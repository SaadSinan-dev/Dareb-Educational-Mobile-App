import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/features/auth/domain/auth_input.dart';
import 'package:tamkeen2/core/validation/app_validators.dart';

enum Gender { male, female }

enum InstitutionType { school, institute }

enum StudyType { science, literature, commerce }

enum ReferralSource { facebook, friend, school, instagram, other }

/// Partial while the user moves through the form; validated before submission.
class RegistrationDraft {
  const RegistrationDraft({
    this.gender,
    this.age,
    this.institutionType,
    this.studyType,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.school = '',
    this.schoolId,
    this.branchId,
    this.referralSource,
    this.acceptedTerms = false,
  });

  final Gender? gender;
  final int? age;
  final InstitutionType? institutionType;
  final StudyType? studyType;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String school;
  final int? schoolId;
  final int? branchId;
  final ReferralSource? referralSource;
  final bool acceptedTerms;

  RegistrationDraft copyWith({
    Gender? gender,
    int? age,
    InstitutionType? institutionType,
    StudyType? studyType,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? school,
    int? schoolId,
    bool clearSchoolId = false,
    int? branchId,
    ReferralSource? referralSource,
    bool? acceptedTerms,
  }) => RegistrationDraft(
    gender: gender ?? this.gender,
    age: age ?? this.age,
    institutionType: institutionType ?? this.institutionType,
    studyType: studyType ?? this.studyType,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    school: school ?? this.school,
    schoolId: clearSchoolId ? null : schoolId ?? this.schoolId,
    branchId: branchId ?? this.branchId,
    referralSource: referralSource ?? this.referralSource,
    acceptedTerms: acceptedTerms ?? this.acceptedTerms,
  );

  String? get validationError {
    if (gender == null ||
        age == null ||
        AppValidators.age('$age') != null ||
        institutionType == null ||
        studyType == null) {
      return AppCopy.completePersonalAndStudyDetails;
    }
    if (AppValidators.name(firstName) != null ||
        AppValidators.name(lastName) != null ||
        AppValidators.school(school) != null) {
      return AppCopy.enterNameAndSchool;
    }
    if (AppValidators.email(email) != null) {
      return AppCopy.validEmailRequired;
    }
    if (AuthInput.phone(phone) == null) return AppCopy.validPhoneNumberRequired;
    if (referralSource == null) return AppCopy.selectReferralSource;
    if (!acceptedTerms) return AppCopy.acceptTermsRequired;
    return null;
  }
}
