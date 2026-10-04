import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/features/auth/domain/auth_repository.dart';
import 'package:tamkeen2/features/auth/domain/auth_user.dart';
import 'package:tamkeen2/features/auth/domain/registration_draft.dart';
import 'package:tamkeen2/features/auth/domain/registration_options.dart';

/// Honest fallback until a documented remote authentication contract exists.
class UnavailableAuthRepository implements AuthRepository {
  @override
  Future<bool> profileCompleted() async => throw const AppFailure.unavailable();
  @override
  Future<List<GovernorateOption>> governorates() async =>
      throw const AppFailure.unavailable();
  @override
  Future<List<RegistrationOption>> branches() async =>
      throw const AppFailure.unavailable();
  @override
  Future<List<RegistrationOption>> schools({
    required int type,
    required String governorate,
  }) async => throw const AppFailure.unavailable();
  @override
  Future<AuthUser?> restoreSession() async => null;
  @override
  Future<void> requestCode(String phone) async =>
      throw const AppFailure.unavailable();
  @override
  Future<void> resendCode(String phone) async =>
      throw const AppFailure.unavailable();
  @override
  Future<AuthUser> verifyCode(String phone, String code) async =>
      throw const AppFailure.unavailable();
  @override
  Future<AuthUser> register(RegistrationDraft draft) async =>
      throw const AppFailure.unavailable();
  @override
  Future<void> logout() async {}
  @override
  Future<void> deleteAccount() async => throw const AppFailure.unavailable();
}
