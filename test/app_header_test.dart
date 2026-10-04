import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';
import 'package:tamkeen2/features/courses/presentation/screens/my_learning_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/app.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/core/preferences/app_preferences_cubit.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/theme/app_theme.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'support/memory_store.dart';

void main() {
  testWidgets(
    'four tabs share header geometry across direction and safe areas',
    (tester) async {
      await services.reset();
      configureDependencies(demoMode: true, store: MemoryStore());
      addTearDown(tester.view.reset);
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );
      addTearDown(() => services.reset());
      await tester.pumpWidget(const LearningApp());
      await tester.pumpAndSettle();
      final auth = services<AuthCubit>();
      await auth.requestCode('0912345678');
      await auth.verifyCode('1234');
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(AppShell)));
      final preferences = services<AppPreferencesCubit>();
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 28, bottom: 16);
      tester.view.viewPadding = const FakeViewPadding(top: 28, bottom: 16);
      for (final language in ['ar', 'en']) {
        await preferences.setLanguage(language);
        for (final size in [
          for (final width in [320.0, 360.0, 390.0, 430.0, 600.0, 768.0])
            Size(width, 932),
          const Size(600, 360),
          const Size(768, 432),
        ]) {
          tester.view.physicalSize = size;
          for (final scale in [1.0, 1.5, 2.0]) {
            tester.binding.platformDispatcher.textScaleFactorTestValue = scale;
            router.go(AppRoutes.myLearning);
            await tester.pumpAndSettle();
            expect(find.byType(AppHeader), findsOneWidget);
            final reference = tester.getRect(find.byType(AppHeader));
            for (final path in [
              AppRoutes.home,
              AppRoutes.gallery,
              AppRoutes.profile,
            ]) {
              router.go(path);
              await tester.pumpAndSettle();
              expect(
                find.byType(AppHeader),
                findsOneWidget,
                reason: '$path / $language / $size / $scale',
              );
              expect(tester.getRect(find.byType(AppHeader)), reference);
              expect(tester.takeException(), isNull);
            }
            expect(reference.top, 28);
          }
        }
      }
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.pumpWidget(const SizedBox.shrink());
      await services.reset();
    },
  );

  testWidgets('long header title fits its reserved area at large text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: const SizedBox(
              width: 320,
              child: AppHeader(
                title:
                    'A long educational materials title that needs to remain readable on a small phone',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(AppHeader)).height,
      lessThanOrEqualTo(112),
    );
  });
  testWidgets(
    'root catalog header remains consistent while loading and failed',
    (tester) async {
      await services.reset();
      configureDependencies(demoMode: true, store: MemoryStore());
      final cubit = _HeaderTestCubit(services<CourseCubit>());
      addTearDown(cubit.close);
      addTearDown(() => services.reset());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BlocProvider<CourseCubit>.value(
            value: cubit,
            child: const MyLearningPage(),
          ),
        ),
      );
      for (final status in [
        LoadStatus.loading,
        LoadStatus.failure,
        LoadStatus.ready,
      ]) {
        cubit.show(status);
        await tester.pump();
        expect(find.byType(AppHeader), findsOneWidget, reason: '$status');
        expect(
          tester.widget<AppHeader>(find.byType(AppHeader)).leading,
          isNull,
        );
      }
    },
  );
  testWidgets(
    'catalog failure beneath header stays reachable in short landscape',
    (tester) async {
      await services.reset();
      configureDependencies(demoMode: true, store: MemoryStore());
      final cubit = _HeaderTestCubit(services<CourseCubit>());
      addTearDown(cubit.close);
      addTearDown(() => services.reset());
      addTearDown(tester.view.reset);
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 360);
      tester.view.padding = const FakeViewPadding(top: 28, bottom: 16);
      tester.view.viewPadding = const FakeViewPadding(top: 28, bottom: 16);
      tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
      cubit.show(
        LoadStatus.failure,
        error:
            'The service is temporarily unavailable. Please try again later.',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AppShell(
            index: 1,
            child: BlocProvider<CourseCubit>.value(
              value: cubit,
              child: const MyLearningPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppHeader), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.byType(TextButton), findsOneWidget);
    },
  );
}

class _HeaderTestCubit extends CourseCubit {
  _HeaderTestCubit(CourseCubit source)
    : super(source.getCourses, source.repository, demoMode: true);
  void show(LoadStatus status, {String error = 'Unavailable'}) =>
      emit(CourseState(status: status, error: error));
}
