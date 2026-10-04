import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';
import 'package:tamkeen2/features/history/presentation/widgets/remote_history_list.dart';

import 'package:tamkeen2/features/courses/presentation/widgets/course_artwork.dart';

class AssessmentList extends StatelessWidget {
  const AssessmentList({
    super.key,
    required this.courses,
    this.activities = false,
  });
  final List<Course> courses;
  final bool activities;
  @override
  Widget build(BuildContext context) => !context.watch<CourseCubit>().demoMode
      ? RemoteHistoryList(activities: activities)
      : courses.isEmpty
      ? AppText(AppCopy.noResults)
      : Column(
          children: [
            for (final course in courses)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: SurfaceCard(
                  child: InkWell(
                    onTap: () => context.push(
                      '${AppRoutes.quiz(course.id)}${activities ? '?activity=true' : ''}',
                    ),
                    child: Row(
                      children: [
                        courseAsset(
                          'icons/${activities ? 'activity' : 'quiz'}',
                          width: 65,
                          height: 72,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                '${activities ? AppCopy.activityLabel : AppCopy.quizLabel} ${course.category}',
                                style: TextStyle(
                                  color: context.colors.primary,
                                  fontSize: 17,
                                ),
                              ),
                              AppText(
                                course.teacher,
                                style: TextStyle(color: context.colors.muted),
                              ),
                              AppText(
                                AppCopy.practiceAndReview,
                                style: TextStyle(color: context.colors.primary),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_left,
                          color: context.colors.secondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
}
