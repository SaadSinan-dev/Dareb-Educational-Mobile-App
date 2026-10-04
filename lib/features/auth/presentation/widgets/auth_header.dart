import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tamkeen2/core/theme/app_palette.dart';

const authBlue = Color(0xFF5B87EC);
Color authAccent(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light
    ? authBlue
    : context.colors.secondary;

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, this.back = false, this.onBack});
  final bool back;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Container(
    height: 228,
    width: double.infinity,
    decoration: BoxDecoration(
      color: context.colors.primary,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
    ),
    child: Stack(
      children: [
        if (back)
          Positioned.directional(
            top: 12,
            start: 14,
            textDirection: Directionality.of(context),
            child: IconButton(
              tooltip: context.tr(AppCopy.backAction),
              onPressed: onBack ?? () => context.pop(),
              icon: Icon(Icons.arrow_back, color: context.colors.onBrand),
            ),
          ),
        Center(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              context.colors.onBrand,
              BlendMode.srcIn,
            ),
            child: Image.asset(
              'assets/images/logo_white.png',
              width: 136,
              height: 136,
              semanticLabel: context.tr(AppCopy.appLogoLabel),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    ),
  );
}

class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.first, required this.second});
  final String first;
  final String second;
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: AppText.rich(
      TextSpan(
        children: [
          TextSpan(
            text: first,
            style: TextStyle(color: context.colors.primary),
          ),
          TextSpan(
            text: second,
            style: TextStyle(color: authAccent(context)),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
    ),
  );
}

class AuthError extends StatelessWidget {
  const AuthError({super.key, required this.message});
  final String? message;
  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: AppText(
            message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.redAccent
                  : context.colors.error,
              fontSize: 13,
            ),
          ),
        );
}

/// Static branded bootstrap view. Navigation belongs to the resolved session.
