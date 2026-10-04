import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/core/widgets/source_icon.dart';
import 'dart:async';

import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/preferences/app_preferences_cubit.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';

import 'package:tamkeen2/features/profile/presentation/widgets/profile_summary_area.dart';
import 'package:tamkeen2/features/profile/presentation/widgets/profile_menu.dart';
import 'package:tamkeen2/features/settings/presentation/widgets/preference_menu_item.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<AppPreferencesCubit>().state;
    final language = preferences.languageCode == 'en'
        ? AppCopy.languageEnglishOption
        : AppCopy.languageArabicOption;
    final theme = switch (preferences.themeMode) {
      ThemeMode.system => AppCopy.themeSystemOption,
      ThemeMode.light => AppCopy.themeLightOption,
      ThemeMode.dark => AppCopy.themeDarkOption,
    };
    return PageLayout(
      title: AppCopy.profileTitle,
      back: false,
      body: BlocListener<AppPreferencesCubit, AppPreferencesState>(
        listenWhen: (previous, current) =>
            !previous.saveFailed && current.saveFailed,
        listener: (context, state) =>
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: AppText(AppCopy.preferencesSaveFailed)),
            ),
        child: ListView(
          children: [
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: ProfileSummaryArea(),
            ),
            const SizedBox(height: 20),
            Divider(thickness: 3, color: context.colors.border),
            const ProfileSectionTitle(AppCopy.supportAndInformationHeading),
            const ProfileMenuItem(
              AppCopy.faqTitle,
              SourceIconName.faq,
              AppRoutes.faq,
            ),
            const ProfileMenuItem(
              AppCopy.contactUsTitle,
              SourceIconName.contact,
              AppRoutes.contact,
            ),
            const ProfileMenuItem(
              AppCopy.subscriptionTitle,
              SourceIconName.subscription,
              AppRoutes.plans,
            ),
            const ProfileMenuItem(
              AppCopy.myAchievementsTitle,
              SourceIconName.achievement,
              AppRoutes.achievements,
            ),
            const ProfileMenuItem(
              AppCopy.aboutAppTitle,
              SourceIconName.about,
              AppRoutes.about,
            ),
            const ProfileMenuItem(
              AppCopy.privacyPolicyTitle,
              SourceIconName.privacy,
              AppRoutes.privacy,
            ),
            const ProfileMenuItem(
              AppCopy.downloadedCoursesTitle,
              SourceIconName.downloads,
              AppRoutes.downloads,
            ),
            const ProfileMenuItem(
              AppCopy.usagePolicyTitle,
              SourceIconName.terms,
              AppRoutes.terms,
            ),
            const ProfileMenuItem(
              AppCopy.myTestsTitle,
              SourceIconName.tests,
              AppRoutes.assessments,
            ),
            Divider(thickness: 3, color: context.colors.border),
            const ProfileSectionTitle(AppCopy.settingsTitle),
            PreferenceMenuItem(
              key: const ValueKey('language-setting'),
              title: AppCopy.languageSettingTitle,
              value: language,
              icon: Icons.language_outlined,
              onTap: () => _showLanguageSheet(context),
            ),
            PreferenceMenuItem(
              key: const ValueKey('theme-setting'),
              title: AppCopy.themeSettingTitle,
              value: theme,
              icon: Icons.brightness_6_outlined,
              onTap: () => _showThemeSheet(context),
            ),
            const ProfileMenuItem(
              AppCopy.editProfileAction,
              SourceIconName.profileEdit,
              AppRoutes.editProfile,
            ),
            const ProfileMenuItem(
              AppCopy.signOutAction,
              SourceIconName.logout,
              AppRoutes.logout,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final cubit = context.read<AppPreferencesCubit>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surface,
      builder: (sheetContext) => PreferenceChoiceSheet(
        title: AppCopy.languageSettingTitle,
        choices: [
          PreferenceChoice(
            key: 'language-option-ar',
            label: AppCopy.languageArabicOption,
            selected: cubit.state.languageCode == 'ar',
            onTap: () {
              unawaited(cubit.setLanguage('ar'));
              Navigator.of(sheetContext).pop();
            },
          ),
          PreferenceChoice(
            key: 'language-option-en',
            label: AppCopy.languageEnglishOption,
            selected: cubit.state.languageCode == 'en',
            onTap: () {
              unawaited(cubit.setLanguage('en'));
              Navigator.of(sheetContext).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showThemeSheet(BuildContext context) {
    final cubit = context.read<AppPreferencesCubit>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surface,
      builder: (sheetContext) => PreferenceChoiceSheet(
        title: AppCopy.themeSettingTitle,
        choices: [
          for (final option in [
            (
              ThemeMode.system,
              AppCopy.themeSystemOption,
              'theme-option-system',
            ),
            (ThemeMode.light, AppCopy.themeLightOption, 'theme-option-light'),
            (ThemeMode.dark, AppCopy.themeDarkOption, 'theme-option-dark'),
          ])
            PreferenceChoice(
              key: option.$3,
              label: option.$2,
              selected: cubit.state.themeMode == option.$1,
              onTap: () {
                unawaited(cubit.setThemeMode(option.$1));
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      ),
    );
  }
}
