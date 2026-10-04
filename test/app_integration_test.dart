import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/app.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/auth/presentation/auth_pages.dart';
import 'package:tamkeen2/features/auth/data/auth_session_store.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'support/memory_store.dart';

void main() {
  setUp(() async => services.reset());
  tearDown(() async => services.reset());

  test('preview requests cannot use or erase a normal-mode session', () async {
    final sessions = _MemoryAuthSessionStore()
      ..session = const AuthSession(phone: '0500000000', token: 'live-session');
    configureDependencies(
      demoMode: true,
      store: MemoryStore(),
      authSessionStore: sessions,
    );
    final adapter = _UnauthorizedAdapter();
    final client = services<ApiClient>();
    client.dio.httpClientAdapter = adapter;
    await expectLater(client.request<Object?>('galleries/all'), throwsA(isA<AppFailure>()));
    expect(adapter.request?.headers.containsKey('Authorization'), isFalse);
    expect(sessions.session?.token, 'live-session');
  });
  testWidgets('normal mode rejects login and guards protected deep links', (
    tester,
  ) async {
    configureDependencies(
      demoMode: false,
      store: MemoryStore(),
      authSessionStore: _MemoryAuthSessionStore(),
    );
    final transport = _RejectingAdapter();
    services<ApiClient>(instanceName: 'public').dio.httpClientAdapter =
        transport;
    await tester.pumpWidget(const LearningApp());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).last);
    final router = GoRouter.of(context);
    final auth = context.read<AuthCubit>();
    final learning = context.read<CourseCubit>();
    router.go('/detail/math');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    await tester.runAsync(() => auth.requestCode('0912345678'));
    await tester.pumpAndSettle();
    expect(auth.state.user, isNull);
    expect(learning.state.courses, isEmpty);
    expect(auth.state.status, AuthStatus.failure);
    expect(transport.attempts, 1);
    expect(auth.state.error, isNot(AppCopy.registrationNotSupported));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'preview verifies OTP, restores user data, and logout clears protected state',
    (tester) async {
      configureDependencies(demoMode: true, store: MemoryStore());
      await tester.pumpWidget(const LearningApp());
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).last);
      final auth = context.read<AuthCubit>();
      final learning = context.read<CourseCubit>();
      final router = GoRouter.of(context);
      router.go('/login');
      await auth.requestCode('0912345678');
      await auth.verifyCode('1234');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(learning.state.courses, isNotEmpty);
      router.go('/register');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(find.byType(RegisterPage), findsNothing);
      learning.purchase('arabic');
      learning.download('math');
      expect(learning.state.purchasedIds, contains('arabic'));
      await auth.logout();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/login');
      expect(learning.state.purchasedIds, isEmpty);
      expect(learning.state.downloadedIds, isEmpty);
      router.go('/lesson/math/0');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/login');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('protected destination survives the login and OTP routes', (
    tester,
  ) async {
    configureDependencies(demoMode: true, store: MemoryStore());
    await tester.pumpWidget(const LearningApp());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).last);
    final router = GoRouter.of(context);
    final auth = context.read<AuthCubit>();
    router.go('/lesson/math/0');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0912345678');
    await tester.ensureVisible(find.text('سجل دخول'));
    await tester.tap(find.text('سجل دخول'));
    await tester.pumpAndSettle();
    expect(find.byType(OtpPage), findsOneWidget);
    await auth.verifyCode('1234');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/lesson/math/0');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _RejectingAdapter implements HttpClientAdapter {
  int attempts = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    attempts++;
    throw StateError('Offline fixture');
  }

  @override
  void close({bool force = false}) {}
}

class _UnauthorizedAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString('{}', 401);
  }

  @override
  void close({bool force = false}) {}
}

class _MemoryAuthSessionStore implements AuthSessionStore {
  AuthSession? session;
  @override
  Future<AuthSession?> readSession() async => session;
  @override
  Future<void> saveSession(AuthSession value) async => session = value;
  @override
  Future<bool> clearSession({String? expectedToken}) async {
    if (expectedToken != null && session?.token != expectedToken) return false;
    session = null;
    return true;
  }

  @override
  Future<String> deviceId() async => 'test-installation-id';
}
