import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/features/account/presentation/account_common.dart';

class PreferenceMenuItem extends StatelessWidget {
  const PreferenceMenuItem({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    minVerticalPadding: 6,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18),
    leading: Icon(icon, color: accountAccent(context), size: 24),
    title: AppText(
      title,
      style: TextStyle(fontSize: 16, color: context.colors.ink),
    ),
    subtitle: AppText(
      value,
      style: TextStyle(fontSize: 12, color: context.colors.muted),
    ),
    trailing: Icon(Icons.chevron_left, color: context.colors.muted, size: 20),
    onTap: onTap,
  );
}

class PreferenceChoice {
  const PreferenceChoice({
    required this.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String key;
  final String label;
  final bool selected;
  final VoidCallback onTap;
}

class PreferenceChoiceSheet extends StatelessWidget {
  const PreferenceChoiceSheet({
    super.key,
    required this.title,
    required this.choices,
  });

  final String title;
  final List<PreferenceChoice> choices;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: AppText(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: context.colors.ink,
            ),
          ),
        ),
        for (final choice in choices)
          ListTile(
            key: ValueKey(choice.key),
            title: AppText(choice.label),
            trailing: choice.selected
                ? Icon(Icons.check, color: context.colors.primary)
                : null,
            onTap: choice.onTap,
          ),
      ],
    ),
  );
}
