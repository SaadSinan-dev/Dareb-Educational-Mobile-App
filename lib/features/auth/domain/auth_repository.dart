import 'package:tamkeen2/features/auth/domain/auth_user.dart';
import 'package:tamkeen2/features/auth/domain/registration_draft.dart';
import 'package:tamkeen2/features/auth/domain/registration_options.dart';

/// Authentication operations supported by the supplied API collection.
abstract interface class AuthRepository {
  Future<AuthUser?> restoreSession();
  Future<void> requestCode(String phone);
  Future<void> resendCode(String phone);
  Future<AuthUser> verifyCode(String phone, String code);
  Future<bool> profileCompleted();
  Future<AuthUser> register(RegistrationDraft draft);
  Future<List<GovernorateOption>> governorates();
  Future<List<RegistrationOption>> branches();
  Future<List<RegistrationOption>> schools({
    required int type,
    required String governorate,
  });
  Future<void> logout();
  Future<void> deleteAccount();
}
