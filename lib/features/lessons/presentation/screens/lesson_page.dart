import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';
import 'package:tamkeen2/features/lessons/presentation/screens/remote_lesson_page.dart';
import 'package:tamkeen2/core/validation/app_validators.dart';

import 'package:tamkeen2/features/courses/presentation/widgets/catalog_widgets.dart';
import 'package:tamkeen2/features/courses/presentation/widgets/course_artwork.dart';
import 'package:tamkeen2/features/lessons/presentation/widgets/lesson_list.dart';

class LessonPage extends StatefulWidget {
  const LessonPage({super.key, required this.courseId, required this.index});
  final String courseId;
  final int index;
  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  final comment = TextEditingController();
  bool allComments = false;
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CourseCubit>();
    final course = cubit.course(widget.courseId);
    if (course == null) return MissingCourse(state: cubit.state);
    if (!cubit.canOpenLesson(course.id, widget.index)) {
      final hasEntitlement = cubit.hasLessonAccess(course.id, widget.index);
      return PageLayout(
        title: AppCopy.lessonUnavailableTitle,
        children: [
          AppText(
            hasEntitlement
                ? AppCopy.completePreviousLesson
                : AppCopy.subscribeForAccess,
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.detail(course.id)),
            child: AppText(AppCopy.learningPath),
          ),
        ],
      );
    }
    final lesson = course.lessons[widget.index];
    if (!cubit.demoMode && lesson.id != null) {
      return RemoteLessonPage(lessonId: lesson.id!, title: lesson.title);
    }
    if (lesson.kind == LessonKind.exam) {
      return PageLayout(
        title: lesson.title,
        children: [
          AppText(AppCopy.quizUnavailableMessage),
          TextButton(
            onPressed: () => context.go(AppRoutes.detail(course.id)),
            child: AppText(AppCopy.learningPath),
          ),
        ],
      );
    }
    final comments = cubit.state.comments['${course.id}:${widget.index}'] ?? [];
    return PageLayout(
      title: lesson.title,
      children: [
        if (lesson.kind == LessonKind.document)
          Container(
            height: 200,
            color: context.colors.primary.withValues(alpha: .08),
            child: Icon(
              Icons.menu_book_outlined,
              size: 90,
              color: context.colors.secondary,
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              alignment: Alignment.center,
              children: [
                courseAsset(
                  'images/lesson_poster',
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Container(
                  height: 240,
                  color: Theme.of(
                    context,
                  ).colorScheme.scrim.withValues(alpha: .26),
                ),
                Icon(
                  Icons.videocam_off_outlined,
                  size: 64,
                  color: context.colors.onBrand,
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: AppText(
            lesson.kind == LessonKind.document
                ? AppCopy.lessonFileUnavailable
                : AppCopy.videoPlaybackUnavailable,
            textAlign: TextAlign.center,
          ),
        ),
        Row(
          children: [
            IconButton(
              tooltip: context.tr(AppCopy.shareLessonInformation),
              icon: Icon(Icons.share_outlined),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (dialog) => AlertDialog(
                  title: AppText(AppCopy.lessonInformation),
                  content: AppText(
                    '${course.title}\n${course.lessons[widget.index].title}\n${course.teacher}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialog),
                      child: AppText(AppCopy.closeAction),
                    ),
                    TextButton(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(
                            text:
                                '${course.title}\n${course.lessons[widget.index].title}\n${course.teacher}',
                          ),
                        );
                        if (dialog.mounted) Navigator.pop(dialog);
                        if (context.mounted) {
                          showAppMessage(
                            context,
                            AppCopy.lessonInformationCopied,
                          );
                        }
                      },
                      child: AppText(AppCopy.copyInformation),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: context.tr(AppCopy.downloadLesson),
              onPressed: () {
                cubit.download(course.id);
                showLearningOperation(context);
              },
              icon: Icon(Icons.download_outlined),
            ),
            Expanded(child: AppText(lessonMetadata(lesson) ?? '')),
          ],
        ),
        if (cubit.demoMode)
          OutlinedButton(
            onPressed: () {
              cubit.completeLesson(course.id, widget.index);
              showLearningOperation(context);
            },
            child: AppText(AppCopy.markPreviewLessonComplete),
          ),
        SectionTitle(
          AppCopy.discussionsLabel,
          onSeeAll: comments.length > 2
              ? () => setState(() => allComments = !allComments)
              : null,
        ),
        if (comments.isEmpty) AppText(AppCopy.noCommentsPrompt),
        for (final text in (allComments ? comments : comments.take(2)))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    AppCopy.yourLocalPreviewComment,
                    style: TextStyle(color: context.colors.primary),
                  ),
                  AppText(text),
                ],
              ),
            ),
          ),
        learningSectionGap,
        TextField(
          controller: comment,
          maxLength: AppValidators.maxMessageLength,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: context.tr(AppCopy.writeCommentHint),
            suffixIcon: IconButton(
              tooltip: context.tr(AppCopy.sendComment),
              onPressed: () {
                if (cubit.addComment(course.id, widget.index, comment.text)) {
                  comment.clear();
                }
                showLearningOperation(context);
              },
              icon: Icon(Icons.send_outlined),
            ),
          ),
        ),
        const SectionTitle(AppCopy.learningPath),
        LessonList(course: course),
      ],
    );
  }
}
