import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/features/auth/data/auth_session_store.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('a pending deletion cannot erase a later activation write', () async {
    final storage = _DelayedDeleteStorage();
    final sessions = SecureAuthSessionStore(storage);
    await sessions.saveSession(
      const AuthSession(phone: '0500000000', token: 'old-token'),
    );
    final deletion = sessions.clearSession();
    await storage.started.future;
    final saving = sessions.saveSession(
      const AuthSession(phone: '0500000000', token: 'new-token'),
    );
    await Future<void>.value();
    storage.release.complete();
    await deletion;
    await saving;
    expect((await sessions.readSession())?.token, 'new-token');
  });

  test('rejecting an older token cannot clear the current session', () async {
    final sessions = SecureAuthSessionStore();
    await sessions.saveSession(
      const AuthSession(phone: '0500000000', token: 'new-token'),
    );
    expect(await sessions.clearSession(expectedToken: 'old-token'), isFalse);
    expect((await sessions.readSession())?.token, 'new-token');
    expect(await sessions.clearSession(expectedToken: 'new-token'), isTrue);
    expect(await sessions.readSession(), isNull);
  });

  test(
    'session survives a new store and clears without changing installation ID',
    () async {
      final first = SecureAuthSessionStore();
      final id = await first.deviceId();
      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      await first.saveSession(
        const AuthSession(phone: '0500000000', token: 'verified-token'),
      );

      final second = SecureAuthSessionStore();
      expect((await second.readSession())?.phone, '0500000000');
      expect((await second.readSession())?.token, 'verified-token');
      expect(await second.deviceId(), id);
      await second.clearSession();
      expect(await first.readSession(), isNull);
      expect(await first.deviceId(), id);
    },
  );

  test('malformed secure session is discarded', () async {
    const storage = FlutterSecureStorage();
    await storage.write(
      key: SecureAuthSessionStore.sessionKey,
      value: '{broken',
    );
    final store = SecureAuthSessionStore();
    expect(await store.readSession(), isNull);
    expect(await storage.read(key: SecureAuthSessionStore.sessionKey), isNull);
  });

  test('token containing header whitespace cannot be saved', () async {
    final store = SecureAuthSessionStore();
    await expectLater(
      store.saveSession(
        const AuthSession(phone: '0500000000', token: 'bad\r\ntoken'),
      ),
      throwsA(isA<FormatException>()),
    );
    expect(await store.readSession(), isNull);
  });
}

class _DelayedDeleteStorage extends FlutterSecureStorage {
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
  }) async {
    started.complete();
    await release.future;
    await super.delete(key: key);
  }
}
