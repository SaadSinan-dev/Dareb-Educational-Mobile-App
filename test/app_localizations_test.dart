import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';

void main() {
  test('Arabic remains the supplied default text', () {
    const l10n = AppLocalizations(Locale('ar'));
    expect(l10n.translate(AppCopy.signInAction), 'سجل دخول');
    expect(l10n.translate('5 دروس'), '5 دروس');
    expect(
      l10n.translate('registrationNotSupported'),
      AppCopy.registrationNotSupported,
    );
  });

  test('English resolves static copy and interpolated counts', () {
    const l10n = AppLocalizations(Locale('en'));
    expect(l10n.translate(AppCopy.signInAction), 'Sign in');
    expect(l10n.translate('5 دروس'), '5 lessons');
    expect(
      l10n.translate('3 دورات • 2 دروس مكتملة'),
      '3 courses • 2 completed lessons',
    );
    expect(
      l10n.translate('registrationNotSupported'),
      'Registration is unavailable right now. Please contact support.',
    );
  });

  testWidgets('locale delegate changes visible text and direction', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [AppLocalizations.delegate],
        home: const Scaffold(body: AppText(AppCopy.signInAction)),
      ),
    );
    expect(find.text('Sign in'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('Sign in'))),
      TextDirection.ltr,
    );
  });

  testWidgets('a localization key never appears raw in visible error text', (
    tester,
  ) async {
    for (final (locale, expected) in [
      (const Locale('ar'), AppCopy.registrationNotSupported),
      (
        const Locale('en'),
        'Registration is unavailable right now. Please contact support.',
      ),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: const Scaffold(body: AppText('registrationNotSupported')),
        ),
      );
      await tester.pump();
      expect(find.text(expected), findsOneWidget);
      expect(find.text('registrationNotSupported'), findsNothing);
    }
  });
}
