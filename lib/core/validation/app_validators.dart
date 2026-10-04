import 'package:tamkeen2/l10n/app_copy.g.dart';

/// Submission rules shared by UI, Cubits and repositories. Never rewrite an
/// active IME composing value: normalization happens at submission boundaries.
abstract final class AppValidators {
  static const maxNameLength = 100;
  static const maxMessageLength = 5000;
  static const maxSearchLength = 2000;
  static String normalizeDigits(String value) {
    return String.fromCharCodes(
      value.runes.map((rune) {
        if (rune >= 0x0660 && rune <= 0x0669) return rune - 0x0660 + 0x30;
        if (rune >= 0x06f0 && rune <= 0x06f9) return rune - 0x06f0 + 0x30;
        return rune;
      }),
    );
  }

  static bool _invalidControls(String value) =>
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]').hasMatch(value);
  static String? requiredText(
    String? value, {
    int minLength = 1,
    int maxLength = maxMessageLength,
  }) {
    final text = (value ?? '').trim();
    if (text.runes.length < minLength ||
        text.runes.length > maxLength ||
        _invalidControls(text)) {
      return AppCopy.textValidation;
    }
    return null;
  }

  static String? optionalText(
    String? value, {
    int maxLength = maxMessageLength,
  }) => (value ?? '').trim().isEmpty
      ? null
      : requiredText(value, maxLength: maxLength);

  static String? name(String? value) {
    final text = (value ?? '').trim();
    // Arabic letters (including Persian variants) and vocalization marks;
    // Latin letters plus the usual spaces, hyphens and apostrophes.
    final letters = RegExp(
      r"[A-Za-z\u00C0-\u02AF\u0620-\u064A\u066E-\u06D3\u06FA-\u06FC\u0750-\u077F\u08A0-\u08C9]",
      unicode: true,
    );
    final allowed = RegExp(
      r"^[A-Za-z\u00C0-\u02AF\u0620-\u065F\u066E-\u06D3\u06FA-\u06FC\u0750-\u077F\u08A0-\u08C9 '’\-]+$",
      unicode: true,
    );
    if (text.runes.length > maxNameLength ||
        !allowed.hasMatch(text) ||
        letters.allMatches(text).length < 2) {
      return AppCopy.nameValidation;
    }
    return null;
  }

  static String? normalizedPhone(String? value) {
    final text = normalizeDigits((value ?? '').trim());
    return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(text) ? text : null;
  }

  static String? phone(String? value) =>
      normalizedPhone(value) == null ? AppCopy.phoneLengthValidation : null;
  static String? email(String? value) {
    final text = (value ?? '').trim();
    final parts = text.split('@');
    if (text.length > 254 || parts.length != 2) {
      return AppCopy.validEmailRequired;
    }
    final local = parts[0], domain = parts[1];
    if (local.isEmpty ||
        local.length > 64 ||
        local.startsWith('.') ||
        local.endsWith('.') ||
        local.contains('..') ||
        !RegExp(r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+$").hasMatch(local)) {
      return AppCopy.validEmailRequired;
    }
    final labels = domain.split('.');
    if (labels.length < 2 ||
        labels.last.length < 2 ||
        labels.any(
          (label) =>
              label.isEmpty ||
              label.length > 63 ||
              !RegExp(
                r'^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$',
              ).hasMatch(label),
        )) {
      return AppCopy.validEmailRequired;
    }
    return null;
  }

  static String? age(String? value) {
    final text = normalizeDigits((value ?? '').trim());
    final number = int.tryParse(text);
    return !RegExp(r'^[0-9]+$').hasMatch(text) ||
            number == null ||
            number < 7 ||
            number > 100
        ? AppCopy.selectAgeRangeRequired
        : null;
  }

  static String? normalizedOtp(String? value) {
    final text = normalizeDigits(value ?? '');
    return RegExp(r'^[0-9]{4}$').hasMatch(text) ? text : null;
  }

  static String? otp(String? value) => normalizedOtp(value) == null
      ? AppCopy.verificationCodeLengthRequired
      : null;
  static String? school(String? value) => requiredText(value, maxLength: 250);
  static String? comment(String? value) => requiredText(value);
  static String? contactMessage(String? value) => requiredText(value);
  static String? search(String? value) =>
      optionalText(value, maxLength: maxSearchLength);
  static String? subscriptionCode(String? value) =>
      requiredText(value, maxLength: 100);
}
