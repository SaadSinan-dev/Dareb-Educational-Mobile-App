import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/storage/key_value_store.dart';
import 'package:tamkeen2/features/account/data/demo_account_repository.dart';
import 'package:tamkeen2/features/account/data/unavailable_account_repository.dart';
import 'package:tamkeen2/features/account/domain/account_models.dart';

class AccountMemoryStore implements KeyValueStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> remove(String key) async => values.remove(key);
}

class DelayedAccountReadStore extends AccountMemoryStore {
  final releaseReads = Completer<void>();

  @override
  Future<String?> read(String key) async {
    final snapshot = values[key];
    await releaseReads.future;
    return snapshot;
  }
}

void main() {
  test(
    'unavailable mutations never report account or contact success',
    () async {
      final repository = UnavailableAccountRepository();
      await expectLater(
        repository.saveProfile(
          'user',
          const AccountProfile(
            firstName: 'سارة',
            lastName: 'أحمد',
            school: 'مدرسة النجاح',
          ),
        ),
        throwsA(isA<AppFailure>()),
      );
      await expectLater(
        repository.submitContact(
          const ContactMessage(
            name: 'سارة',
            lastName: 'أحمد',
            phone: '0501234567',
            description: 'أحتاج للمساعدة',
          ),
        ),
        throwsA(isA<AppFailure>()),
      );
      await expectLater(
        repository.markNotificationRead('user', 'new-offer'),
        throwsA(isA<AppFailure>()),
      );
    },
  );

  test('corrupt preview account data is discarded without crashing', () async {
    final store = AccountMemoryStore();
    store.values['tamkeen.preview.account.user.v1'] = '{broken';
    final data = await DemoAccountRepository(store).load('user');
    expect(data.profile, isNull);
    expect(data.readNotificationIds, isEmpty);
    expect(store.values, isEmpty);
  });

  test('preview read state persists for the same account only', () async {
    final store = AccountMemoryStore();
    final repository = DemoAccountRepository(store);
    await repository.markNotificationRead('user-a', 'new-offer');
    expect(
      (await DemoAccountRepository(store).load('user-a')).readNotificationIds,
      {'new-offer'},
    );
    expect(
      (await DemoAccountRepository(store).load('user-b')).readNotificationIds,
      isEmpty,
    );
  });

  test('profile and contact validation reject incomplete input', () {
    expect(
      const AccountProfile(
        firstName: '',
        lastName: 'أحمد',
        school: 'مدرسة',
      ).validationError,
      isNotNull,
    );
    expect(
      const AccountProfile(
        firstName: 'سارة',
        lastName: 'أحمد',
        school: '',
      ).validationError,
      isNotNull,
    );
    expect(
      const ContactMessage(
        name: 'سارة',
        lastName: 'أحمد',
        phone: 'abc',
        description: 'رسالة',
      ).validationError,
      isNotNull,
    );
    expect(
      const ContactMessage(
        name: 'سارة',
        lastName: 'أحمد',
        phone: '0501234567',
        description: ' ',
      ).validationError,
      isNotNull,
    );
  });

  test(
    'preview contact result explicitly says no message was delivered',
    () async {
      final result = await DemoAccountRepository(AccountMemoryStore())
          .submitContact(
            const ContactMessage(
              name: 'سارة',
              lastName: 'أحمد',
              phone: '0501234567',
              description: 'أحتاج للمساعدة',
            ),
          );
      expect(result.delivered, isFalse);
      expect(result.message, contains('معاينة'));
    },
  );

  test('overlapping profile and read updates preserve every change', () async {
    final store = DelayedAccountReadStore();
    final repository = DemoAccountRepository(store);
    final profileSave = repository.saveProfile(
      'user',
      const AccountProfile(
        firstName: 'سارة',
        lastName: 'أحمد',
        school: 'مدرسة النجاح',
      ),
    );
    final firstRead = repository.markNotificationRead('user', 'new-offer');
    final secondRead = repository.markNotificationRead(
      'user',
      'service-update-1',
    );
    store.releaseReads.complete();
    await Future.wait([profileSave, firstRead, secondRead]);
    final data = await DemoAccountRepository(store).load('user');
    expect(data.profile?.displayName, 'سارة أحمد');
    expect(data.readNotificationIds, {'new-offer', 'service-update-1'});
  });

  test('demo account data supplies summary and achievement records', () async {
    final data = await DemoAccountRepository(AccountMemoryStore()).load('user');
    expect(data.summary?.lessons, 12);
    expect(data.achievements.map((item) => item.title), contains('الرياضيات'));
    expect(data.achievements.first.points, 55);
  });
}
