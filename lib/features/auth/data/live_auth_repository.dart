import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/features/auth/domain/auth_repository.dart';
import 'package:tamkeen2/features/auth/domain/auth_user.dart';
import 'package:tamkeen2/features/auth/domain/registration_draft.dart';
import 'package:tamkeen2/features/auth/domain/registration_options.dart';
import 'package:tamkeen2/features/auth/data/auth_session_store.dart';
import 'package:tamkeen2/features/auth/data/postman_auth_data_source.dart';

typedef FcmTokenProvider = Future<String?> Function();

/// Real auth calls. Activation includes a platform FCM token when available.
class LiveAuthRepository implements AuthRepository {
  LiveAuthRepository(this.source, this.sessions, {this.fcmTokenProvider});

  final PostmanAuthDataSource source;
  final AuthSessionStore sessions;
  final FcmTokenProvider? fcmTokenProvider;
  Future<void> _pendingActivation = Future<void>.value();

  @override
  Future<AuthUser?> restoreSession() async {
    final session = await sessions.readSession();
    if (session == null) return null;
    try {
      final completed = await source.profileCompleted();
      return _localUser(session.phone, profileComplete: completed);
    } on AppFailure catch (error) {
      if (error.statusCode != 401) rethrow;
      final current = await sessions.readSession();
      if (current == null) return null;
      if (current.token != session.token) rethrow;
      if (!await sessions.clearSession(expectedToken: session.token)) rethrow;
      return null;
    }
  }

  @override
  Future<bool> profileCompleted() => source.profileCompleted();

  @override
  Future<void> requestCode(String phone) async {
    await source.login(phone);
  }

  @override
  Future<void> resendCode(String phone) async {
    await source.resend(phone);
  }

  @override
  Future<AuthUser> verifyCode(String phone, String code) {
    final activation = _pendingActivation.then((_) => _activate(phone, code));
    _pendingActivation = activation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return activation;
  }

  Future<AuthUser> _activate(String phone, String code) async {
    final fcmToken = (await fcmTokenProvider?.call())?.trim();
    final deviceId = await sessions.deviceId();
    if (deviceId.isEmpty) throw const AppFailure.unavailable();
    final token = await source.activate(
      phone: phone,
      code: code,
      fcmToken: fcmToken,
      deviceId: deviceId,
    );
    await sessions.saveSession(AuthSession(phone: phone, token: token));
    return _localUser(phone);
  }

  @override
  Future<AuthUser> register(RegistrationDraft draft) async {
    if (draft.schoolId == null || draft.branchId == null) {
      throw const AppFailure(AppCopy.completeAccountDetailsRequired);
    }
    final session = await sessions.readSession();
    if (session == null || session.phone != draft.phone) {
      throw const AppFailure(AppCopy.sessionExpired);
    }
    await source.completeProfile(draft);
    if (!await source.profileCompleted()) {
      throw const AppFailure(AppCopy.completeAccountDetailsRequired);
    }
    return _localUser(session.phone);
  }

  @override
  Future<List<GovernorateOption>> governorates() => source.governorates();
  @override
  Future<List<RegistrationOption>> branches() => source.branches();
  @override
  Future<List<RegistrationOption>> schools({
    required int type,
    required String governorate,
  }) => source.schools(type: type, governorate: governorate);

  @override
  Future<void> logout() async {
    await _pendingActivation;
    final session = await sessions.readSession();
    try {
      if (session != null) await source.logout();
    } finally {
      await sessions.clearSession();
    }
  }

  @override
  Future<void> deleteAccount() async {
    await _pendingActivation;
    final session = await sessions.readSession();
    if (session == null) throw const AppFailure.unavailable();
    await source.deleteAccount();
    await sessions.clearSession();
  }

  Future<AuthUser> _localUser(
    String phone, {
    bool profileComplete = true,
  }) async {
    final installationId = await sessions.deviceId();
    final digest = Hmac(
      sha256,
      utf8.encode(installationId),
    ).convert(utf8.encode(phone)).toString();
    return AuthUser(
      id: 'local:$digest',
      phone: phone,
      profileComplete: profileComplete,
    );
  }
}
