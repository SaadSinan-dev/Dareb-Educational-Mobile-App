import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/app.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/profile/presentation/screens/profile_page.dart';
import 'package:tamkeen2/features/profile/presentation/widgets/profile_modal.dart';
import 'support/memory_store.dart';

void main() {
  setUp(() async => services.reset());
  tearDown(() async => services.reset());
  testWidgets('profile messages belong to its visible scaffold, not shell', (
    tester,
  ) async {
    configureDependencies(demoMode: true, store: MemoryStore());
    await tester.pumpWidget(const LearningApp());
    await tester.pumpAndSettle();
    final auth = services<AuthCubit>();
    await auth.requestCode('0912345678');
    await auth.verifyCode('1234');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bottom-tab-3')));
    await tester.pumpAndSettle();
    final profile = tester.element(find.byType(ProfilePage));
    final shell = tester.element(find.byType(AppShell));
    expect(
      ScaffoldMessenger.of(profile),
      isNot(same(ScaffoldMessenger.of(shell))),
    );
    for (final message in ['Success message', 'Error message']) {
      showAppMessage(profile, message);
      await tester.pumpAndSettle();
      final snack = tester.element(find.text(message));
      expect(snack.findAncestorWidgetOfExactType<PageLayout>(), isNotNull);
      expect(find.byType(ProfilePage), findsOneWidget);
      ScaffoldMessenger.of(profile).removeCurrentSnackBar();
      await tester.pumpAndSettle();
    }
    final router = GoRouter.of(profile);
    for (final route in ['/profile/edit', '/contact', '/about', '/logout']) {
      router.push(route);
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget, reason: route);
      final modal = tester.widget<ProfileModal>(find.byType(ProfileModal));
      final scaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(ProfileModal),
          matching: find.byType(Scaffold),
        ),
      );
      expect(scaffold.backgroundColor, Colors.transparent, reason: route);
      expect(modal.overlay, isTrue, reason: route);
      final modalContext = tester.element(find.byType(ProfileModal));
      showAppMessage(modalContext, 'Modal message');
      await tester.pumpAndSettle();
      final snack = tester.element(find.text('Modal message'));
      expect(snack.findAncestorWidgetOfExactType<ProfileModal>(), isNotNull);
      expect(find.byType(ProfilePage), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(tester.widget<AppShell>(find.byType(AppShell)).index, 3);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
