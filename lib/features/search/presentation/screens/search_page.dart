import 'package:tamkeen2/features/search/presentation/search_cubit.dart';
import 'package:tamkeen2/features/courses/presentation/widgets/course_cards.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/domain/subject.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';
import 'package:tamkeen2/features/assessments/presentation/widgets/remote_assessment_cards.dart';

import 'package:tamkeen2/features/courses/presentation/widgets/catalog_widgets.dart';
import 'package:tamkeen2/features/courses/presentation/widgets/category_grid.dart';
import 'package:tamkeen2/features/assessments/presentation/widgets/assessment_list.dart';

class _SearchResultsSkeleton extends StatelessWidget {
  const _SearchResultsSkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr(AppCopy.loadingCoursesLabel),
    child: Column(
      children: [
        for (var i = 0; i < 3; i++)
          const SurfaceCard(
            child: Row(
              children: [
                SkeletonBlock(width: 60, height: 60, radius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(width: 135, height: 17),
                      SizedBox(height: 9),
                      SkeletonBlock(width: 90, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CourseCubit>();
    final state = cubit.state;
    if (!cubit.demoMode) {
      final search = context.watch<SearchCubit>();
      final searchState = search.state;
      final results = searchState.results;
      final byId = {for (final course in state.courses) course.id: course};
      final matchedCourses = (results?.subjects ?? const <Subject>[])
          .map((subject) => byId[subject.id])
          .whereType<Course>()
          .toList(growable: false);
      return PageLayout(
        title: AppCopy.searchResults,
        children: [
          AppSearch(
            value: searchState.query,
            onChanged: search.search,
            onSubmitted: search.submit,
          ),
          if (searchState.status == SearchStatus.loading)
            const _SearchResultsSkeleton(),
          if (searchState.status == SearchStatus.failure) ...[
            AppText(searchState.error ?? AppCopy.serviceCurrentlyUnavailable),
            TextButton(
              onPressed: search.retry,
              child: const AppText(AppCopy.retryAction),
            ),
          ],
          if (searchState.status == SearchStatus.empty)
            const AppText(AppCopy.noResultsTryAnother),
          if (results != null) ...[
            if (results.subjects.isNotEmpty) ...[
              const SectionTitle(AppCopy.subjectsLabel),
              CategoryGrid(
                categories: results.subjects.map((item) => item.name).toList(),
                onSelect: (category) {
                  cubit.selectCategory(category);
                  context.push(AppRoutes.categories);
                },
              ),
            ],
            if (matchedCourses.isNotEmpty) ...[
              const SectionTitle(AppCopy.coursesTitle),
              CourseList(courses: matchedCourses),
            ],
            if (results.exams.isNotEmpty) ...[
              const SectionTitle(AppCopy.quizzesLabel),
              RemoteAssessmentCards(records: results.exams),
            ],
            if (results.activities.isNotEmpty) ...[
              const SectionTitle(AppCopy.activitiesLabel),
              RemoteAssessmentCards(
                records: results.activities,
                activities: true,
              ),
            ],
          ],
        ],
      );
    }
    final query = state.search.trim().toLowerCase();
    final courses = state.courses
        .where(
          (c) => '${c.title} ${c.teacher} ${c.category}'.toLowerCase().contains(
            query,
          ),
        )
        .toList();
    return CatalogContent(
      state: state,
      child: PageLayout(
        title: AppCopy.searchResults,
        children: [
          AppSearch(
            value: state.search,
            onChanged: context.read<CourseCubit>().search,
          ),
          if (courses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: AppText(AppCopy.noResultsTryAnother),
            )
          else ...[
            const SectionTitle(AppCopy.activitiesLabel),
            AssessmentList(courses: courses, activities: true),
            const SectionTitle(AppCopy.coursesTitle),
            CourseList(courses: courses),
            const SectionTitle(AppCopy.quizzesLabel),
            AssessmentList(courses: courses),
          ],
        ],
      ),
    );
  }
}
