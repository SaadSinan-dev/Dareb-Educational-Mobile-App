import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/app.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/courses/presentation/screens/my_learning_page.dart';
import 'support/memory_store.dart';

void main() {
  testWidgets('bottom tabs preserve page state without accumulating routes', (
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
    final router = GoRouter.of(tester.element(find.byType(AppShell)));
    final nav = find.byKey(const ValueKey('bottom-tab-1'));
    await tester.tap(nav);
    await tester.pumpAndSettle();
    final original = tester.state(find.byType(MyLearningPage));
    await tester.tap(find.byKey(const ValueKey('bottom-tab-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bottom-tab-1')));
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(MyLearningPage)), same(original));
    expect(router.canPop(), isFalse);
    router.push(AppRoutes.detail('math'));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(MyLearningPage)), same(original));
    await auth.logout();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.login);
    expect(find.byType(AppShell), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await services.reset();
  });
}
