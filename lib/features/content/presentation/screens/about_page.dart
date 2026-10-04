import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:tamkeen2/core/widgets/source_icon.dart';

import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/features/account/domain/account_content.dart';
import 'package:tamkeen2/features/account/domain/account_content_repository.dart';
import 'package:tamkeen2/features/account/presentation/account_common.dart';
import 'package:tamkeen2/features/account/presentation/account_preview_mode.dart';
import 'package:tamkeen2/features/content/presentation/widgets/remote_account_page_content.dart';

import 'package:tamkeen2/features/profile/presentation/widgets/profile_modal.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key, this.repository, this.previewMode});

  final AccountContentRepository? repository;
  final bool? previewMode;

  @override
  Widget build(BuildContext context) => ProfileModal(
    title: AppCopy.aboutAppTitle,
    icon: Icons.info_outline,
    leadingIcon: SourceIcon(
      SourceIconName.about,
      color: accountAccent(context),
    ),
    child: Column(
      children: [
        SizedBox(
          width: 175,
          height: 104,
          child: Image.asset(
            'assets/images/about_education_logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        if (accountPreviewMode(context, previewMode))
          AppText(
            AppCopy.aboutAppDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.primary, fontSize: 13),
          )
        else
          RemoteAccountPageContent(
            kind: AccountPageKind.aboutApplication,
            repository: repository,
            centered: true,
          ),
        if (accountPreviewMode(context, previewMode))
          const SizedBox(height: 24),
        if (accountPreviewMode(context, previewMode))
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final network in [
                'whatsapp',
                'telegram',
                'instagram',
                'facebook',
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Image.asset(
                    'assets/images/about_$network.png',
                    width: 46,
                    height: 46,
                  ),
                ),
            ],
          ),
      ],
    ),
  );
}
