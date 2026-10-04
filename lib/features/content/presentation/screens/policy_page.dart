import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/account/domain/account_content.dart';
import 'package:tamkeen2/features/account/domain/account_content_repository.dart';
import 'package:tamkeen2/features/account/presentation/account_common.dart';
import 'package:tamkeen2/features/account/presentation/account_preview_mode.dart';
import 'package:tamkeen2/features/content/presentation/widgets/remote_account_page_content.dart';

class PolicyPage extends StatelessWidget {
  const PolicyPage({
    super.key,
    required this.privacy,
    this.repository,
    this.previewMode,
  });
  final bool privacy;
  final AccountContentRepository? repository;
  final bool? previewMode;

  static const termsSections = <(String, String)>[
    (AppCopy.termsAcceptanceHeading, AppCopy.termsAcceptanceBody),
    (AppCopy.termsAccountUsageHeading, AppCopy.termsAccountUsageBody),
    (AppCopy.termsAcceptableUseHeading, AppCopy.termsAcceptableUseBody),
    (
      AppCopy.termsIntellectualPropertyHeading,
      AppCopy.termsIntellectualPropertyBody,
    ),
    (AppCopy.termsServiceSuspensionHeading, AppCopy.privacyDataCollectionBody),
  ];

  @override
  Widget build(BuildContext context) {
    if (privacy) {
      return PageLayout(
        title: AppCopy.privacyPolicyTitle,
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
        children: [
          RemoteAccountPageContent(
            kind: AccountPageKind.privacyPolicy,
            repository: repository,
          ),
        ],
      );
    }
    // Privacy always displays the CMS value, including in design preview builds.
    final preview = !privacy && accountPreviewMode(context, previewMode);
    const sections = termsSections;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            AccountTopBar(
              title: privacy
                  ? AppCopy.privacyPolicyTitle
                  : AppCopy.usagePolicyTitle,
            ),
            if (preview)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: AppText(
                  AppCopy.referenceLegalTextNotice,
                  style: TextStyle(fontSize: 11, color: context.colors.muted),
                ),
              ),
            if (preview)
              for (final section in sections)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      AppText(
                        section.$1,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: accountAccent(context),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      AppText(
                        section.$2,
                        textAlign: TextAlign.start,
                        style: const TextStyle(fontSize: 14, height: 1.55),
                      ),
                      const SizedBox(height: 11),
                      Divider(color: context.colors.border, thickness: 1.5),
                    ],
                  ),
                ),
            if (!preview)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
                child: RemoteAccountPageContent(
                  kind: privacy
                      ? AccountPageKind.privacyPolicy
                      : AccountPageKind.termsConditions,
                  repository: repository,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
