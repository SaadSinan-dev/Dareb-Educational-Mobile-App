import 'dart:async';
import 'package:tamkeen2/features/profile/presentation/school_options_cubit.dart';
import 'package:tamkeen2/core/state/resource_cubit.dart';
import 'package:tamkeen2/core/widgets/source_icon.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:tamkeen2/core/validation/app_validators.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/features/auth/domain/registration_draft.dart';
import 'package:tamkeen2/features/auth/domain/registration_options.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/account/domain/account_models.dart';
import 'package:tamkeen2/features/account/presentation/account_common.dart';
import 'package:tamkeen2/features/account/presentation/account_cubit.dart';
import 'package:tamkeen2/features/account/presentation/account_preview_mode.dart';

import 'package:tamkeen2/features/profile/presentation/widgets/profile_modal.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, this.completion = false});

  /// The Home prompt includes a gender choice; Profile editing keeps its own sheet.
  final bool completion;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _school;
  int? _schoolId;
  String? _schoolGovernorate;
  List<RegistrationOption> _schoolOptions = const [];
  String? _schoolOptionsError;
  SchoolOptionsCubit? _options;
  StreamSubscription<ResourceState<List<RegistrationOption>>>?
  _optionsSubscription;
  Gender? _gender;
  bool _profileHydrated = false;

  @override
  void initState() {
    super.initState();
    if (!accountPreviewMode(context, null)) {
      _options = context.read<SchoolOptionsCubit>();
      _optionsSubscription = _options!.stream.listen((state) {
        if (mounted) {
          setState(() {
            _schoolOptions = state.data ?? _schoolOptions;
            _schoolOptionsError = state.error;
          });
        }
      });
    }
    final profile = context.read<AccountCubit>().state.data.profile;
    final user = context.read<AuthCubit>().state.user;
    _first = TextEditingController(
      text: profile?.firstName ?? user?.firstName ?? '',
    );
    _last = TextEditingController(
      text: profile?.lastName ?? user?.lastName ?? '',
    );
    _school = TextEditingController(
      text: profile?.school ?? user?.school ?? '',
    );
    _schoolId = profile?.schoolId;
    _schoolGovernorate = profile?.schoolGovernorate;
    _profileHydrated = accountPreviewMode(context, null) || profile != null;
    if (_schoolId != null) {
      _schoolOptions = [RegistrationOption(id: _schoolId!, name: _school.text)];
    }
    if (!accountPreviewMode(context, null) && _schoolGovernorate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadSchoolOptions());
    }
    if (!accountPreviewMode(context, null) && profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final account = context.read<AccountCubit>();
        if (account.state.status == AccountStatus.initial && user != null) {
          account.load(user.id);
        }
      });
    }
    if (widget.completion) {
      _gender = switch (user?.gender) {
        'male' => Gender.male,
        'female' => Gender.female,
        _ => null,
      };
    }
    context.read<AccountCubit>().clearAction();
  }

  void _hydrateProfile(AccountProfile profile) {
    if (_profileHydrated) return;
    _first.text = profile.firstName;
    _last.text = profile.lastName;
    _school.text = profile.school;
    setState(() {
      _schoolId = profile.schoolId;
      _schoolGovernorate = profile.schoolGovernorate;
      _schoolOptions = profile.schoolId == null
          ? const []
          : [RegistrationOption(id: profile.schoolId!, name: profile.school)];
      _profileHydrated = true;
    });
    _loadSchoolOptions();
  }

  Future<void> _loadSchoolOptions() async {
    final governorate = _schoolGovernorate;
    if (!mounted || governorate == null) return;
    await _options?.refresh(governorate, _schoolOptions);
  }

  @override
  void dispose() {
    _optionsSubscription?.cancel();
    _first.dispose();
    _last.dispose();
    _school.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AccountCubit>().state;
    return BlocListener<AccountCubit, AccountState>(
      listenWhen: (previous, current) =>
          !_profileHydrated &&
          current.status == AccountStatus.ready &&
          current.data.profile != null,
      listener: (context, state) => _hydrateProfile(state.data.profile!),
      child: ProfileModal(
        title: widget.completion
            ? AppCopy.completeProfileTitle
            : AppCopy.editPersonalInformationHeading,
        icon: widget.completion
            ? Icons.manage_accounts_outlined
            : Icons.edit_outlined,
        leadingIcon: widget.completion
            ? null
            : SourceIcon(SourceIconName.edit, color: accountAccent(context)),
        overlay: true,
        child: !_profileHydrated && !accountPreviewMode(context, null)
            ? state.status == AccountStatus.failure ||
                      state.status == AccountStatus.ready
                  ? Column(
                      children: [
                        AppText(
                          state.error ?? AppCopy.unexpectedResponse,
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () => context.read<AccountCubit>().load(
                            accountUserId(context),
                          ),
                          child: const AppText(AppCopy.retryAction),
                        ),
                      ],
                    )
                  : const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    )
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _first,
                            decoration: InputDecoration(
                              labelText: context.tr(AppCopy.firstNameLabel),
                              prefixIcon: SourceIcon(
                                SourceIconName.profileCircle,
                                size: 24,
                                color: accountAccent(context),
                              ),
                            ),
                            validator: (value) {
                              final error = AppValidators.name(value);
                              return error == null ? null : context.tr(error);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _last,
                            decoration: InputDecoration(
                              labelText: context.tr(AppCopy.lastNameLabel),
                              prefixIcon: SourceIcon(
                                SourceIconName.profileCircle,
                                size: 24,
                                color: accountAccent(context),
                              ),
                            ),
                            validator: (value) {
                              final error = AppValidators.name(value);
                              return error == null ? null : context.tr(error);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    if (accountPreviewMode(context, null))
                      TextFormField(
                        controller: _school,
                        decoration: InputDecoration(
                          labelText: context.tr(AppCopy.schoolLabel),
                          prefixIcon: SourceIcon(
                            SourceIconName.referralSchool,
                            color: accountAccent(context),
                          ),
                        ),
                        validator: (value) {
                          final error = AppValidators.school(value);
                          return error == null ? null : context.tr(error);
                        },
                      )
                    else
                      DropdownButtonFormField<int>(
                        initialValue: _schoolId,
                        isExpanded: true,
                        icon: SourceIcon(
                          SourceIconName.arrow,
                          size: 14,
                          quarterTurns: 1,
                          color: accountAccent(context),
                        ),
                        decoration: InputDecoration(
                          labelText: context.tr(AppCopy.schoolLabel),
                          prefixIcon: SourceIcon(
                            SourceIconName.referralSchool,
                            color: accountAccent(context),
                          ),
                        ),
                        items: [
                          for (final option in _schoolOptions)
                            DropdownMenuItem(
                              value: option.id,
                              child: Text(option.name),
                            ),
                        ],
                        onChanged: (value) {
                          final selected = _schoolOptions
                              .where((item) => item.id == value)
                              .firstOrNull;
                          if (selected != null) {
                            setState(() {
                              _schoolId = selected.id;
                              _school.text = selected.name;
                            });
                          }
                        },
                        validator: (value) => value == null
                            ? context.tr(AppCopy.schoolRequired)
                            : null,
                      ),
                    if (_schoolOptionsError != null)
                      TextButton(
                        onPressed: _loadSchoolOptions,
                        child: AppText(_schoolOptionsError!),
                      ),
                    if (widget.completion) ...[
                      const SizedBox(height: 22),
                      DropdownButtonFormField<Gender>(
                        initialValue: _gender,
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: accountAccent(context),
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Icon(switch (_gender) {
                            Gender.male => Icons.male,
                            Gender.female => Icons.female,
                            null => Icons.transgender,
                          }, color: accountAccent(context)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: accountAccent(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: accountAccent(context),
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: Gender.male,
                            child: AppText(AppCopy.maleOption),
                          ),
                          DropdownMenuItem(
                            value: Gender.female,
                            child: AppText(AppCopy.femaleOption),
                          ),
                        ],
                        onChanged: (gender) => setState(() => _gender = gender),
                        validator: (gender) => gender == null
                            ? context.tr(AppCopy.selectGenderRequired)
                            : null,
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (state.actionMessage != null)
                      AppText(
                        state.actionMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              state.actionStatus == AccountActionStatus.failure
                              ? accountError(context)
                              : context.colors.primary,
                        ),
                      ),
                    const SizedBox(height: 18),
                    ProfileModalActions(
                      label: widget.completion
                          ? AppCopy.confirmAction
                          : AppCopy.editAction,
                      busy:
                          state.actionStatus == AccountActionStatus.submitting,
                      confirm: () {
                        if (!_formKey.currentState!.validate()) return;
                        context.read<AccountCubit>().saveProfile(
                          accountUserId(context),
                          AccountProfile(
                            firstName: _first.text,
                            lastName: _last.text,
                            school: _school.text,
                            schoolId: _schoolId,
                            schoolGovernorate: _schoolGovernorate,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
