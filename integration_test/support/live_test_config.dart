import 'package:flutter_test/flutter_test.dart';

String liveTestCode() {
  const code = String.fromEnvironment('LIVE_TEST_OTP');
  if (!RegExp(r'^[0-9]{4}$').hasMatch(code)) {
    fail('Set LIVE_TEST_OTP to the code received by the dedicated QA account.');
  }
  return code;
}
