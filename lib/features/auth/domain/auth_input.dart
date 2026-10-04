import 'package:tamkeen2/core/validation/app_validators.dart';

abstract final class AuthInput {
  static String normalizeDigits(String value) {
    return AppValidators.normalizeDigits(value);
  }

  static String? phone(String input) {
    return AppValidators.normalizedPhone(input);
  }

  static String? code(String input) {
    return AppValidators.normalizedOtp(input);
  }
}
