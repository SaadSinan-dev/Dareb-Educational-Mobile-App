import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';

class CourseProgress extends StatelessWidget {
  const CourseProgress({super.key, required this.course});
  final Course course;
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CourseCubit>();
    if (!cubit.demoMode) return const SizedBox.shrink();
    final state = cubit.state;
    final count = List.generate(
      course.lessons.length,
      (i) => '${course.id}:$i',
    ).where(state.completedLessonIds.contains).length;
    final progress = course.lessons.isEmpty
        ? 0.0
        : count / course.lessons.length;
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: AppText(AppCopy.completedLessons)),
            AppText(
              AppCopy.format(AppCopy.completedOfTotal, [
                count,
                course.lessons.length,
              ]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          color: context.colors.secondary,
          backgroundColor: context.colors.border,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }
}
