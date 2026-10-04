import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The submitted phone is a local session key, not an inferred server user ID.
class AuthSession {
  const AuthSession({required this.phone, required this.token});

  final String phone;
  final String token;
}

abstract interface class AuthSessionStore {
  Future<AuthSession?> readSession();
  Future<void> saveSession(AuthSession session);
  Future<bool> clearSession({String? expectedToken});
  Future<String> deviceId();
}

/// Persists credentials and an app-installation ID in platform secure storage.
class SecureAuthSessionStore implements AuthSessionStore {
  SecureAuthSessionStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(resetOnError: false),
          );

  static const sessionKey = 'tamkeen.auth.session.v1';
  static const installationIdKey = 'tamkeen.auth.installation_id.v1';

  final FlutterSecureStorage _storage;
  Future<String>? _pendingDeviceId;
  Future<void> _sessionOperations = Future<void>.value();

  @override
  Future<AuthSession?> readSession() => _serialize(_readSession);

  Future<AuthSession?> _readSession() async {
    final raw = await _storage.read(key: sessionKey);
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw);
      if (value is Map &&
          value['phone'] is String &&
          (value['phone'] as String).isNotEmpty &&
          value['token'] is String &&
          _validToken(value['token'] as String)) {
        return AuthSession(
          phone: value['phone'] as String,
          token: value['token'] as String,
        );
      }
    } on FormatException {
      // An interrupted or obsolete value cannot establish a session.
    }
    await _storage.delete(key: sessionKey);
    return null;
  }

  @override
  Future<void> saveSession(AuthSession session) => _serialize(() async {
    if (session.phone.isEmpty || !_validToken(session.token)) {
      throw const FormatException('Invalid auth session');
    }
    await _storage.write(
      key: sessionKey,
      value: jsonEncode({'phone': session.phone, 'token': session.token}),
    );
  });

  @override
  Future<bool> clearSession({String? expectedToken}) => _serialize(() async {
    if (expectedToken != null &&
        (await _readSession())?.token != expectedToken) {
      return false;
    }
    await _storage.delete(key: sessionKey);
    return true;
  });

  Future<Result> _serialize<Result>(Future<Result> Function() operation) {
    final result = _sessionOperations.then((_) => operation());
    _sessionOperations = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  @override
  Future<String> deviceId() {
    return _pendingDeviceId ??= _loadDeviceId().whenComplete(() {
      _pendingDeviceId = null;
    });
  }

  Future<String> _loadDeviceId() async {
    final existing = await _storage.read(key: installationIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final id =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    await _storage.write(key: installationIdKey, value: id);
    return id;
  }

  static bool _validToken(String value) =>
      value.isNotEmpty && !value.contains(RegExp(r'\s'));
}
