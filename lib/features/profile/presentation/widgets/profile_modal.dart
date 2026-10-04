import 'package:tamkeen2/core/widgets/source_icon.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/theme/app_theme.dart';
import 'package:tamkeen2/features/account/presentation/account_common.dart';

Color accountError(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? context.colors.error
    : Colors.red;

class ProfileModal extends StatelessWidget {
  const ProfileModal({
    super.key,
    required this.title,
    required this.icon,
    this.leadingIcon,
    required this.child,
    this.center = false,
    this.overlay = true,
  });
  final String title;
  final IconData icon;
  final Widget? leadingIcon;
  final Widget child;
  final bool center;
  final bool overlay;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: overlay
        ? Colors.transparent
        : Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF4D4D4D)
        : context.colors.shadow,
    resizeToAvoidBottomInset: true,
    body: SafeArea(
      bottom: false,
      child: Align(
        alignment: center ? Alignment.center : Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, 16, 16, center ? 26 : 24),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: center
                  ? BorderRadius.circular(22)
                  : const BorderRadius.vertical(top: Radius.circular(38)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      leadingIcon ?? Icon(icon, color: accountAccent(context)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: AppText(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => accountBack(context),
                        icon: SourceIcon(
                          SourceIconName.cancel,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? context.colors.muted
                              : const Color(0xFF777777),
                          size: 31,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class ProfileModalActions extends StatelessWidget {
  const ProfileModalActions({
    super.key,
    required this.confirm,
    required this.label,
    this.busy = false,
  });
  final VoidCallback? confirm;
  final String label;
  final bool busy;

  @override
  Widget build(BuildContext context) => Row(
    textDirection: TextDirection.ltr,
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: () => accountBack(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: accountAccent(context),
            side: BorderSide(color: accountAccent(context)),
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
          ),
          child: const AppText(AppCopy.exitAction),
        ),
      ),
      const SizedBox(width: 20),
      Expanded(
        child: FilledButton(
          onPressed: busy ? null : confirm,
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
              : AppText(label),
        ),
      ),
    ],
  );
}
