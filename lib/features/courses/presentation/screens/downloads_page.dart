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

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CourseCubit>();
    final courses = cubit.state.courses.where(
      (c) => cubit.state.downloadedIds.contains(c.id),
    );
    return PageLayout(
      title: AppCopy.downloadedCoursesTitle,
      children: [
        if (courses.isEmpty)
          const Center(child: AppText(AppCopy.downloadListEmpty)),
        if (courses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppText(
              AppCopy.previewDownloadListNotice,
              style: TextStyle(color: context.colors.muted),
            ),
          ),
        for (final course in courses) ...[
          for (var i = 0; i < course.lessons.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: context.colors.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: context.colors.surface,
                  child: AppText(
                    '${i + 1}',
                    style: TextStyle(color: context.colors.secondary),
                  ),
                ),
              ),
              title: AppText(
                course.lessons[i].title,
                style: TextStyle(color: context.colors.primary),
              ),
              subtitle: AppText(
                course.lessons[i].kind == LessonKind.document
                    ? AppCopy.format(AppCopy.pageCountLabel, [
                        course.lessons[i].pages,
                      ])
                    : AppCopy.format(AppCopy.minuteCountLabel, [
                        course.lessons[i].minutes,
                      ]),
              ),
              trailing: IconButton(
                tooltip: context.tr(
                  course.lessons[i].kind == LessonKind.document
                      ? AppCopy.openDocumentAction
                      : AppCopy.playLessonAction,
                ),
                onPressed: () => context.push(AppRoutes.lesson(course.id, i)),
                icon: Icon(
                  course.lessons[i].kind == LessonKind.document
                      ? Icons.menu_book
                      : Icons.play_circle,
                  color: context.colors.secondary,
                ),
              ),
              onTap: () => context.push(AppRoutes.lesson(course.id, i)),
            ),
          Tooltip(
            message: context.tr(AppCopy.removeFromDownloadListAction),
            child: TextButton(
              onPressed: () => cubit.removeDownload(course.id),
              child: AppText(
                AppCopy.format(AppCopy.removeItemFromListLabel, [course.title]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
