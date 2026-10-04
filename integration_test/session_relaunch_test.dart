import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tamkeen2/app.dart';
import 'package:tamkeen2/application/app_bootstrap_cubit.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/features/account/presentation/account_cubit.dart';
import 'package:tamkeen2/features/auth/data/auth_session_store.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/auth/presentation/screens/login_page.dart';
import 'package:tamkeen2/features/auth/presentation/screens/otp_page.dart';
import 'package:tamkeen2/features/auth/presentation/screens/register_page.dart';
import 'package:tamkeen2/features/home/presentation/screens/home_page.dart';
import 'package:tamkeen2/features/profile/presentation/screens/profile_page.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';

import 'support/live_test_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const phase = String.fromEnvironment(
    'SESSION_TEST_PHASE',
    defaultValue: 'restore',
  );
  testWidgets('production secure session: $phase', (tester) async {
    expect([
      'inspect',
      'login',
      'restore',
      'logout',
      'signed-out',
      'network-retry',
      'revoked',
    ], contains(phase));
    await services.reset();
    configureDependencies(demoMode: false);
    final sessions = services<AuthSessionStore>();
    final before = await sessions.readSession();
    debugPrint('SESSION_AUDIT phase=$phase persisted=${before != null}');
    if (phase == 'inspect') {
      await services.reset();
      return;
    }

    final auth = services<AuthCubit>();
    final client = services<ApiClient>();
    final transport = client.dio.httpClientAdapter;
    int verifiedProfileRequests = 0;
    client.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.path == 'profile/get') {
            final saved = await sessions.readSession();
            expect(
              saved != null,
              isTrue,
              reason: 'Profile requires durable credentials',
            );
            expect(
              options.headers['Authorization'] == 'Bearer ${saved!.token}',
              isTrue,
              reason: 'Profile must use the persisted bearer token',
            );
            verifiedProfileRequests++;
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (response.requestOptions.path == 'profile/get') {
            debugPrint(
              'SESSION_AUDIT profile_status=${response.statusCode} bearer_verified=true',
            );
          }
          handler.next(response);
        },
      ),
    );

    Future<void> waitFor(Type destination, {bool restoring = false}) async {
      final deadline = Stopwatch()..start();
      while (find.byType(destination).evaluate().isEmpty &&
          deadline.elapsed.inSeconds < 60) {
        await tester.pump(const Duration(milliseconds: 100));
        if (restoring) {
          expect(find.byType(LoginPage), findsNothing);
          expect(find.byType(RegisterPage), findsNothing);
          expect(find.byType(OtpPage), findsNothing);
        }
      }
      expect(
        find.byType(destination),
        findsOneWidget,
        reason: auth.state.error,
      );
    }

    if ({'restore', 'logout', 'network-retry', 'revoked'}.contains(phase)) {
      expect(
        before != null,
        isTrue,
        reason: 'Login with the existing QA account first',
      );
    }
    if (phase == 'signed-out') {
      expect(
        before == null,
        isTrue,
        reason: 'Logout must remove the durable session',
      );
    }
    if (phase == 'network-retry') {
      client.dio.httpClientAdapter = _OfflineAdapter();
    }
    await tester.pumpWidget(const LearningApp());

    if (phase == 'network-retry') {
      await waitForSessionError(tester);
      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(RegisterPage), findsNothing);
      expect(find.byType(HomePage), findsNothing);
      expect((await sessions.readSession())?.token == before!.token, isTrue);
      client.dio.httpClientAdapter = transport;
      await tester.tap(find.widgetWithText(TextButton, AppCopy.retryAction));
    }

    if (phase == 'login') {
      const phone = String.fromEnvironment('LIVE_ACCOUNT_PHONE');
      expect(
        phone.isNotEmpty,
        isTrue,
        reason: 'An existing QA account is required',
      );
      final code = liveTestCode();
      if (before != null) {
        await waitFor(HomePage, restoring: true);
        await auth.logout();
      }
      await waitFor(LoginPage);
      await tester.enterText(find.byType(TextField).first, phone);
      await tester.tap(find.widgetWithText(FilledButton, AppCopy.signInAction));
      await waitFor(OtpPage);
      final digits = find.byType(TextField);
      for (var index = 0; index < code.length; index++) {
        await tester.enterText(digits.at(index), code[index]);
      }
      await tester.tap(
        find.widgetWithText(FilledButton, AppCopy.confirmAction),
      );
    }

    if (phase == 'signed-out') {
      await waitFor(LoginPage);
      expect(find.byType(HomePage), findsNothing);
    } else {
      await waitFor(HomePage, restoring: phase != 'login');
      expect(auth.state.status, AuthStatus.authenticated);
      final after = await SecureAuthSessionStore().readSession();
      expect(after != null, isTrue);
      if (phase != 'login') {
        expect(
          after!.token == before!.token,
          isTrue,
          reason: 'Relaunch must retain the same token',
        );
      }
      final profileContext = tester.element(find.byType(HomePage));
      final account = profileContext.read<AccountCubit>();
      GoRouter.of(profileContext).go(AppRoutes.profile);
      await waitFor(ProfilePage);
      final deadline = Stopwatch()..start();
      while (account.state.status == AccountStatus.loading &&
          deadline.elapsed.inSeconds < 30) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        account.state.status,
        AccountStatus.ready,
        reason: account.state.error,
      );
      expect(account.state.data.profile, isNotNull);
      expect(verifiedProfileRequests, greaterThan(0));
      if (phase == 'logout' || phase == 'revoked') {
        await auth.logout();
        await waitFor(LoginPage);
        expect(await sessions.readSession(), isNull);
        if (phase == 'revoked') {
          await sessions.saveSession(before!);
          await auth.restore();
          await waitFor(LoginPage);
          expect(auth.state.user, isNull);
          expect(await sessions.readSession(), isNull);
        }
      }
    }
    expect(tester.takeException(), isNull);
    debugPrint('SESSION_AUDIT phase=$phase passed=true');
    await tester.pumpWidget(const SizedBox.shrink());
    await services.reset();
  });
}

Future<void> waitForSessionError(WidgetTester tester) async {
  final deadline = Stopwatch()..start();
  while (deadline.elapsed.inSeconds < 30) {
    await tester.pump(const Duration(milliseconds: 100));
    final retry = find.widgetWithText(TextButton, AppCopy.retryAction);
    if (retry.evaluate().isNotEmpty) {
      final bootstrap = tester.element(retry).read<AppBootstrapCubit>();
      expect(bootstrap.state.status, BootstrapStatus.sessionError);
      return;
    }
  }
  fail('Session validation error must offer retry');
}

class _OfflineAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}
