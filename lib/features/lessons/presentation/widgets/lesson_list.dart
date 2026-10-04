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

import 'package:tamkeen2/features/courses/presentation/widgets/catalog_widgets.dart';
import 'package:tamkeen2/features/courses/presentation/widgets/course_artwork.dart';

IconData lessonIcon(Lesson lesson) => switch (lesson.kind) {
  LessonKind.video => Icons.schedule_outlined,
  LessonKind.document => Icons.description_outlined,
  LessonKind.exam => Icons.quiz_outlined,
};

String? lessonMetadata(Lesson lesson) {
  if (lesson.kind == LessonKind.exam) return AppCopy.quizLabel;
  final rawTime = lesson.durationText?.trim();
  if (rawTime != null && rawTime.isNotEmpty) return rawTime;
  if (lesson.kind == LessonKind.document && lesson.pages > 0) {
    return AppCopy.format(AppCopy.lessonPageCount, [lesson.pages]);
  }
  if (lesson.minutes > 0) {
    return AppCopy.format(AppCopy.lessonMinuteCount, [lesson.minutes]);
  }
  return null;
}

Future<void> openLesson(BuildContext context, Course course, int index) async {
  final cubit = context.read<CourseCubit>();
  if (index < 0 || index >= course.lessons.length) return;
  if (!cubit.hasLessonAccess(course.id, index)) {
    final subscribe = await showDialog<bool>(
      context: context,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .67),
      builder: (_) => const AppDecisionDialog(
        title: AppCopy.subscribeForAccess,
        confirmLabel: AppCopy.subscribeAction,
      ),
    );
    if (subscribe == true && context.mounted) {
      context.push(AppRoutes.checkout(course.id));
    }
    return;
  }
  if (!cubit.canOpenLesson(course.id, index)) {
    final previous = await showDialog<bool>(
      context: context,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .67),
      builder: (_) => const AppDecisionDialog(
        title: AppCopy.completePreviousLesson,
        confirmLabel: AppCopy.startAction,
        warning: true,
      ),
    );
    if (previous == true && context.mounted) {
      var next = 0;
      while (next < index &&
          cubit.state.completedLessonIds.contains('${course.id}:$next')) {
        next++;
      }
      context.push(AppRoutes.lesson(course.id, next));
    }
    return;
  }
  if (course.lessons[index].kind == LessonKind.exam) {
    context.push(AppRoutes.lesson(course.id, index));
    return;
  }
  final start = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: courseAsset(
              'images/lesson_intro',
              height: 205,
              width: 300,
              fit: BoxFit.cover,
            ),
          ),
          learningSectionGap,
          AppText(
            course.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.primary),
          ),
          learningSectionGap,
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: AppText(AppCopy.startNow),
          ),
        ],
      ),
    ),
  );
  if (start == true && context.mounted) {
    context.push(AppRoutes.lesson(course.id, index));
  }
}

class LessonList extends StatelessWidget {
  const LessonList({super.key, required this.course});
  final Course course;
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CourseCubit>();
    return Column(
      children: [
        for (var i = 0; i < course.lessons.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: cubit.canOpenLesson(course.id, i)
                      ? context.colors.primary
                      : context.colors.border,
                  child: Icon(
                    cubit.state.completedLessonIds.contains('${course.id}:$i')
                        ? Icons.check
                        : cubit.canOpenLesson(course.id, i)
                        ? course.lessons[i].kind == LessonKind.exam
                              ? Icons.quiz_outlined
                              : Icons.play_arrow
                        : Icons.lock_outline,
                    color: cubit.canOpenLesson(course.id, i)
                        ? context.colors.onBrand
                        : context.colors.muted,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SurfaceCard(
                    child: InkWell(
                      onTap: () => openLesson(context, course, i),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: AppText(course.lessons[i].title)),
                              if (i == 0 &&
                                  (cubit.state.completedLessonIds.contains(
                                        '${course.id}:$i',
                                      ) ||
                                      cubit.state.downloadedIds.contains(
                                        course.id,
                                      )))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        cubit.state.completedLessonIds.contains(
                                          '${course.id}:$i',
                                        )
                                        ? context.colors.successSoft
                                        : context.colors.errorSoft,
                                    border: Border.all(
                                      color:
                                          cubit.state.completedLessonIds
                                              .contains('${course.id}:$i')
                                          ? context.colors.success
                                          : context.colors.error,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: AppText(
                                    cubit.state.completedLessonIds.contains(
                                          '${course.id}:$i',
                                        )
                                        ? AppCopy.watchedLabel
                                        : AppCopy.unwatchedLabel,
                                    style: TextStyle(fontSize: 9),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(lessonIcon(course.lessons[i]), size: 16),
                              if (lessonMetadata(course.lessons[i])
                                  case final text?)
                                Expanded(child: AppText(text))
                              else
                                const Spacer(),
                              if (course.lessons[i].kind != LessonKind.exam)
                                IconButton(
                                  tooltip: context.tr(AppCopy.downloadAction),
                                  onPressed: () {
                                    cubit.download(course.id);
                                    showLearningOperation(context);
                                  },
                                  icon: Icon(
                                    Icons.download_outlined,
                                    color: context.colors.secondary,
                                  ),
                                ),
                            ],
                          ),
                          if (i == 0 &&
                              cubit.state.downloadedIds.contains(course.id))
                            AppText(
                              AppCopy.inPreviewList,
                              style: TextStyle(
                                color: context.colors.primary,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
