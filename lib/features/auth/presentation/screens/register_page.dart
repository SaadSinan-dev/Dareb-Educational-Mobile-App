import 'package:tamkeen2/features/auth/presentation/widgets/registration_step_content.dart';
import 'package:tamkeen2/features/auth/presentation/registration_options_cubit.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:tamkeen2/features/content/presentation/screens/policy_page.dart';
import 'package:tamkeen2/features/auth/domain/registration_draft.dart';
import 'package:tamkeen2/features/auth/domain/registration_options.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/auth/presentation/widgets/auth_header.dart';
import 'package:tamkeen2/features/auth/presentation/registration_flow_cubit.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with WidgetsBindingObserver {
  final _flow = RegistrationFlowCubit();
  final _registrationErrorKey = GlobalKey();
  bool _registrationAttempted = false;
  StreamSubscription<RegistrationFlowState>? _flowSubscription;
  RegistrationDraft get _draft => _flow.state.draft;
  set _draft(RegistrationDraft value) => _flow.update(value);
  int get _step => _flow.state.step;
  String? get _error => _flow.state.error;
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  late final RegistrationOptionsCubit _options;
  StreamSubscription<RegistrationOptionsState>? _optionsSubscription;
  List<GovernorateOption> get _governorates => _options.state.governorates;
  List<RegistrationOption> get _schools => _options.state.schools;
  bool get _loadingOptions => _options.state.loading;
  String? get _optionsError => _options.state.error;
  bool get _loadingSchools => _options.state.loadingSchools;
  bool get _schoolLookupAttempted => _options.state.schoolLookupAttempted;
  String? get _schoolsError => _options.state.schoolsError;

  @override
  void initState() {
    super.initState();
    _options = context.read<RegistrationOptionsCubit>();
    _optionsSubscription = _options.stream.listen((state) {
      if (_draft.schoolId != null &&
          (state.loadingSchools ||
              (state.schoolLookupAttempted &&
                  !state.loadingSchools &&
                  !state.schools.any((s) => s.id == _draft.schoolId)))) {
        _draft = _draft.copyWith(clearSchoolId: true, school: '');
      }
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addObserver(this);
    _flowSubscription = _flow.stream.listen((_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthCubit>();
      _phone.text = auth.state.phone ?? '';
      _flow.update(_draft.copyWith(phone: _phone.text));
      _loadOptions();
    });
  }

  Future<void> _loadOptions() => _options.load();
  Future<void> _loadSchools() => _options.loadSchools();

  void _selectInstitutionType(InstitutionType type) {
    if (_draft.institutionType == type) return;
    _draft = _draft.copyWith(
      institutionType: type,
      clearSchoolId: true,
      school: '',
    );
    unawaited(_options.select(type: type == InstitutionType.school ? 1 : 2));
  }

  @override
  void didChangeMetrics() => _revealRegistrationError();

  void _revealRegistrationError() {
    if (!_registrationAttempted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          context.read<AuthCubit>().state.status != AuthStatus.failure) {
        return;
      }
      final errorContext = _registrationErrorKey.currentContext;
      if (errorContext != null) {
        Scrollable.ensureVisible(
          errorContext,
          duration: const Duration(milliseconds: 250),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _optionsSubscription?.cancel();
    _flowSubscription?.cancel();
    _flow.close();
    for (final controller in [_firstName, _lastName, _email, _phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _exitRegistration() async {
    final auth = context.read<AuthCubit>();
    if (auth.state.status == AuthStatus.registrationPending) {
      await auth.logout();
      if (mounted) context.go(AppRoutes.login);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  void _back() {
    _registrationAttempted = false;
    if (_step == 0) {
      unawaited(_exitRegistration());
      return;
    }
    _flow.back();
  }

  void _next() {
    final draft = _draft.copyWith(
      firstName: _firstName.text,
      lastName: _lastName.text,
      email: _email.text,
      phone: context.read<AuthCubit>().state.phone ?? _phone.text,
    );
    final submitting = _step == 6;
    _flow.update(draft);
    if (!_flow.advance()) return;
    if (submitting) {
      setState(() => _registrationAttempted = true);
      context.read<AuthCubit>().register(draft);
    }
  }

  void _showTerms() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: context.colors.surface,
    builder: (sheet) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(sheet).height * .68,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.policy_outlined, color: context.colors.primary),
                  const Expanded(
                    child: AppText(
                      AppCopy.termsAndConditionsTitle,
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr(AppCopy.closeAction),
                    onPressed: () => Navigator.pop(sheet),
                    icon: const Icon(Icons.cancel_outlined),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final section in PolicyPage.termsSections) ...[
                        AppText(
                          section.$1,
                          style: TextStyle(
                            color: context.colors.primary,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppText(
                          section.$2,
                          style: const TextStyle(fontSize: 13, height: 1.6),
                        ),
                        const Divider(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => BlocListener<AuthCubit, AuthState>(
    listenWhen: (old, next) =>
        old.status != next.status &&
        (next.status == AuthStatus.registrationSucceeded ||
            next.status == AuthStatus.failure),
    listener: (context, state) {
      if (state.status == AuthStatus.registrationSucceeded) {
        context.go(AppRoutes.registrationSuccess);
      } else if (_registrationAttempted) {
        _revealRegistrationError();
      }
    },
    child: Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    AuthHeader(
                      back: _step == 0,
                      onBack: () => unawaited(_exitRegistration()),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LinearProgressIndicator(
                              value: (_step + 1) / 7,
                              minHeight: 7,
                              color: authAccent(context),
                              backgroundColor:
                                  Theme.of(context).brightness ==
                                      Brightness.light
                                  ? const Color(0xFFEFF2F5)
                                  : context.colors.border,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Expanded(
                                  child: AppText(
                                    AppCopy.personalInformationTitle,
                                    textAlign: TextAlign.start,
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                                Expanded(
                                  child: AppText(
                                    AppCopy.institutionTypeTitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                                Expanded(
                                  child: AppText(
                                    AppCopy.accountDetailsTitle,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),
                            AuthHeading(
                              first: _step == 2
                                  ? AppCopy.referralHeadingPrefix
                                  : AppCopy.completeDetailsHeadingPrefix,
                              second: _step == 2
                                  ? AppCopy.referralHeadingSuffix
                                  : AppCopy.yourInformationHeading,
                            ),
                            const SizedBox(height: 12),
                            if (_step != 2)
                              AppText(
                                AppCopy.registrationDetailsPrompt,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.light
                                      ? const Color(0xFF666666)
                                      : context.colors.muted,
                                ),
                              ),
                            const SizedBox(height: 28),
                            RegistrationStepContent(
                              step: _step,
                              draft: _draft,
                              options: _options.state,
                              onChanged: _flow.update,
                              onInstitution: _selectInstitutionType,
                              onGovernorate: (value) {
                                _draft = _draft.copyWith(
                                  clearSchoolId: true,
                                  school: '',
                                );
                                unawaited(_options.select(governorate: value));
                              },
                              showTerms: _showTerms,
                              firstName: _firstName,
                              lastName: _lastName,
                              email: _email,
                              phone: _phone,
                            ),
                            if (_loadingOptions)
                              const LinearProgressIndicator(),
                            if (_loadingSchools)
                              const LinearProgressIndicator(),
                            if (_optionsError != null) ...[
                              AuthError(message: _optionsError),
                              TextButton(
                                onPressed: _loadOptions,
                                child: const AppText(AppCopy.retryAction),
                              ),
                            ],
                            if (_step == 5 &&
                                !_loadingOptions &&
                                _optionsError == null &&
                                _governorates.isEmpty) ...[
                              const AppText(
                                AppCopy.noGovernoratesAvailable,
                                textAlign: TextAlign.center,
                              ),
                              TextButton(
                                onPressed: _loadOptions,
                                child: const AppText(AppCopy.retryAction),
                              ),
                            ],
                            if (_step == 5 && _schoolsError != null) ...[
                              AuthError(message: _schoolsError),
                              TextButton(
                                onPressed: _loadSchools,
                                child: const AppText(AppCopy.retryAction),
                              ),
                            ],
                            if (_step == 5 &&
                                _schoolLookupAttempted &&
                                !_loadingSchools &&
                                _schoolsError == null &&
                                _schools.isEmpty) ...[
                              const AppText(
                                AppCopy.noSchoolsForSelection,
                                textAlign: TextAlign.center,
                              ),
                              TextButton(
                                onPressed: _loadSchools,
                                child: const AppText(AppCopy.retryAction),
                              ),
                            ],
                            if (_error != null) AuthError(message: _error),
                            BlocBuilder<AuthCubit, AuthState>(
                              builder: (_, state) => AuthError(
                                key: _registrationErrorKey,
                                message:
                                    _registrationAttempted &&
                                        state.status == AuthStatus.failure
                                    ? state.error
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    if (_step > 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _back,
                          child: const AppText(AppCopy.goBackAction),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) => FilledButton(
                          onPressed:
                              _loadingOptions ||
                                  _loadingSchools ||
                                  state.status == AuthStatus.submitting ||
                                  state.status == AuthStatus.loggingOut
                              ? null
                              : _next,
                          child: AppText(
                            state.status == AuthStatus.submitting
                                ? AppCopy.registeringLabel
                                : _step == 6
                                ? AppCopy.createAccountAction
                                : _step == 4
                                ? AppCopy.confirmAction
                                : AppCopy.nextAction,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
