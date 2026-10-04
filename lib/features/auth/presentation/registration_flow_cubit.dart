import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tamkeen2/features/auth/domain/auth_input.dart';
import 'package:tamkeen2/core/validation/app_validators.dart';
import 'package:tamkeen2/features/auth/domain/registration_draft.dart';

class RegistrationFlowState {
  const RegistrationFlowState({
    this.draft = const RegistrationDraft(age: 26),
    this.step = 0,
    this.error,
  });

  final RegistrationDraft draft;
  final int step;
  final String? error;
}

/// Owns the local registration draft until AuthCubit submits it.
class RegistrationFlowCubit extends Cubit<RegistrationFlowState> {
  RegistrationFlowCubit() : super(const RegistrationFlowState());

  void update(RegistrationDraft draft) {
    if (isClosed) return;
    emit(RegistrationFlowState(draft: draft, step: state.step));
  }

  void back() {
    if (isClosed || state.step == 0) return;
    emit(RegistrationFlowState(draft: state.draft, step: state.step - 1));
  }

  bool advance() {
    if (isClosed) return false;
    final draft = state.draft;
    final error = switch (state.step) {
      0 when AppValidators.age('${draft.age ?? ''}') != null =>
        AppCopy.selectAgeRangeRequired,
      1 when draft.gender == null => AppCopy.selectGenderRequired,
      2 when draft.referralSource == null => AppCopy.selectReferralSource,
      3 when draft.institutionType == null =>
        AppCopy.selectInstitutionTypeRequired,
      4 when draft.studyType == null || draft.branchId == null =>
        AppCopy.selectStudyTrackRequired,
      5
          when AppValidators.name(draft.firstName) != null ||
              AppValidators.name(draft.lastName) != null ||
              draft.schoolId == null =>
        AppCopy.completeAccountDetailsRequired,
      5 when AppValidators.email(draft.email) != null =>
        AppCopy.validEmailRequired,
      5 when AuthInput.phone(draft.phone) == null =>
        AppCopy.validPhoneNumberRequired,
      6 => draft.validationError,
      _ => null,
    };
    if (error != null) {
      emit(RegistrationFlowState(draft: draft, step: state.step, error: error));
      return false;
    }
    if (state.step < 6) {
      emit(RegistrationFlowState(draft: draft, step: state.step + 1));
    }
    return true;
  }
}
