import 'package:tamkeen2/core/widgets/source_icon.dart';
import 'package:tamkeen2/core/theme/design_tokens.dart';

import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tamkeen2/core/theme/app_palette.dart';

class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
    child: AppText(
      title,
      style: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).brightness == Brightness.dark
            ? context.colors.ink
            : const Color(0xFF555555),
      ),
    ),
  );
}

class ProfileMenuItem extends StatelessWidget {
  const ProfileMenuItem(this.title, this.icon, this.route, {super.key});
  final String title;
  final SourceIconName icon;
  final String route;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    minVerticalPadding: 6,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18),
    leading: SourceIcon(
      icon,
      color: Theme.of(context).brightness == Brightness.dark
          ? context.colors.secondary
          : AppIconTokens.actionBlue,
      size: AppIconTokens.profileCanvas,
    ),
    title: AppText(
      title,
      style: TextStyle(
        fontSize: 16,
        color: Theme.of(context).brightness == Brightness.dark
            ? context.colors.ink
            : const Color(0xFF555555),
      ),
    ),
    trailing: SourceIcon(
      SourceIconName.profileArrow,
      quarterTurns: Directionality.of(context) == TextDirection.rtl ? 0 : 2,
      color: Theme.of(context).brightness == Brightness.dark
          ? context.colors.muted
          : const Color(0xFF666666),
      size: 20,
    ),
    onTap: () => context.push(route),
  );
}
