import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/app.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/core/preferences/app_preferences_cubit.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'support/memory_store.dart';

void main() {
  setUp(() async => services.reset());
  tearDown(() async => services.reset());
  testWidgets('resolved empty session opens login without a splash timer', (
    tester,
  ) async {
    configureDependencies(demoMode: true, store: MemoryStore());
    await tester.pumpWidget(const LearningApp());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('session-initializing')), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('splash and validated preview login reach the course catalog', (
    tester,
  ) async {
    configureDependencies(demoMode: true, store: MemoryStore());
    await tester.pumpWidget(const LearningApp());
    await tester.pumpAndSettle();
    expect(find.text('سجل دخول'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '0912345678');
    await tester.tap(find.text('سجل دخول'));
    await tester.pumpAndSettle();
    expect(find.text('التأكيد'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tester.enterText(find.byType(TextField).at(i), '${i + 1}');
    }
    await tester.ensureVisible(find.text('التأكيد'));
    await tester.tap(find.text('التأكيد'));
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(Scaffold).last));
    expect(router.routeInformationProvider.value.uri.path, '/home');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('all client destinations render at six required widths', (
    tester,
  ) async {
    configureDependencies(demoMode: true, store: MemoryStore());
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const LearningApp());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).last);
    final router = GoRouter.of(context);
    final auth = context.read<AuthCubit>();
    await auth.requestCode('0912345678');
    await auth.verifyCode('1234');
    await tester.pumpAndSettle();
    final failures = <String>[];
    for (final width in [320.0, 360.0, 390.0, 430.0, 600.0, 768.0]) {
      tester.view.physicalSize = Size(width, 932);
      tester.view.devicePixelRatio = 1;
      for (final path in [
        '/home',
        '/categories',
        '/my-learning',
        '/search',
        '/assessments',
        '/activities',
        '/gallery',
        '/gallery/art',
        '/profile',
        '/profile/edit',
        '/detail/math',
        '/detail/arabic',
        '/lesson/math/0',
        '/lesson/math/-1',
        '/checkout/arabic',
        '/checkout/plan-year',
        '/plans',
        '/quiz/math',
        '/quiz/math?activity=true',
        '/quiz-review',
        '/notifications',
        '/downloads',
        '/achievements',
        '/faq',
        '/privacy',
        '/terms',
        '/about',
        '/contact',
        '/logout',
        '/unknown',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        Object? error;
        while ((error = tester.takeException()) != null) {
          failures.add('$path at $width: $error');
        }
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    expect(failures, isEmpty);
  });

  testWidgets('major routes survive short screens, rotation, and larger text', (
    tester,
  ) async {
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('RenderFlex overflowed')) {
        debugPrint(details.toString());
      }
      previousErrorHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    configureDependencies(demoMode: true, store: MemoryStore());
    addTearDown(tester.view.reset);
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(const LearningApp());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).last);
    final router = GoRouter.of(context);
    final auth = context.read<AuthCubit>();
    final preferences = context.read<AppPreferencesCubit>();
    await auth.requestCode('0912345678');
    await auth.verifyCode('1234');
    await tester.pumpAndSettle();
    final failures = <String>[];
    const routes = [
      '/home',
      '/categories',
      '/my-learning',
      '/search',
      '/assessments',
      '/activities',
      '/gallery',
      '/gallery/art',
      '/profile',
      '/profile/edit',
      '/detail/math',
      '/lesson/math/0',
      '/checkout/arabic',
      '/plans',
      '/quiz/math',
      '/notifications',
      '/downloads',
      '/achievements',
      '/faq',
      '/privacy',
      '/terms',
      '/about',
      '/contact',
      '/logout',
    ];
    for (final (size, scale, language) in [
      (const Size(320, 568), 1.0, 'ar'),
      (const Size(768, 432), 1.0, 'ar'),
      (const Size(600, 360), 1.0, 'en'),
      (const Size(390, 700), 1.5, 'en'),
    ]) {
      tester.view.physicalSize = size;
      tester.binding.platformDispatcher.textScaleFactorTestValue = scale;
      await preferences.setLanguage(language);
      await tester.pumpAndSettle();
      for (final path in routes) {
        router.go(path);
        await tester.pumpAndSettle();
        Object? error;
        while ((error = tester.takeException()) != null) {
          failures.add(
            '$path at $size, scale $scale, $language: '
            '${error is FlutterError ? error.toStringDeep(minLevel: DiagnosticLevel.info) : error}',
          );
        }
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    expect(failures, isEmpty);
  });
}
