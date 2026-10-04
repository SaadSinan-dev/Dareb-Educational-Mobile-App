import 'package:tamkeen2/features/courses/presentation/widgets/course_cards.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';

import 'package:tamkeen2/features/courses/presentation/widgets/catalog_widgets.dart';
import 'package:tamkeen2/core/widgets/segmented_tabs.dart';
import 'package:tamkeen2/features/courses/presentation/widgets/category_grid.dart';
import 'package:tamkeen2/features/assessments/presentation/widgets/assessment_list.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});
  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CourseCubit>().state;
    return CatalogContent(
      state: state,
      child: PageLayout(
        title: state.category ?? AppCopy.allCategories,
        actions: [notificationAction(context)],
        children: [
          if (state.category == null) ...[
            learningSectionGap,
            CategoryGrid(
              categories: state.courses.map((c) => c.category).toSet().toList(),
              onSelect: context.read<CourseCubit>().selectCategory,
            ),
            learningSectionGap,
            OutlinedButton(
              onPressed: () => context.push(AppRoutes.plans),
              child: AppText(AppCopy.subscriptionsLabel),
            ),
          ] else ...[
            AppSearch(
              value: state.search,
              onChanged: context.read<CourseCubit>().search,
            ),
            SegmentedTabs(
              const [
                AppCopy.contentLabel,
                AppCopy.quizzesTab,
                AppCopy.dailyActivities,
              ],
              tab,
              (value) => setState(() => tab = value),
            ),
            if (tab == 0)
              CourseList(courses: state.visibleCourses)
            else
              AssessmentList(
                courses: state.visibleCourses,
                activities: tab == 2,
              ),
            TextButton(
              onPressed: () {
                context.read<CourseCubit>().selectCategory(null);
                context.read<CourseCubit>().search('');
              },
              child: AppText(AppCopy.viewAllCategories),
            ),
          ],
        ],
      ),
    );
  }
}
