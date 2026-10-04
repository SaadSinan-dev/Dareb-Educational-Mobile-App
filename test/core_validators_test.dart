import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/validation/app_validators.dart';

void main() {
  test(
    'required and optional text reject whitespace and control characters',
    () {
      expect(AppValidators.requiredText('   '), isNotNull);
      expect(AppValidators.optionalText(''), isNull);
      expect(AppValidators.requiredText('مرحبا بالعالم'), isNull);
      expect(AppValidators.requiredText('a\u0000b'), isNotNull);
    },
  );
  test(
    'Arabic and English names accept diacritics and legitimate separators',
    () {
      for (final value in [
        'عبد الرحمن',
        'مُحَمَّد',
        'أحمد',
        'O’Connor',
        'Anne-Marie',
        ' محمد ',
      ]) {
        expect(AppValidators.name(value), isNull, reason: value);
      }
      for (final value in [
        '',
        '  ',
        'a',
        'Ali123',
        '<script>',
        '😀😀',
        'a' * 101,
      ]) {
        expect(AppValidators.name(value), isNotNull, reason: value);
      }
    },
  );
  test(
    'phone normalizes Arabic digits without silently removing internal whitespace',
    () {
      expect(AppValidators.normalizedPhone(' ٠٩١٢٣٤٥٦٧٨ '), '0912345678');
      for (final value in [
        '123',
        '+',
        '123 456789',
        '123-456789',
        '12a456789',
      ]) {
        expect(AppValidators.phone(value), isNotNull, reason: value);
      }
    },
  );
  test('email rejects malformed local and domain parts', () {
    expect(AppValidators.email(' user.name+qa@example.com '), isNull);
    for (final value in [
      '@example.com',
      'a@',
      'a b@example.com',
      'a..b@example.com',
      '.a@example.com',
      'a@-example.com',
      'a@example..com',
    ]) {
      expect(AppValidators.email(value), isNotNull, reason: value);
    }
  });
  test('age is an integer in the existing 7 to 100 contract', () {
    for (final value in ['7', '100', '٢٦']) {
      expect(AppValidators.age(value), isNull);
    }
    for (final value in ['6', '101', '26.5', 'abc', '2 6', '']) {
      expect(AppValidators.age(value), isNotNull);
    }
  });
  test('OTP is exactly four numeric digits with no whitespace', () {
    for (final value in ['1111', '١١١١', '۱۱۱۱']) {
      expect(AppValidators.otp(value), isNull);
    }
    for (final value in [
      '',
      '1',
      '11',
      '111',
      '11111',
      'a111',
      '!111',
      ' 1111',
      '1 11',
    ]) {
      expect(AppValidators.otp(value), isNotNull);
    }
  });
  test('messages allow useful Arabic length and reject whitespace', () {
    expect(AppValidators.comment(''), isNotNull);
    expect(AppValidators.comment('جيد'), isNull);
    expect(AppValidators.contactMessage('  '), isNotNull);
    expect(AppValidators.contactMessage('رسالة عربية طويلة ' * 100), isNull);
    expect(AppValidators.comment('ن' * 5001), isNotNull);
    expect(AppValidators.search('عربي English 123'), isNull);
    expect(AppValidators.search(''), isNull);
  });
}
