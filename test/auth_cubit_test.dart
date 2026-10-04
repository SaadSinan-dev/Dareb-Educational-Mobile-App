import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/storage/key_value_store.dart';
import 'package:tamkeen2/features/auth/data/demo_auth_repository.dart';
import 'package:tamkeen2/features/auth/domain/auth_repository.dart';
import 'package:tamkeen2/features/auth/domain/auth_user.dart';
import 'package:tamkeen2/features/auth/domain/registration_draft.dart';
import 'package:tamkeen2/features/auth/domain/registration_options.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';

class ControlledRepository implements AuthRepository {
  @override
  Future<bool> profileCompleted() async => true;
  @override
  Future<List<GovernorateOption>> governorates() async => const [];
  @override
  Future<List<RegistrationOption>> branches() async => const [];
  @override
  Future<List<RegistrationOption>> schools({
    required int type,
    required String governorate,
  }) async => const [];
  int requestCount = 0;
  int resendCount = 0;
  Completer<AuthUser>? verification;
  @override
  Future<AuthUser?> restoreSession() async => null;
  @override
  Future<void> requestCode(String phone) async {
    requestCount++;
  }

  @override
  Future<void> resendCode(String phone) async {
    resendCount++;
  }

  @override
  Future<AuthUser> verifyCode(String phone, String code) =>
      verification!.future;
  @override
  Future<AuthUser> register(RegistrationDraft draft) async =>
      const AuthUser(id: '1', phone: '0501234567');
  @override
  Future<void> logout() async {}

  @override
  Future<void> deleteAccount() async {}
}

void main() {
  test('resend uses the dedicated repository operation', () async {
    final repository = ControlledRepository();
    final cubit = AuthCubit(repository);
    await cubit.requestCode('0501234567');
    await cubit.resendCode();
    expect(repository.requestCount, 1);
    expect(repository.resendCount, 1);
    expect(cubit.state.status, AuthStatus.codeSent);
    expect(cubit.state.phone, '0501234567');
    await cubit.close();
  });

  test('invalid phone and code cannot start verification', () async {
    final repository = ControlledRepository()
      ..verification = Completer<AuthUser>();
    final cubit = AuthCubit(repository);
    await cubit.requestCode('123');
    expect(cubit.state.status, AuthStatus.failure);
    expect(repository.requestCount, 0);
    await cubit.requestCode('٠٥٠١٢٣٤٥٦٧');
    expect(cubit.state.status, AuthStatus.codeSent);
    expect(cubit.state.phone, '0501234567');
    await cubit.verifyCode('12');
    expect(cubit.state.status, AuthStatus.failure);
    expect(cubit.state.user, isNull);
    await cubit.close();
  });

  test('logout invalidates a pending verification completion', () async {
    final repository = ControlledRepository()
      ..verification = Completer<AuthUser>();
    final cubit = AuthCubit(repository);
    await cubit.requestCode('0501234567');
    final pending = cubit.verifyCode('1234');
    await cubit.logout();
    repository.verification!.complete(
      const AuthUser(id: '1', phone: '0501234567'),
    );
    await pending;
    expect(cubit.state.status, AuthStatus.initial);
    expect(cubit.state.user, isNull);
    await cubit.close();
  });

  test(
    'draft validation rejects incomplete profile and missing consent',
    () async {
      final repository = ControlledRepository();
      final cubit = AuthCubit(repository);
      await cubit.register(
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
          acceptedTerms: false,
        ),
      );
      expect(cubit.state.status, AuthStatus.failure);
      expect(cubit.state.user, isNull);
      await cubit.close();
    },
  );

  test('safe repository failure leaves session empty', () async {
    final cubit = AuthCubit(_FailingRepository());
    await cubit.requestCode('0501234567');
    expect(cubit.state.status, AuthStatus.failure);
    expect(cubit.state.error, const AppFailure.unavailable().message);
    expect(cubit.state.user, isNull);
    await cubit.close();
  });

  test(
    'unexpected auth exception is not described as a server outage',
    () async {
      final cubit = AuthCubit(_CrashingRepository());
      await cubit.requestCode('0501234567');
      expect(cubit.state.status, AuthStatus.failure);
      expect(
        cubit.state.error,
        'حدث خطأ غير متوقع في التطبيق. يرجى المحاولة مجدداً.',
      );
      expect(cubit.state.error, isNot(contains('secret-client-detail')));
      await cubit.close();
    },
  );

  test(
    'restore and register cannot run while logout clears a session',
    () async {
      final store = _BlockingRemoveStore();
      final repository = DemoAuthRepository(store);
      await repository.requestCode('0501234567');
      await repository.verifyCode('0501234567', '1234');
      final cubit = AuthCubit(repository);
      await cubit.restore();
      expect(cubit.state.status, AuthStatus.authenticated);
      final pendingLogout = cubit.logout();
      expect(cubit.state.status, AuthStatus.loggingOut);
      await cubit.restore();
      await cubit.register(
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
      );
      expect(cubit.state.status, AuthStatus.loggingOut);
      expect(cubit.state.user, isNull);
      store.allowRemove.complete();
      await pendingLogout;
      expect(cubit.state.status, AuthStatus.initial);
      expect(await repository.restoreSession(), isNull);
      await cubit.close();
    },
  );

  test('late logout failure cannot emit after the Cubit closes', () async {
    final repository = _FailingDelayedLogoutRepository();
    final cubit = AuthCubit(repository);
    final pendingLogout = cubit.logout();
    await cubit.close();
    repository.logoutGate.completeError(const AppFailure.unavailable());
    await pendingLogout;
    expect(cubit.isClosed, isTrue);
  });
}

class _FailingRepository extends ControlledRepository {
  @override
  Future<void> requestCode(String phone) async =>
      throw const AppFailure.unavailable();
}

class _CrashingRepository extends ControlledRepository {
  @override
  Future<void> requestCode(String phone) async =>
      throw StateError('secret-client-detail');
}

class _BlockingRemoveStore implements KeyValueStore {
  final values = <String, String>{};
  final allowRemove = Completer<void>();

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    await allowRemove.future;
    values.remove(key);
  }
}

class _FailingDelayedLogoutRepository extends ControlledRepository {
  final logoutGate = Completer<void>();

  @override
  Future<void> logout() => logoutGate.future;
}
