import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/account/presentation/account_common.dart';

import 'package:tamkeen2/features/profile/presentation/widgets/profile_modal.dart';

class LogoutPage extends StatefulWidget {
  const LogoutPage({super.key});
  @override
  State<LogoutPage> createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage> {
  bool busy = false;
  String? error;

  Future<void> _logout() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    await context.read<AuthCubit>().logout();
    if (!mounted) return;
    final auth = context.read<AuthCubit>().state;
    if (auth.status == AuthStatus.failure) {
      setState(() {
        busy = false;
        error = auth.error;
      });
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) => ProfileModal(
    title: AppCopy.confirmSignOutTitle,
    icon: Icons.logout_outlined,
    center: true,
    child: Column(
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppText(
              error!,
              style: TextStyle(color: accountError(context)),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => accountBack(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accountAccent(context),
                  side: BorderSide(color: accountAccent(context)),
                  minimumSize: const Size(0, 48),
                ),
                child: const AppText(AppCopy.goBackAction),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: FilledButton(
                onPressed: busy ? null : _logout,
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  minimumSize: const Size(0, 48),
                ),
                child: busy
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.onBrand,
                        ),
                      )
                    : const AppText(AppCopy.confirmAction),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
