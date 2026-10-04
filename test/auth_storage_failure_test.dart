import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/features/auth/data/auth_session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Android read failure preserves credentials for a later retry',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      const channel = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      String? saved = jsonEncode({
        'phone': '0500000000',
        'token': 'persisted-token',
      });
      bool unavailable = true;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'read') {
          final arguments = call.arguments as Map;
          final options = arguments['options'] as Map;
          if (unavailable) {
            if (options['resetOnError'] == 'true') {
              saved = null;
              return null;
            }
            throw PlatformException(code: 'storage-unavailable');
          }
          return saved;
        }
        fail('Unexpected storage operation: ${call.method}');
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(channel, null);
        debugDefaultTargetPlatformOverride = null;
      });

      final sessions = SecureAuthSessionStore();
      await expectLater(
        sessions.readSession(),
        throwsA(isA<PlatformException>()),
      );
      unavailable = false;
      expect((await sessions.readSession())?.token, 'persisted-token');
    },
  );
}
