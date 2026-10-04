import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/features/lessons/presentation/lesson_cubit.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/validation/app_validators.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/lessons/domain/lesson_repository.dart';

import 'package:tamkeen2/core/widgets/request_retry.dart';
import 'package:tamkeen2/features/lessons/presentation/widgets/backend_video_player.dart';

class RemoteLessonPage extends StatefulWidget {
  const RemoteLessonPage({
    super.key,
    required this.lessonId,
    this.title,
    this.repository,
  });
  final String lessonId;
  final String? title;
  final LessonRepository? repository;
  @override
  State<RemoteLessonPage> createState() => _RemoteLessonPageState();
}

class _RemoteLessonPageState extends State<RemoteLessonPage> {
  late final LessonCubit _cubit = LessonCubit(
    widget.repository ?? context.read<LessonRepository>(),
    widget.lessonId,
  )..load();
  final _comment = TextEditingController();
  final _form = GlobalKey<FormState>();
  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    final sent = await _cubit.sendComment(_comment.text);
    if (mounted && sent) _comment.clear();
  }

  @override
  void dispose() {
    _cubit.close();
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<LessonCubit, LessonState>(
    bloc: _cubit,
    builder: (context, state) {
      final lesson = state.lesson;
      return PageLayout(
        title: lesson?.title ?? widget.title ?? AppCopy.lessonInformation,
        children: [
          if (state.loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (state.error != null)
            RemoteRetry(message: state.error!, retry: _cubit.load),
          if (lesson != null && lesson.kind == LessonKind.video)
            BackendVideoPlayer(
              lesson: lesson,
              resolveSource: _cubit.resolveVideo,
              onCompleted: _cubit.attend,
            ),
          if (lesson != null && lesson.kind == LessonKind.document)
            SurfaceCard(
              child: Column(
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 72,
                    color: context.colors.secondary,
                  ),
                  if (lesson.fileUrl != null)
                    SelectableText(lesson.fileUrl!)
                  else
                    const AppText(AppCopy.mediaMissing),
                ],
              ),
            ),
          if (lesson != null && lesson.kind == LessonKind.exam) ...[
            if (lesson.exam == null)
              RemoteRetry(message: AppCopy.examMissing, retry: _cubit.load)
            else
              FilledButton(
                onPressed: () => context.push(
                  '/exam/${lesson.exam!.id}',
                  extra: lesson.exam,
                ),
                child: const AppText(AppCopy.startAction),
              ),
          ],
          if (lesson != null)
            OutlinedButton(
              onPressed:
                  state.attending || (state.attended && !state.lastPending)
                  ? null
                  : _cubit.attend,
              child: AppText(
                state.attended
                    ? AppCopy.attendanceConfirmed
                    : AppCopy.attendAction,
              ),
            ),
          if (state.attendanceError != null)
            RemoteRetry(message: state.attendanceError!, retry: _cubit.attend),
          const SectionTitle(AppCopy.discussionsLabel),
          if (state.commentError != null)
            RemoteRetry(
              message: state.commentError!,
              retry: _cubit.loadComments,
            ),
          if (state.comments.isEmpty &&
              !state.loading &&
              state.commentError == null)
            const AppText(AppCopy.noCommentsPrompt),
          for (final comment in state.comments)
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (comment.author != null)
                    AppText(
                      comment.author!,
                      style: TextStyle(color: context.colors.primary),
                    ),
                  AppText(comment.text),
                ],
              ),
            ),
          if (lesson != null)
            Form(
              key: _form,
              child: TextFormField(
                controller: _comment,
                minLines: 1,
                maxLines: 4,
                textDirection: Directionality.of(context),
                textAlign: TextAlign.start,
                validator: (value) {
                  final error = AppValidators.comment(value);
                  return error == null ? null : context.tr(error);
                },
                decoration: InputDecoration(
                  hintText: context.tr(AppCopy.writeCommentHint),
                  suffixIcon: IconButton(
                    tooltip: context.tr(AppCopy.sendComment),
                    onPressed: state.sending ? null : _send,
                    icon: state.sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
