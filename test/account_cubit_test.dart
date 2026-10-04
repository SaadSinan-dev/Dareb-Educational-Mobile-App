import 'package:tamkeen2/features/contact/presentation/contact_cubit.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/features/account/domain/account_models.dart';
import 'package:tamkeen2/features/account/domain/account_repository.dart';
import 'package:tamkeen2/features/account/presentation/account_cubit.dart';

class DelayedAccountRepository implements AccountRepository {
  final loadResult = Completer<AccountData>();
  final saveResult = Completer<AccountProfile>();
  int imageCalls = 0;

  @override
  Future<AccountData> load(String userId) => loadResult.future;
  @override
  Future<AccountProfile> saveProfile(String userId, AccountProfile profile) =>
      saveResult.future;
  @override
  Future<AccountProfile> updateImage(
    String userId,
    Uint8List bytes,
    String filename,
    String? mimeType,
  ) {
    imageCalls++;
    return saveResult.future;
  }

  @override
  Future<void> markNotificationRead(String userId, String id) async {}
  @override
  Future<ContactResult> submitContact(ContactMessage message) async =>
      const ContactResult(delivered: false, message: 'معاينة');
}

void main() {
  test(
    'image upload is single-flight and shows the confirmed profile',
    () async {
      final repository = DelayedAccountRepository();
      final cubit = AccountCubit(repository);
      final bytes = Uint8List.fromList([1, 2, 3]);
      final update = cubit.updateImage(
        'user',
        bytes,
        'avatar.png',
        'image/png',
      );
      await cubit.updateImage('user', bytes, 'avatar.png', 'image/png');
      expect(repository.imageCalls, 1);
      expect(cubit.state.actionStatus, AccountActionStatus.submitting);
      repository.saveResult.complete(
        const AccountProfile(
          firstName: 'QA',
          lastName: 'Verified',
          school: 'School',
          imageUrl: 'https://example.test/avatar.png',
        ),
      );
      await update;
      expect(cubit.state.actionStatus, AccountActionStatus.success);
      expect(
        cubit.state.data.profile?.imageUrl,
        'https://example.test/avatar.png',
      );
      await cubit.close();
    },
  );

  test(
    'unexpected account exception is not described as a server outage',
    () async {
      final repository = DelayedAccountRepository();
      final cubit = AccountCubit(repository);
      final loading = cubit.load('user');
      repository.loadResult.completeError(StateError('secret-client-detail'));
      await loading;
      expect(cubit.state.status, AccountStatus.failure);
      expect(
        cubit.state.error,
        'حدث خطأ غير متوقع في التطبيق. يرجى المحاولة مجدداً.',
      );
      await cubit.close();
    },
  );

  test('reset ignores an older load completion', () async {
    final repository = DelayedAccountRepository();
    final cubit = AccountCubit(repository);
    final loading = cubit.load('user');
    cubit.reset();
    repository.loadResult.complete(const AccountData());
    await loading;
    expect(cubit.state.status, AccountStatus.initial);
    await cubit.close();
  });

  test('closing during profile save does not emit completion', () async {
    final repository = DelayedAccountRepository();
    final cubit = AccountCubit(repository);
    const profile = AccountProfile(
      firstName: 'سارة',
      lastName: 'أحمد',
      school: 'مدرسة',
    );
    final saving = cubit.saveProfile('user', profile);
    await cubit.close();
    repository.saveResult.complete(profile);
    await saving;
  });

  test('preview contact result is neutral, not delivery success', () async {
    final cubit = ContactCubit(DelayedAccountRepository());
    await cubit.submitContact(
      const ContactMessage(
        name: 'سارة',
        lastName: 'أحمد',
        phone: '0501234567',
        description: 'أحتاج للمساعدة',
      ),
    );
    expect(cubit.state.actionStatus, ContactStatus.preview);
    expect(cubit.state.actionMessage, contains('معاينة'));
    await cubit.close();
  });
}
