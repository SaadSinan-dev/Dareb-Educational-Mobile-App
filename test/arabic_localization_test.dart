import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/app.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'support/memory_store.dart';

void main() {
  testWidgets('Arabic screens retain Arabic native control labels', (
    tester,
  ) async {
    await services.reset();
    configureDependencies(demoMode: true, store: MemoryStore());
    await tester.pumpWidget(const LearningApp());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).last);
    final router = GoRouter.of(context);
    final auth = context.read<AuthCubit>();
    await auth.requestCode('0912345678');
    await auth.verifyCode('1234');
    await tester.pumpAndSettle();
    router.push<void>('/detail/math');
    await tester.pumpAndSettle();
    final screen = tester.element(find.byType(Scaffold).last);
    expect(Localizations.localeOf(screen).languageCode, 'ar');
    expect(Directionality.of(screen), TextDirection.rtl);
    expect(MaterialLocalizations.of(screen).backButtonTooltip, 'رجوع');
    expect(find.byTooltip('رجوع'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await services.reset();
  });
}
