import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/features/auth/domain/registration_draft.dart';
import 'package:tamkeen2/features/auth/presentation/registration_flow_cubit.dart';

void main() {
  test(
    'registration keeps choices and account details when moving back',
    () async {
      final flow = RegistrationFlowCubit();
      flow.update(flow.state.draft.copyWith(gender: Gender.female));
      expect(flow.advance(), isTrue);
      expect(flow.state.step, 1);
      flow.update(flow.state.draft.copyWith(age: 26));
      expect(flow.advance(), isTrue);
      flow.back();
      expect(flow.state.step, 1);
      expect(flow.state.draft.gender, Gender.female);
      expect(flow.state.draft.age, 26);
      await flow.close();
    },
  );

  test('account step rejects malformed email before advancing', () async {
    final flow = RegistrationFlowCubit();
    flow.update(
      const RegistrationDraft(
        gender: Gender.female,
        age: 16,
        institutionType: InstitutionType.school,
        studyType: StudyType.science,
        branchId: 1,
        schoolId: 7,
        referralSource: ReferralSource.friend,
        firstName: 'سارة',
        lastName: 'أحمد',
        email: 'invalid',
        phone: '0501234567',
        school: 'مدرسة النجاح',
      ),
    );
    for (var i = 0; i < 5; i++) {
      expect(flow.advance(), isTrue);
    }
    expect(flow.state.step, 5);
    expect(flow.advance(), isFalse);
    expect(flow.state.step, 5);
    expect(flow.state.error, isNotNull);
    await flow.close();
  });
}
