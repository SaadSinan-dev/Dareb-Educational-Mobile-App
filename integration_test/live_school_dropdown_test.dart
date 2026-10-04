import 'support/live_test_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/features/auth/presentation/registration_options_cubit.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/auth/presentation/auth_pages.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('school dropdown opens and selects a live backend school', (
    tester,
  ) async {
    const phone = String.fromEnvironment('LIVE_ACCOUNT_PHONE');
    if (phone.isEmpty) fail('Set LIVE_ACCOUNT_PHONE to a dedicated QA number.');

    configureDependencies();
    final auth = services<AuthCubit>();
    final code = liveTestCode();
    await auth.requestCode(phone);
    expect(auth.state.status, AuthStatus.codeSent, reason: auth.state.error);
    await auth.verifyCode(code);
    expect(
      auth.state.status,
      AuthStatus.authenticated,
      reason: auth.state.error,
    );

    final governorates = await auth.governorates();
    expect(governorates, isNotEmpty);
    final governorate = governorates.first;
    final schools = await auth.schools(type: 1, governorate: governorate.key);
    expect(schools, isNotEmpty);

    final schoolRequests = <Map<String, dynamic>>[];
    services<ApiClient>().dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.uri.path.endsWith('/schools/all')) {
            schoolRequests.add(
              Map<String, dynamic>.from(options.queryParameters),
            );
          }
          handler.next(options);
        },
      ),
    );

    await tester.pumpWidget(
      BlocProvider.value(
        value: auth,
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            ...GlobalMaterialLocalizations.delegates,
            AppLocalizations.delegate,
          ],
          home: BlocProvider(
            create: (_) => RegistrationOptionsCubit(auth.repository),
            child: const RegisterPage(),
          ),
        ),
      ),
    );
    await _waitFor(
      tester,
      () => find.widgetWithText(FilledButton, 'التالي').evaluate().isNotEmpty,
    );
    await _tap(tester, find.widgetWithText(FilledButton, 'التالي'));
    await _tap(tester, find.text('أنثى'));
    await _tap(tester, find.widgetWithText(FilledButton, 'التالي'));
    await _tap(tester, find.text('صديق'));
    await _tap(tester, find.widgetWithText(FilledButton, 'التالي'));
    await _tap(tester, find.text('مدرسة'));
    await _tap(tester, find.widgetWithText(FilledButton, 'التالي'));
    await _tap(tester, find.text('بكالوريا علمي'));
    await _tap(tester, find.byType(DropdownButtonFormField<int>).first);
    final branches = await auth.branches();
    await _tap(tester, find.text(branches.first.name).last);
    await _tap(tester, find.widgetWithText(FilledButton, 'التأكيد'));

    final schoolField = find.byType(DropdownButtonFormField<int>);
    await _waitFor(tester, () {
      if (schoolField.evaluate().isEmpty) return false;
      final button = find.descendant(
        of: schoolField,
        matching: find.byType(DropdownButton<int>),
      );
      if (button.evaluate().isEmpty) return false;
      return tester.widget<DropdownButton<int>>(button).items?.isNotEmpty ??
          false;
    });
    expect(
      schoolRequests.any(
        (query) =>
            query['type'] == 1 && query['governorate'] == governorate.key,
      ),
      isTrue,
    );
    await _tap(tester, schoolField);
    expect(find.text(schools.first.name), findsWidgets);
    await _tap(tester, find.text(schools.first.name).last);
    expect(
      tester.state<FormFieldState<int>>(schoolField).value,
      schools.first.id,
    );
    expect(find.text(schools.first.name), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _waitFor(tester, () {
    final elements = finder.evaluate();
    if (elements.length != 1) return false;
    final widget = elements.single.widget;
    return widget is! FilledButton || widget.onPressed != null;
  });
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _waitFor(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) return;
  }
  fail('Timed out waiting for the live registration screen.');
}
