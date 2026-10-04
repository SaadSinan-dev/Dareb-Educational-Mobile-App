import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';

import 'package:tamkeen2/features/courses/presentation/widgets/catalog_widgets.dart';
import 'package:tamkeen2/features/courses/presentation/widgets/course_artwork.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});
  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  // Repeated design tiles are illustrative preview content, not plan coverage.
  static final _previewSubjects = List<String>.generate(
    18,
    (index) => switch (index % 4) {
      0 || 3 => AppCopy.mathematicsSubject,
      _ => AppCopy.socialStudiesSubject,
    },
    growable: false,
  );
  int selected = 0;
  final code = TextEditingController();
  final detailsScroll = ScrollController();
  String? error;
  @override
  void dispose() {
    code.dispose();
    detailsScroll.dispose();
    super.dispose();
  }

  void _details() => showDialog<void>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            IconButton(
              tooltip: dialog.tr(AppCopy.closeAction),
              onPressed: () => Navigator.pop(dialog),
              icon: Icon(
                Icons.cancel_outlined,
                color: dialog.colors.muted,
                size: 32,
              ),
            ),
            const Expanded(
              child: AppText(
                AppCopy.availableSubjects,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
      content: context.read<CourseCubit>().demoMode
          ? SizedBox(
              width: 300,
              height: 350,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 19),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: ScrollbarTheme(
                    data: ScrollbarThemeData(
                      thumbColor: WidgetStatePropertyAll(
                        dialog.colors.secondary,
                      ),
                      trackColor: WidgetStatePropertyAll(
                        dialog.colors.skeleton,
                      ),
                    ),
                    child: Scrollbar(
                      controller: detailsScroll,
                      thumbVisibility: true,
                      trackVisibility: true,
                      thickness: 8,
                      radius: const Radius.circular(8),
                      child: GridView.builder(
                        key: const Key('preview-plan-subject-grid'),
                        controller: detailsScroll,
                        padding: const EdgeInsets.only(right: 20),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 30,
                          crossAxisSpacing: 14,
                          mainAxisExtent: MediaQuery.sizeOf(dialog).width >= 390
                              ? 86
                              : 96,
                        ),
                        itemCount: _previewSubjects.length,
                        itemBuilder: (dialog, index) {
                          final subject = _previewSubjects[index];
                          return Container(
                            key: Key('preview-plan-subject-$index'),
                            decoration: BoxDecoration(
                              color: dialog.colors.softBlue,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                AppText(
                                  subject,
                                  style: TextStyle(
                                    color: dialog.colors.ink,
                                    fontSize: 12,
                                  ),
                                ),
                                courseAsset(
                                  'icons/${subjectAssetName(subject)}',
                                  height: 48,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            )
          : SizedBox(
              width: 320,
              child: AppText(AppCopy.serviceCurrentlyUnavailable),
            ),
    ),
  );
  @override
  Widget build(BuildContext context) => PageLayout(
    title: AppCopy.subscriptionsLabel,
    actions: [notificationAction(context)],
    children: [
      learningSectionGap,
      for (var i = 0; i < 2; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: InkWell(
            onTap: () => setState(() {
              selected = i;
              error = null;
            }),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: selected == i
                    ? context.colors.secondary
                    : context.colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          i == 0 ? AppCopy.oneYear : AppCopy.freeLabel,
                          style: TextStyle(
                            fontSize: 22,
                            color: selected == i
                                ? context.colors.onBrand
                                : context.colors.primary,
                          ),
                        ),
                        AppText(
                          i == 0
                              ? AppCopy.allFeaturesPlanDescription
                              : AppCopy.trialPlanDescription,
                          style: TextStyle(
                            color: selected == i
                                ? context.colors.onBrand
                                : context.colors.muted,
                          ),
                        ),
                        AppText(
                          i == 0
                              ? AppCopy.annualPlanPrice
                              : AppCopy.freeTrialPrice,
                          style: TextStyle(
                            fontSize: 18,
                            color: selected == i
                                ? context.colors.onBrand
                                : context.colors.secondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => selected = i);
                            _details();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: selected == i
                                ? context.colors.onBrand
                                : context.colors.primary,
                          ),
                          child: AppText(AppCopy.detailsLabel),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected == i
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected == i
                        ? context.colors.onBrand
                        : context.colors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      TextField(
        controller: code,
        decoration: InputDecoration(
          hintText: context.tr(AppCopy.subjectCodeHint),
          errorText: error == null ? null : context.tr(error!),
        ),
      ),
      learningSectionGap,
      OutlinedButton(
        onPressed: () => setState(
          () => error = code.text.trim().isEmpty
              ? AppCopy.enterCodeFirst
              : AppCopy.codeVerificationUnavailable,
        ),
        child: AppText(AppCopy.applyCode),
      ),
      learningSectionGap,
      FilledButton(
        onPressed: () => context.push(
          AppRoutes.checkout(selected == 0 ? 'plan-year' : 'plan-free'),
        ),
        child: AppText(AppCopy.subscribeNow),
      ),
    ],
  );
}
