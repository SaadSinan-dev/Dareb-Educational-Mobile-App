import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/app.dart';
import 'package:tamkeen2/application/app_bootstrap_cubit.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/preferences/app_preferences_cubit.dart';
import 'package:tamkeen2/features/auth/domain/auth_repository.dart';
import 'package:tamkeen2/features/auth/domain/auth_user.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/auth/presentation/auth_pages.dart';
import 'package:tamkeen2/features/home/presentation/screens/home_page.dart';
import 'support/memory_store.dart';

class _SessionRepository implements AuthRepository {
  Completer<AuthUser?> session = Completer<AuthUser?>();
  @override
  Future<AuthUser?> restoreSession() => session.future;
  @override
  Future<void> logout() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() => services.reset());
  for (final signedIn in [false, true]) {
    testWidgets(
      'delayed restoration paints only bootstrap until ${signedIn ? 'Home' : 'Login'}',
      (tester) async {
        await services.reset();
        configureDependencies(demoMode: true, store: MemoryStore());
        await services.unregister<AuthCubit>();
        final repository = _SessionRepository();
        final auth = AuthCubit(repository);
        services.registerSingleton<AuthCubit>(
          auth,
          dispose: (value) => value.close(),
        );
        await tester.pumpWidget(const LearningApp());
        await tester.pump(const Duration(seconds: 3));
        expect(
          find.byKey(const ValueKey('session-initializing')),
          findsOneWidget,
        );
        expect(find.byType(LoginPage), findsNothing);
        expect(find.byType(HomePage), findsNothing);
        repository.session.complete(
          signedIn ? const AuthUser(id: 'qa', phone: '0912345678') : null,
        );
        await tester.pumpAndSettle();
        expect(find.byType(signedIn ? HomePage : LoginPage), findsOneWidget);
        expect(
          find.byKey(const ValueKey('session-initializing')),
          findsNothing,
        );
        if (signedIn) {
          await auth.logout();
          await tester.pumpAndSettle();
          expect(find.byType(LoginPage), findsOneWidget);
          expect(find.byType(HomePage), findsNothing);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  test('restoration failure keeps startup gated and can retry', () async {
    final repository = _SessionRepository();
    final auth = AuthCubit(repository);
    final preferences = AppPreferencesCubit(MemoryStore());
    final bootstrap = AppBootstrapCubit(auth, preferences);
    final first = bootstrap.initialize();
    repository.session.completeError(const AppFailure.unavailable());
    await first;
    expect(bootstrap.state.status, BootstrapStatus.sessionError);
    expect(bootstrap.state.resolved, isFalse);
    repository.session = Completer<AuthUser?>();
    final retry = bootstrap.initialize();
    repository.session.complete(null);
    await retry;
    expect(bootstrap.state.status, BootstrapStatus.unauthenticated);
    await bootstrap.close();
    await auth.close();
    await preferences.close();
  });
}
