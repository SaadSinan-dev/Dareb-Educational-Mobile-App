import 'dart:async';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:tamkeen2/core/config/app_config.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';

import 'package:tamkeen2/features/auth/presentation/widgets/auth_header.dart';
import 'package:tamkeen2/features/auth/presentation/widgets/otp_digits.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});
  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _digitKey = GlobalKey<OtpDigitsState>();
  Timer? _timer;
  int _seconds = 60;

  @override
  void initState() {
    super.initState();
    if (context.read<AuthCubit>().state.phone != null) _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_seconds > 0) _seconds--;
      });
      if (_seconds == 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (old, next) =>
          old.status != next.status &&
          (next.status == AuthStatus.codeSent ||
              next.status == AuthStatus.registrationPending),
      listener: (context, state) {
        if (state.status == AuthStatus.registrationPending) {
          context.go(AppRoutes.register);
        } else {
          _digitKey.currentState?.clear();
          setState(_startTimer);
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const AuthHeader(back: true),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(25, 27, 25, 26),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? const Color(0xFFDADADA)
                              : context.colors.border,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AuthHeading(
                            first: AppCopy.enterCodeHeadingPrefix,
                            second: AppCopy.verificationCodeHeading,
                          ),
                          const SizedBox(height: 12),
                          AppText(
                            authState.phone == null
                                ? AppCopy.returnToLoginForPhone
                                : AppCopy.format(AppCopy.enterSentCodeMessage, [
                                    authState.phone,
                                  ]),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 15),
                          ),
                          if (AppConfig.demoMode)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: AppText(
                                AppCopy.previewVerificationCodeHint,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.colors.primaryDark,
                                ),
                              ),
                            ),
                          const SizedBox(height: 30),
                          OtpDigits(key: _digitKey),
                          const SizedBox(height: 26),
                          AppText(
                            _seconds > 0
                                ? AppCopy.format(AppCopy.resendCodeCountdown, [
                                    _seconds.toString().padLeft(2, '0'),
                                  ])
                                : AppCopy.resendCodeCountdownExpired,
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed:
                                _seconds > 0 ||
                                    (authState.status ==
                                            AuthStatus.submitting ||
                                        authState.status ==
                                            AuthStatus.loggingOut) ||
                                    authState.phone == null
                                ? null
                                : () => context.read<AuthCubit>().resendCode(),
                            child: const AppText(AppCopy.resendCodeAction),
                          ),
                          AuthError(
                            message: authState.status == AuthStatus.failure
                                ? authState.error
                                : null,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed:
                                authState.phone == null ||
                                    (authState.status ==
                                            AuthStatus.submitting ||
                                        authState.status ==
                                            AuthStatus.loggingOut)
                                ? null
                                : () => context.read<AuthCubit>().verifyCode(
                                    _digitKey.currentState?.code ?? '',
                                  ),
                            child: AppText(
                              authState.status == AuthStatus.submitting
                                  ? AppCopy.verifyingLabel
                                  : AppCopy.confirmAction,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const AppText(
                              AppCopy.changePhoneNumberAction,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
