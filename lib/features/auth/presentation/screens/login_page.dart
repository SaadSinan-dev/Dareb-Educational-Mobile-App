import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';

import 'package:tamkeen2/features/auth/presentation/widgets/auth_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  bool _loginRequestPending = false;

  void _requestLoginCode() {
    _loginRequestPending = true;
    context.read<AuthCubit>().requestCode(_phone.text);
  }

  void _requestRegistrationCode() {
    _loginRequestPending = true;
    context.read<AuthCubit>().requestCode(_phone.text, forRegistration: true);
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthCubit, AuthState>(
    listenWhen: (old, next) =>
        old.status != next.status &&
        (next.status == AuthStatus.codeSent ||
            next.status == AuthStatus.failure),
    listener: (context, state) {
      if (state.status == AuthStatus.failure) {
        _loginRequestPending = false;
      } else {
        final shouldNavigate =
            _loginRequestPending && ModalRoute.of(context)?.isCurrent == true;
        _loginRequestPending = false;
        if (shouldNavigate) context.push(AppRoutes.otp);
      }
    },
    child: Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              const AuthHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 28, 12, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(30, 26, 30, 25),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFFDADADA)
                            : context.colors.border,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AuthHeading(
                          first: AppCopy.signInHeadingPrefix,
                          second: AppCopy.yourAccountHeading,
                        ),
                        const SizedBox(height: 12),
                        AppText(
                          AppCopy.welcomeBackMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? const Color(0xFF555555)
                                : context.colors.muted,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          decoration: InputDecoration(
                            hintText: context.tr(AppCopy.enterPhoneNumberHint),
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              color: authAccent(context),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) => Column(
                            children: [
                              AuthError(
                                message: state.status == AuthStatus.failure
                                    ? state.error
                                    : null,
                              ),
                              const SizedBox(height: 23),
                              FilledButton(
                                onPressed:
                                    state.status == AuthStatus.submitting ||
                                        state.status == AuthStatus.restoring ||
                                        state.status == AuthStatus.loggingOut
                                    ? null
                                    : _requestLoginCode,
                                child: AppText(
                                  state.status == AuthStatus.submitting
                                      ? AppCopy.sendingLabel
                                      : AppCopy.signInAction,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _requestRegistrationCode,
                          child: const AppText(AppCopy.createNewAccountAction),
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
