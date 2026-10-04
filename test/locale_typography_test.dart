import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/app.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/core/preferences/app_preferences_cubit.dart';
import 'support/memory_store.dart';

void main() {
  testWidgets('both locale themes consistently style all text roles', (
    tester,
  ) async {
    await services.reset();
    configureDependencies(demoMode: true, store: MemoryStore());
    await tester.pumpWidget(const LearningApp());
    await tester.pumpAndSettle();
    for (final language in ['ar', 'en']) {
      await services<AppPreferencesCubit>().setLanguage(language);
      await tester.pumpAndSettle();
      final element = tester.element(find.byType(TextField));
      final theme = Theme.of(element);
      final family = language == 'ar' ? 'NotoSansArabic' : 'Roboto';
      expect(theme.textTheme.bodyMedium!.fontFamily, family);
      expect(theme.textTheme.titleLarge!.fontFamily, family);
      expect(theme.textTheme.labelLarge!.fontFamily, family);
      expect(theme.primaryTextTheme.bodyMedium!.fontFamily, family);
      expect(
        Directionality.of(element),
        language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await services.reset();
  });
  testWidgets('bundled fonts keep root tabs and Profile inputs usable at 2x', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final family in ['NotoSansArabic', 'Roboto']) {
        await (FontLoader(
          family,
        )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
      }
    });
    await services.reset();
    addTearDown(() async => services.reset());
    addTearDown(tester.view.reset);
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    configureDependencies(demoMode: true, store: MemoryStore());
    await tester.pumpWidget(const LearningApp());
    await tester.pumpAndSettle();
    final auth = services<AuthCubit>();
    await auth.requestCode('0912345678');
    await auth.verifyCode('1234');
    await tester.pumpAndSettle();
    final failures = <String>[];
    for (final language in ['ar', 'en']) {
      await services<AppPreferencesCubit>().setLanguage(language);
      for (final size in [
        for (final width in [320.0, 360.0, 390.0, 430.0, 600.0, 768.0])
          Size(width, 932),
        const Size(600, 360),
        const Size(768, 432),
      ]) {
        tester.view.physicalSize = size;
        for (var tab = 0; tab < 4; tab++) {
          await tester.tap(find.byKey(ValueKey('bottom-tab-$tab')));
          await tester.pumpAndSettle();
          Object? error;
          while ((error = tester.takeException()) != null) {
            failures.add('$language $size tab $tab: $error');
          }
        }
        final router = GoRouter.of(tester.element(find.byType(AppShell)));
        router.push('/profile/edit');
        await tester.pumpAndSettle();
        Object? error;
        while ((error = tester.takeException()) != null) {
          failures.add('$language $size profile inputs: $error');
        }
        router.pop();
        await tester.pumpAndSettle();
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    expect(failures, isEmpty);
  });
}
