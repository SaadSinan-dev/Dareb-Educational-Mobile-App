import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/storage/key_value_store.dart';
import 'package:tamkeen2/features/auth/data/demo_auth_repository.dart';
import 'package:tamkeen2/features/auth/data/unavailable_auth_repository.dart';
import 'package:tamkeen2/features/auth/domain/registration_draft.dart';

class MemoryStore implements KeyValueStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

class DelayedWriteStore extends MemoryStore {
  final allowWrite = Completer<void>();

  @override
  Future<void> write(String key, String value) async {
    await allowWrite.future;
    await super.write(key, value);
  }
}

void main() {
  test(
    'preview code requires a prior request and persists only session profile',
    () async {
      final store = MemoryStore();
      final repository = DemoAuthRepository(store);
      await expectLater(
        repository.verifyCode('0501234567', '1234'),
        throwsA(isA<AppFailure>()),
      );
      await repository.requestCode('0501234567');
      await expectLater(
        repository.verifyCode('0501234567', '9999'),
        throwsA(isA<AppFailure>()),
      );
      final user = await repository.verifyCode('0501234567', '1234');
      expect(user.phone, '0501234567');
      expect(
        (await DemoAuthRepository(store).restoreSession())?.phone,
        '0501234567',
      );
      expect(store.values.values.single, isNot(contains('"code"')));
      expect(store.values.values.single, isNot(contains('"otp"')));
      await repository.logout();
      expect(await DemoAuthRepository(store).restoreSession(), isNull);
    },
  );

  test('malformed saved preview data is discarded', () async {
    final store = MemoryStore();
    store.values['tamkeen.preview.auth.user.v1'] = '{broken';
    expect(await DemoAuthRepository(store).restoreSession(), isNull);
    expect(store.values, isEmpty);
  });

  test('logout clears a preview verification write still in flight', () async {
    final store = DelayedWriteStore();
    final repository = DemoAuthRepository(store);
    await repository.requestCode('0501234567');
    final verification = repository.verifyCode('0501234567', '1234');
    final logout = repository.logout();
    store.allowWrite.complete();
    await Future.wait([verification, logout]);
    expect(await DemoAuthRepository(store).restoreSession(), isNull);
  });

  test('unavailable repository cannot produce authenticated user', () async {
    final repository = UnavailableAuthRepository();
    expect(await repository.restoreSession(), isNull);
    await expectLater(
      repository.requestCode('0501234567'),
      throwsA(isA<AppFailure>()),
    );
    await expectLater(
      repository.verifyCode('0501234567', '1234'),
      throwsA(isA<AppFailure>()),
    );
    await expectLater(
      repository.register(
        const RegistrationDraft(
          gender: Gender.female,
          age: 16,
          institutionType: InstitutionType.school,
          studyType: StudyType.science,
          firstName: 'سارة',
          lastName: 'أحمد',
          email: 'sara@example.com',
          phone: '0501234567',
          school: 'مدرسة النجاح',
          referralSource: ReferralSource.friend,
          acceptedTerms: true,
        ),
      ),
      throwsA(isA<AppFailure>()),
    );
  });
}
