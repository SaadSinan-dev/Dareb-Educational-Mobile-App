import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/features/auth/presentation/auth_pages.dart';

void main() {
  testWidgets('OTP digit controls fit the form panel at 320 pixels', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox(width: 234, child: OtpDigits())),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(4));
    final panel = tester.getRect(find.byType(OtpDigits));
    expect(tester.getRect(fields.at(0)).left, greaterThanOrEqualTo(panel.left));
    expect(tester.getRect(fields.at(3)).right, lessThanOrEqualTo(panel.right));
  });
}
