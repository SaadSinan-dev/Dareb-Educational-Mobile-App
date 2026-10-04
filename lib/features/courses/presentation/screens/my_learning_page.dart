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
import 'package:tamkeen2/core/widgets/segmented_tabs.dart';
import 'package:tamkeen2/features/courses/presentation/widgets/course_progress.dart';

class MyLearningPage extends StatefulWidget {
  const MyLearningPage({super.key});
  @override
  State<MyLearningPage> createState() => _MyLearningPageState();
}

class _MyLearningPageState extends State<MyLearningPage> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CourseCubit>();
    final state = cubit.state;
    final courses = state.visibleCourses
        .where((c) => cubit.hasAccess(c.id))
        .toList();
    return CatalogContent(
      state: state,
      title: AppCopy.mySubjectsTab,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          16,
          22,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          AppSearch(value: state.search, onChanged: cubit.search),
          SegmentedTabs(
            const [
              AppCopy.subjectsLabel,
              AppCopy.chaptersLabel,
              AppCopy.plansLabel,
            ],
            tab,
            (value) => setState(() => tab = value),
          ),
          if (tab == 2) ...[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    AppCopy.availableSubjects,
                    style: TextStyle(
                      fontSize: 20,
                      color: context.colors.primary,
                    ),
                  ),
                  AppText(AppCopy.availableSubjectsDescription),
                  ExpansionTile(
                    title: AppText(AppCopy.viewSubjects),
                    children: [
                      for (final c in courses)
                        ListTile(
                          title: AppText(c.title),
                          onTap: () => context.push(AppRoutes.detail(c.id)),
                        ),
                    ],
                  ),
                  FilledButton(
                    onPressed: () => context.push(AppRoutes.plans),
                    child: AppText(AppCopy.browseSubscriptions),
                  ),
                ],
              ),
            ),
          ] else if (courses.isEmpty) ...[
            AppText(AppCopy.noMatchingAvailableSubjects),
            TextButton(
              onPressed: () => context.push(AppRoutes.categories),
              child: AppText(AppCopy.exploreSubjects),
            ),
          ] else
            for (final course in courses) ...[
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tab == 0)
                      Row(
                        children: [
                          courseArtwork(course, width: 110, height: 110),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  course.title,
                                  style: TextStyle(
                                    color: context.colors.primary,
                                    fontSize: 18,
                                  ),
                                ),
                                AppText(course.teacher),
                                AppText(
                                  AppCopy.format(AppCopy.lessonCountLabel, [
                                    course.lessons.length,
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      AppText(
                        cubit.demoMode
                            ? AppCopy.chapterOne
                            : AppCopy.learningPath,
                        style: TextStyle(
                          color: context.colors.primary,
                          fontSize: 19,
                        ),
                      ),
                      AppText(course.title),
                      AppText(course.teacher),
                      const Divider(),
                    ],
                    learningSectionGap,
                    CourseProgress(course: course),
                    learningSectionGap,
                    OutlinedButton(
                      onPressed: () =>
                          context.push(AppRoutes.detail(course.id)),
                      child: AppText(AppCopy.continueLearning),
                    ),
                  ],
                ),
              ),
              learningSectionGap,
            ],
        ],
      ),
    );
  }
}
