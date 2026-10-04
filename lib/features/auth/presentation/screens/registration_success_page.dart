import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:tamkeen2/features/auth/presentation/widgets/auth_header.dart';

class RegistrationSuccessPage extends StatelessWidget {
  const RegistrationSuccessPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.background,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Spacer(),
            Image.asset(
              'assets/icons/registration_badge.png',
              width: 128,
              height: 128,
              semanticLabel: context.tr(AppCopy.registrationSuccessfulTitle),
            ),
            const SizedBox(height: 28),
            AppText(
              AppCopy.congratulationsTitle,
              style: TextStyle(
                color: authAccent(context),
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            const AppText(
              AppCopy.registrationSuccessfulMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const AppText(AppCopy.homePageAction),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
