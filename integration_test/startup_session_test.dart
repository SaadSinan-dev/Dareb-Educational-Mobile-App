import 'support/live_test_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tamkeen2/app.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/features/auth/data/auth_session_store.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/auth/presentation/screens/login_page.dart';
import 'package:tamkeen2/features/home/presentation/screens/home_page.dart';
import '../test/support/memory_store.dart';

/// Device evidence uses isolated secure-storage keys and a dedicated QA account.
/// It never replaces or clears the normal application's saved credentials.
class _Sessions implements AuthSessionStore {
  final storage = const FlutterSecureStorage();
  static const key = 'qa.architecture.session';
  @override
  Future<AuthSession?> readSession() async {
    final raw = await storage.read(key: key);
    if (raw == null) return null;
    final value = jsonDecode(raw) as Map<String, dynamic>;
    return AuthSession(
      phone: value['phone'] as String,
      token: value['token'] as String,
    );
  }

  @override
  Future<void> saveSession(AuthSession value) => storage.write(
    key: key,
    value: jsonEncode({'phone': value.phone, 'token': value.token}),
  );
  @override
  Future<bool> clearSession({String? expectedToken}) async {
    if (expectedToken != null &&
        (await readSession())?.token != expectedToken) {
      return false;
    }
    await storage.delete(key: key);
    return true;
  }

  @override
  Future<String> deviceId() async => 'qa-architecture-emulator';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real secure session bootstrap, restart, resume and invalid credentials',
    (tester) async {
      const phone = String.fromEnvironment('LIVE_ACCOUNT_PHONE');
      if (phone.isEmpty) fail('A dedicated QA account is required.');
      final sessions = _Sessions();
      await services.reset();
      configureDependencies(store: MemoryStore(), authSessionStore: sessions);
      final auth = services<AuthCubit>();
      final code = liveTestCode();
      await auth.requestCode(phone);
      expect(auth.state.status, AuthStatus.codeSent, reason: auth.state.error);
      await auth.verifyCode(code);
      expect(
        auth.state.status,
        AuthStatus.authenticated,
        reason: auth.state.error,
      );

      Future<void> waitFor(Type destination, {Type? forbidden}) async {
        final watch = Stopwatch()..start();
        while (find.byType(destination).evaluate().isEmpty &&
            watch.elapsed.inSeconds < 45) {
          await tester.pump(const Duration(milliseconds: 100));
          if (forbidden != null) expect(find.byType(forbidden), findsNothing);
        }
        expect(find.byType(destination), findsOneWidget);
      }

      await tester.pumpWidget(const LearningApp());
      expect(find.byType(LoginPage), findsNothing);
      await waitFor(HomePage, forbidden: LoginPage);
      // Rebuild the app root to exercise the same bootstrap path as restart.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const LearningApp());
      expect(find.byType(LoginPage), findsNothing);
      await waitFor(HomePage, forbidden: LoginPage);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      await auth.refreshSession();
      expect(find.byType(LoginPage), findsNothing);

      await sessions.clearSession();
      await auth.refreshSession();
      await waitFor(LoginPage);
      expect(find.byType(HomePage), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await services.reset();
      configureDependencies(store: MemoryStore(), authSessionStore: sessions);
      await sessions.saveSession(
        const AuthSession(phone: phone, token: 'invalid-qa-token'),
      );
      await tester.pumpWidget(const LearningApp());
      expect(find.byType(HomePage), findsNothing);
      await waitFor(LoginPage, forbidden: HomePage);
      expect(await sessions.readSession(), isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await services.reset();
      await sessions.clearSession();
    },
  );
}
