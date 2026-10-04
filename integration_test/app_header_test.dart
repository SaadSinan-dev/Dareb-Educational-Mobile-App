import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tamkeen2/app.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/core/preferences/app_preferences_cubit.dart';
import 'package:tamkeen2/features/notifications/presentation/screens/notifications_page.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import '../test/support/memory_store.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('four device tabs retain one header and existing navigation', (
    tester,
  ) async {
    await services.reset();
    configureDependencies(demoMode: true, store: MemoryStore());
    await tester.pumpWidget(const LearningApp());
    await tester.pumpAndSettle();
    final auth = services<AuthCubit>();
    await auth.requestCode('0912345678');
    await auth.verifyCode('1234');
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(AppShell)));
    for (final language in ['ar', 'en']) {
      await services<AppPreferencesCubit>().setLanguage(language);
      Rect? reference;
      for (var index = 0; index < 4; index++) {
        await tester.tap(find.byKey(ValueKey('bottom-tab-$index')));
        await tester.pumpAndSettle();
        expect(tester.widget<AppShell>(find.byType(AppShell)).index, index);
        expect(find.byType(AppHeader), findsOneWidget);
        reference ??= tester.getRect(find.byType(AppHeader));
        expect(tester.getRect(find.byType(AppHeader)), reference);
        expect(router.canPop(), isFalse);
        expect(tester.takeException(), isNull);
        await binding.takeScreenshot(
          'header-$language-${['home', 'materials', 'gallery', 'profile'][index]}',
        );
      }
    }
    await tester.tap(find.byType(HeaderNotificationAction));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsPage), findsOneWidget);
    expect(router.canPop(), isTrue);
    router.pop();
    await tester.pumpAndSettle();
    expect(tester.widget<AppShell>(find.byType(AppShell)).index, 3);
    await tester.pumpWidget(const SizedBox.shrink());
    await services.reset();
  });
}
