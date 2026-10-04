import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'dart:convert';

import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/storage/key_value_store.dart';
import 'package:tamkeen2/features/auth/domain/auth_repository.dart';
import 'package:tamkeen2/features/auth/domain/auth_user.dart';
import 'package:tamkeen2/features/auth/domain/registration_draft.dart';
import 'package:tamkeen2/features/auth/domain/registration_options.dart';

/// Explicit local preview. It must only be wired when APP_DEMO_MODE is enabled.
class DemoAuthRepository implements AuthRepository {
  @override
  Future<bool> profileCompleted() async => true;
  DemoAuthRepository(this.store);

  final KeyValueStore store;
  @override
  Future<List<GovernorateOption>> governorates() async => const [
    GovernorateOption(key: 'preview', name: 'دمشق'),
  ];
  @override
  Future<List<RegistrationOption>> branches() async => const [
    RegistrationOption(id: 1, name: 'الفرع التجريبي'),
  ];
  @override
  Future<List<RegistrationOption>> schools({
    required int type,
    required String governorate,
  }) async => const [RegistrationOption(id: 1, name: 'المدرسة التجريبية')];
  static const sessionKey = 'tamkeen.preview.auth.user.v1';
  String? _requestedPhone;
  Future<void> _pendingSave = Future<void>.value();

  @override
  Future<AuthUser?> restoreSession() async {
    final raw = await store.read(sessionKey);
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw);
      if (value is! Map<String, dynamic> ||
          value['id'] is! String ||
          value['phone'] is! String ||
          (value['id'] as String).isEmpty ||
          (value['phone'] as String).isEmpty) {
        throw const FormatException('Invalid preview profile');
      }
      return AuthUser(
        id: value['id'] as String,
        phone: value['phone'] as String,
        firstName: value['firstName'] is String
            ? value['firstName'] as String
            : '',
        lastName: value['lastName'] is String
            ? value['lastName'] as String
            : '',
        email: value['email'] is String ? value['email'] as String : '',
        school: value['school'] is String ? value['school'] as String : '',
        gender: value['gender'] is String ? value['gender'] as String : '',
        age: value['age'] is int ? value['age'] as int : null,
      );
    } catch (_) {
      await store.remove(sessionKey);
      return null;
    }
  }

  @override
  Future<void> requestCode(String phone) async {
    _requestedPhone = phone;
  }

  @override
  Future<void> resendCode(String phone) => requestCode(phone);

  @override
  Future<AuthUser> verifyCode(String phone, String code) async {
    if (_requestedPhone != phone || code != '1234') {
      throw const AppFailure(AppCopy.verificationCodeInvalid);
    }
    _requestedPhone = null;
    final user = AuthUser(id: 'preview:$phone', phone: phone);
    await _save(user);
    return user;
  }

  @override
  Future<AuthUser> register(RegistrationDraft draft) async {
    if (draft.validationError != null) throw AppFailure(draft.validationError!);
    final user = AuthUser(
      id: 'preview:${draft.phone}',
      phone: draft.phone,
      firstName: draft.firstName.trim(),
      lastName: draft.lastName.trim(),
      email: draft.email.trim(),
      school: draft.school.trim(),
      gender: draft.gender!.name,
      age: draft.age,
    );
    await _save(user);
    return user;
  }

  Future<void> _save(AuthUser user) {
    final save = store.write(
      sessionKey,
      jsonEncode({
        'id': user.id,
        'phone': user.phone,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'email': user.email,
        'school': user.school,
        'gender': user.gender,
        'age': user.age,
      }),
    );
    _pendingSave = save;
    return save;
  }

  @override
  Future<void> logout() async {
    _requestedPhone = null;
    try {
      await _pendingSave;
    } catch (_) {
      // Remove any profile left by a partially completed preview write.
    }
    await store.remove(sessionKey);
  }

  @override
  Future<void> deleteAccount() => logout();
}
