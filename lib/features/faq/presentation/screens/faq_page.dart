import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/account/presentation/account_common.dart';
import 'package:tamkeen2/features/account/presentation/account_preview_mode.dart';
import 'package:tamkeen2/features/content/data/cms_text_mapper.dart';
import 'package:tamkeen2/features/faq/presentation/faq_cubit.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) => accountPreviewMode(context, null)
      ? _previewPage()
      : BlocBuilder<FaqCubit, FaqState>(
          builder: (context, state) => PageLayout(
            title: AppCopy.faqTitle,
            body: ListView(
              children: [
                const SizedBox(height: 22),
                if (state.status == FaqStatus.loading ||
                    state.status == FaqStatus.initial)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
                        SkeletonBlock(height: 28),
                        SizedBox(height: 26),
                        SkeletonBlock(height: 52),
                        SizedBox(height: 12),
                        SkeletonBlock(height: 52),
                        SizedBox(height: 12),
                        SkeletonBlock(height: 52),
                      ],
                    ),
                  ),
                if (state.status == FaqStatus.failure)
                  Center(
                    child: Column(
                      children: [
                        AppText(state.error ?? AppCopy.accountLoadingFailed),
                        TextButton(
                          onPressed: () => context.read<FaqCubit>().load(),
                          child: const AppText(AppCopy.retryAction),
                        ),
                      ],
                    ),
                  ),
                if (state.status == FaqStatus.ready && state.items.isEmpty)
                  const Center(child: AppText(AppCopy.pageContentEmpty)),
                if (state.status == FaqStatus.ready &&
                    state.items.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.help_outline, color: accountAccent(context)),
                        const SizedBox(width: 7),
                        Expanded(
                          child: AppText(
                            AppCopy.faqTitle,
                            style: TextStyle(
                              color: context.colors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < state.items.length; i++)
                    ExpansionTile(
                      key: ValueKey(state.items[i].id),
                      initiallyExpanded: i == 0,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 18),
                      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                      iconColor: accountAccent(context),
                      collapsedIconColor: accountAccent(context),
                      title: Text(
                        accountHtmlToText(state.items[i].question),
                        style: const TextStyle(fontSize: 14),
                      ),
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            accountHtmlToText(state.items[i].answer),
                            style: TextStyle(
                              color: accountAccent(context),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        );

  Widget _previewPage() => PageLayout(
    title: AppCopy.faqTitle,
    body: ListView(
      children: [
        const SizedBox(height: 22),
        const _FaqGroup(
          icon: Icons.psychology_outlined,
          title: AppCopy.faqCourseContentHeading,
          questions: [
            (
              AppCopy.faqAvailableSubjectsQuestion,
              AppCopy.faqAvailableSubjectsAnswer,
            ),
            (AppCopy.faqFreeVideosQuestion, null),
            (AppCopy.faqDownloadMaterialsQuestion, null),
          ],
        ),
        const _FaqGroup(
          icon: Icons.co_present_outlined,
          title: AppCopy.faqTeachersHeading,
          questions: [
            (AppCopy.faqChooseTeacherQuestion, null),
            (AppCopy.faqMobileTestsQuestion, null),
            (AppCopy.faqAskTeacherQuestion, null),
          ],
        ),
        const _FaqGroup(
          icon: Icons.build_outlined,
          title: AppCopy.faqTechnicalSupportHeading,
          questions: [
            (AppCopy.faqSupportedDevicesQuestion, null),
            (AppCopy.faqForgotPasswordQuestion, null),
            (AppCopy.faqContactSupportQuestion, null),
          ],
        ),
      ],
    ),
  );
}

class _FaqGroup extends StatelessWidget {
  const _FaqGroup({
    required this.icon,
    required this.title,
    required this.questions,
  });
  final IconData icon;
  final String title;
  final List<(String, String?)> questions;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(
          children: [
            Icon(icon, color: accountAccent(context)),
            const SizedBox(width: 7),
            Expanded(
              child: AppText(
                title,
                style: TextStyle(
                  color: context.colors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      for (var i = 0; i < questions.length; i++)
        ExpansionTile(
          initiallyExpanded: title == AppCopy.faqCourseContentHeading && i == 0,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          iconColor: accountAccent(context),
          collapsedIconColor: accountAccent(context),
          title: AppText(questions[i].$1, style: const TextStyle(fontSize: 14)),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AppText(
                questions[i].$2 ?? AppCopy.faqAnswerMissing,
                style: TextStyle(color: accountAccent(context), fontSize: 12),
              ),
            ),
          ],
        ),
      Divider(thickness: 3, color: context.colors.border),
    ],
  );
}
