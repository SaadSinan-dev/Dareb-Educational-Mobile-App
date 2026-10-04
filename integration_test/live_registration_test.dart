import 'support/live_test_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/features/auth/data/auth_session_store.dart';
import 'package:tamkeen2/features/auth/domain/registration_draft.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';

// Run explicitly on an emulator with a dedicated QA phone. This creates a
// real backend account, so it is intentionally outside the unit-test suite.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real registration completes on device', (tester) async {
    const phone = String.fromEnvironment('LIVE_REGISTRATION_PHONE');
    if (phone.isEmpty) {
      fail('Set LIVE_REGISTRATION_PHONE to a dedicated QA number.');
    }

    configureDependencies();
    final statuses = <String, int>{};
    void capture(ApiClient client) {
      client.dio.interceptors.add(
        InterceptorsWrapper(
          onResponse: (response, handler) {
            final path = response.requestOptions.uri.path;
            for (final endpoint in const [
              '/auth/login',
              '/auth/active',
              '/users/edit',
              '/profile/get',
            ]) {
              if (path.endsWith(endpoint)) {
                statuses[endpoint] = response.statusCode ?? 0;
              }
            }
            handler.next(response);
          },
        ),
      );
    }

    capture(services<ApiClient>(instanceName: 'public'));
    capture(services<ApiClient>());
    final auth = services<AuthCubit>();
    final code = liveTestCode();
    await auth.requestCode(phone, forRegistration: true);
    expect(auth.state.status, AuthStatus.codeSent, reason: auth.state.error);

    await auth.verifyCode(code);
    expect(
      auth.state.status,
      AuthStatus.registrationPending,
      reason: auth.state.error,
    );
    expect((await services<AuthSessionStore>().readSession())?.phone, phone);

    final governorates = await auth.governorates();
    final branches = await auth.branches();
    expect(governorates, isNotEmpty);
    expect(branches, isNotEmpty);

    final governorate = governorates.firstWhere(
      (item) => item.key == 'damascus',
      orElse: () => governorates.first,
    );
    final schools = await auth.schools(type: 1, governorate: governorate.key);
    expect(schools, isNotEmpty);
    final school = schools.first;

    await auth.register(
      RegistrationDraft(
        phone: phone,
        firstName: 'QA',
        lastName: 'Registration',
        email: 'qa.$phone@example.invalid',
        gender: Gender.female,
        age: 22,
        institutionType: InstitutionType.school,
        studyType: StudyType.science,
        referralSource: ReferralSource.friend,
        school: school.name,
        schoolId: school.id,
        branchId: branches.first.id,
        acceptedTerms: true,
      ),
    );
    expect(
      auth.state.status,
      AuthStatus.registrationSucceeded,
      reason: auth.state.error,
    );
    expect(await auth.repository.profileCompleted(), isTrue);
    expect((await auth.repository.restoreSession())?.profileComplete, isTrue);
    expect(statuses, {
      '/auth/login': 200,
      '/auth/active': 200,
      '/users/edit': 200,
      '/profile/get': 200,
    });
    // Safe evidence: endpoint and status only, never OTP, token or personal data.
    // ignore: avoid_print
    print('Registration HTTP statuses: $statuses');
  });
}
