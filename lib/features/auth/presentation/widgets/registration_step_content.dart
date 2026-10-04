import 'package:tamkeen2/core/widgets/source_icon.dart';
import 'package:tamkeen2/features/auth/presentation/registration_options_cubit.dart';

import 'package:flutter/material.dart';

import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:tamkeen2/features/auth/domain/registration_draft.dart';
import 'package:tamkeen2/features/auth/domain/registration_options.dart';
import 'package:tamkeen2/features/auth/presentation/widgets/auth_header.dart';

class RegistrationStepContent extends StatefulWidget {
  const RegistrationStepContent({
    super.key,
    required this.step,
    required this.draft,
    required this.onChanged,
    required this.options,
    required this.onInstitution,
    required this.onGovernorate,
    required this.showTerms,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  });
  final int step;
  final RegistrationDraft draft;
  final ValueChanged<RegistrationDraft> onChanged;
  final RegistrationOptionsState options;
  final ValueChanged<InstitutionType> onInstitution;
  final ValueChanged<String> onGovernorate;
  final VoidCallback showTerms;
  final TextEditingController firstName, lastName, email, phone;
  @override
  State<RegistrationStepContent> createState() =>
      _RegistrationStepContentState();
}

class _RegistrationStepContentState extends State<RegistrationStepContent> {
  int get _step => widget.step;
  RegistrationDraft get _draft => widget.draft;
  set _draft(RegistrationDraft value) => widget.onChanged(value);
  List<RegistrationOption> get _branches => widget.options.branches;
  List<GovernorateOption> get _governorates => widget.options.governorates;
  List<RegistrationOption> get _schools => widget.options.schools;
  String? get _governorate => widget.options.governorate;
  TextEditingController get _firstName => widget.firstName;
  TextEditingController get _lastName => widget.lastName;
  TextEditingController get _email => widget.email;
  TextEditingController get _phone => widget.phone;
  void _selectInstitutionType(InstitutionType type) =>
      widget.onInstitution(type);
  void _showTerms() => widget.showTerms();
  @override
  Widget build(BuildContext context) => _content();
  Widget _content() {
    switch (_step) {
      case 1:
        return Column(
          children: [
            _choice(
              AppCopy.maleOption,
              Icons.male,
              _draft.gender == Gender.male,
              () =>
                  setState(() => _draft = _draft.copyWith(gender: Gender.male)),
            ),
            _choice(
              AppCopy.femaleOption,
              Icons.female,
              _draft.gender == Gender.female,
              () => setState(
                () => _draft = _draft.copyWith(gender: Gender.female),
              ),
            ),
          ],
        );
      case 0:
        return Container(
          padding: const EdgeInsets.all(30),
          decoration: _box(),
          child: Column(
            children: [
              const AppText(AppCopy.ageLabel),
              AppText(
                '${_draft.age}',
                style: TextStyle(
                  color: context.colors.primary,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: TextDirection.ltr,
                children: [
                  IconButton.outlined(
                    onPressed: _draft.age! <= 7
                        ? null
                        : () => setState(
                            () =>
                                _draft = _draft.copyWith(age: _draft.age! - 1),
                          ),
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 28),
                  IconButton.outlined(
                    onPressed: _draft.age! >= 100
                        ? null
                        : () => setState(
                            () =>
                                _draft = _draft.copyWith(age: _draft.age! + 1),
                          ),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        );
      case 3:
        return Column(
          children: [
            _choice(
              AppCopy.schoolInstitutionOption,
              Icons.school_outlined,
              _draft.institutionType == InstitutionType.school,
              () => _selectInstitutionType(InstitutionType.school),
              subtitle: AppCopy.schoolInstitutionDescription,
            ),
            _choice(
              AppCopy.instituteInstitutionOption,
              Icons.account_balance_outlined,
              _draft.institutionType == InstitutionType.institute,
              () => _selectInstitutionType(InstitutionType.institute),
              subtitle: AppCopy.instituteInstitutionDescription,
            ),
          ],
        );
      case 4:
        return Column(
          children: [
            _choice(
              AppCopy.scienceBaccalaureateOption,
              Icons.science_outlined,
              _draft.studyType == StudyType.science,
              () => setState(
                () => _draft = _draft.copyWith(studyType: StudyType.science),
              ),
            ),
            _choice(
              AppCopy.humanitiesBaccalaureateOption,
              Icons.menu_book_outlined,
              _draft.studyType == StudyType.literature,
              () => setState(
                () => _draft = _draft.copyWith(studyType: StudyType.literature),
              ),
            ),
            _choice(
              AppCopy.commerceBaccalaureateOption,
              Icons.calculate_outlined,
              _draft.studyType == StudyType.commerce,
              () => setState(
                () => _draft = _draft.copyWith(studyType: StudyType.commerce),
              ),
            ),
            DropdownButtonFormField<int>(
              initialValue: _draft.branchId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.tr(AppCopy.branchLabel),
              ),
              items: [
                for (final branch in _branches)
                  DropdownMenuItem(value: branch.id, child: Text(branch.name)),
              ],
              onChanged: (value) =>
                  setState(() => _draft = _draft.copyWith(branchId: value)),
            ),
          ],
        );
      case 5:
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: _box(),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final names = [
                    _field(
                      _firstName,
                      AppCopy.firstNameLabel,
                      Icons.person_outline,
                    ),
                    _field(
                      _lastName,
                      AppCopy.lastNameLabel,
                      Icons.person_outline,
                    ),
                  ];
                  if (constraints.maxWidth < 300) {
                    return Column(children: names);
                  }
                  return Row(
                    children: [
                      Expanded(child: names[0]),
                      const SizedBox(width: 12),
                      Expanded(child: names[1]),
                    ],
                  );
                },
              ),
              _field(
                _email,
                AppCopy.enterEmailHint,
                Icons.mail_outline,
                keyboard: TextInputType.emailAddress,
              ),
              _field(
                _phone,
                AppCopy.phoneNumberLabel,
                Icons.phone_outlined,
                keyboard: TextInputType.phone,
                enabled: false,
              ),
              DropdownButtonFormField<String>(
                initialValue: _governorate,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr(AppCopy.governorateLabel),
                ),
                items: [
                  for (final option in _governorates)
                    DropdownMenuItem(
                      value: option.key,
                      child: Text(option.name),
                    ),
                ],
                onChanged: (value) {
                  if (value == null || value == _governorate) return;
                  widget.onGovernorate(value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                key: ValueKey('${_governorate}_${_draft.institutionType}'),
                initialValue: _draft.schoolId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr(AppCopy.schoolOrInstituteLabel),
                ),
                items: [
                  for (final option in _schools)
                    DropdownMenuItem(
                      value: option.id,
                      child: Text(
                        option.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  final selected = _schools
                      .where((option) => option.id == value)
                      .firstOrNull;
                  if (selected != null) {
                    setState(
                      () => _draft = _draft.copyWith(
                        schoolId: selected.id,
                        school: selected.name,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      case 2:
        final choices = [
          (
            ReferralSource.facebook,
            AppCopy.facebookReferralOption,
            Icons.facebook,
          ),
          (
            ReferralSource.friend,
            AppCopy.friendReferralOption,
            Icons.people_outline,
          ),
          (ReferralSource.school, AppCopy.schoolLabel, Icons.school_outlined),
          (
            ReferralSource.instagram,
            AppCopy.instagramReferralOption,
            Icons.camera_alt_outlined,
          ),
          (ReferralSource.other, AppCopy.otherReferralOption, Icons.more_horiz),
        ];
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final choice in choices)
              SizedBox(
                width: 125,
                child: _choice(
                  choice.$2,
                  choice.$3,
                  _draft.referralSource == choice.$1,
                  () => setState(
                    () => _draft = _draft.copyWith(referralSource: choice.$1),
                  ),
                  compact: true,
                ),
              ),
          ],
        );
      default:
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: _box(),
          child: Column(
            children: [
              Icon(
                Icons.verified_outlined,
                color: authAccent(context),
                size: 54,
              ),
              const SizedBox(height: 12),
              const AppText(
                AppCopy.termsAndConditionsTitle,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _draft.acceptedTerms,
                    onChanged: (value) => setState(
                      () => _draft = _draft.copyWith(
                        acceptedTerms: value ?? false,
                      ),
                    ),
                  ),
                  const Expanded(child: AppText(AppCopy.agreeToTermsLabel)),
                ],
              ),
              TextButton(
                onPressed: _showTerms,
                child: const AppText(AppCopy.readTermsAction),
              ),
            ],
          ),
        );
    }
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    bool enabled = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: controller,
      keyboardType: keyboard,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: context.tr(label),
        prefixIcon: Icon(icon, color: authAccent(context)),
      ),
    ),
  );

  BoxDecoration _box() => BoxDecoration(
    border: Border.all(
      color: Theme.of(context).brightness == Brightness.light
          ? const Color(0xFFD6D6D6)
          : context.colors.border,
    ),
    borderRadius: BorderRadius.circular(24),
  );

  Widget _choice(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap, {
    String? subtitle,
    bool compact = false,
  }) => Padding(
    padding: EdgeInsets.only(bottom: compact ? 0 : 14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: compact ? 18 : 16,
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? context.colors.primary
                : Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFD6D6D6)
                : context.colors.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          color: context.colors.surface,
        ),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  _choiceIcon(icon, selected, compact),
                  const SizedBox(height: 8),
                  AppText(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: compact ? 13 : 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 7),
                    AppText(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFF666666)
                            : context.colors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              Positioned.directional(
                textDirection: Directionality.of(context),
                end: 0,
                top: 0,
                child: SourceIcon(
                  SourceIconName.registrationCheck,
                  size: 23,
                  color: context.colors.primary,
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _choiceIcon(IconData icon, bool selected, bool compact) {
    final asset = switch (icon) {
      Icons.male => SourceIconName.registrationMale,
      Icons.female => SourceIconName.registrationFemale,
      Icons.school_outlined =>
        compact
            ? SourceIconName.referralSchool
            : SourceIconName.registrationSchool,
      Icons.account_balance_outlined => SourceIconName.registrationInstitute,
      Icons.science_outlined => SourceIconName.registrationScience,
      Icons.menu_book_outlined => SourceIconName.registrationLiterature,
      Icons.calculate_outlined => SourceIconName.registrationCommerce,
      Icons.facebook => SourceIconName.referralFacebook,
      Icons.people_outline => SourceIconName.referralFriend,
      Icons.camera_alt_outlined => SourceIconName.referralInstagram,
      Icons.more_horiz => SourceIconName.referralOther,
      _ => null,
    };
    final tint = selected ? context.colors.primary : authAccent(context);
    if (asset == null) return Icon(icon, color: tint, size: compact ? 27 : 31);
    final glyph = SourceIcon(
      asset,
      size: 28,
      color: (icon == Icons.male || icon == Icons.female) && !selected
          ? context.colors.muted
          : tint,
    );
    if (icon == Icons.male || icon == Icons.female || compact) return glyph;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: selected ? context.colors.softTeal : context.colors.softBlue,
      ),
      alignment: Alignment.center,
      child: glyph,
    );
  }
}
