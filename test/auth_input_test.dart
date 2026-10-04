import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/features/auth/domain/auth_input.dart';

void main() {
  test('OTP accepts exactly four numeric digits', () {
    expect(AuthInput.code('1111'), '1111');
    expect(AuthInput.code('١١١١'), '1111');
    expect(AuthInput.code('۱۱۱۱'), '1111');

    for (final invalid in [
      '1',
      '111',
      '11111',
      '11a1',
      '11!1',
      '1 111',
      ' 1111 ',
      '',
    ]) {
      expect(AuthInput.code(invalid), isNull, reason: invalid);
    }
  });
}
