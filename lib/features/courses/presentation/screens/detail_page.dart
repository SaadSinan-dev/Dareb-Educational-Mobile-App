import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';
import 'package:tamkeen2/core/widgets/request_retry.dart';

import 'package:tamkeen2/features/courses/presentation/widgets/catalog_widgets.dart';
import 'package:tamkeen2/features/courses/presentation/widgets/course_artwork.dart';
import 'package:tamkeen2/features/lessons/presentation/widgets/lesson_list.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.courseId});
  final String courseId;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CourseCubit>().state;
    final course = findCourse(context, courseId);
    if (course == null) return MissingCourse(state: state);
    return PageLayout(
      title: AppCopy.courseDetails,
      header: LayoutBuilder(
        builder: (context, constraints) {
          final scale = (constraints.maxWidth / 430).clamp(.74, 1.0);
          return SizedBox(
            height: 353 * scale,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(22),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: (constraints.maxWidth - 430 * scale) / 2 + 65 * scale,
                  top: 42 * scale,
                  child: courseArtwork(
                    course,
                    width: 287 * scale,
                    height: 324 * scale,
                  ),
                ),
                Positioned(
                  top: 22 * scale,
                  right: 16,
                  child: IconButton(
                    tooltip: context.tr(AppCopy.backAction),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.home);
                      }
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.colors.onBrand,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * .45,
                ),
                child: AppText(
                  course.teacher,
                  style: TextStyle(color: context.colors.primary),
                ),
              ),
              Expanded(
                child: AppText(
                  course.title,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: context.colors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (course.points > 0) ...[
              Icon(
                Icons.monetization_on_outlined,
                size: 17,
                color: context.colors.secondary,
              ),
              const SizedBox(width: 3),
              AppText(
                '${course.points}',
                style: TextStyle(color: context.colors.primary),
              ),
            ],
            Expanded(
              child: AppText(
                course.id == 'math'
                    ? AppCopy.format(AppCopy.chaptersAndLessons, [
                        course.lessons.length,
                      ])
                    : AppCopy.format(AppCopy.lessonCountAndPrice, [
                        course.lessons.length,
                        course.isFree
                            ? AppCopy.freeLabel
                            : AppCopy.format(AppCopy.priceInSyrianPounds, [
                                course.price,
                              ]),
                      ]),
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: context.colors.muted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 32),
        Align(
          alignment: Alignment.centerRight,
          child: SectionTitle(AppCopy.descriptionLabel),
        ),
        AppText(
          course.description,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: context.colors.muted,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: SectionTitle(AppCopy.learningPath),
        ),
        if (course.id == 'math')
          Align(
            alignment: Alignment.centerRight,
            child: AppText(
              AppCopy.statisticsSectionTwelve,
              style: TextStyle(color: context.colors.muted),
            ),
          ),
        const SizedBox(height: 20),
        LessonList(course: course),
        if (course.detailsError != null)
          RemoteRetry(
            message: course.detailsError!,
            retry: context.read<CourseCubit>().load,
          ),
        FilledButton(
          onPressed: course.lessons.isEmpty
              ? null
              : () => openLesson(context, course, 0),
          child: AppText(AppCopy.startLearning),
        ),
        learningSectionGap,
        OutlinedButton.icon(
          onPressed: () {
            context.read<CourseCubit>().download(course.id);
            showLearningOperation(context);
          },
          icon: Icon(Icons.download_outlined),
          label: AppText(
            state.downloadedIds.contains(course.id)
                ? AppCopy.inPreviewList
                : AppCopy.downloadCourse,
          ),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.quiz(course.id)),
          child: AppText(AppCopy.testYourKnowledge),
        ),
      ],
    );
  }
}
