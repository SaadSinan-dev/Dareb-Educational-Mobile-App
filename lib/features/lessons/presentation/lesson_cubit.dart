import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/core/validation/app_validators.dart';
import 'package:tamkeen2/features/lessons/domain/lesson.dart';
import 'package:tamkeen2/features/lessons/domain/lesson_repository.dart';
import 'package:tamkeen2/core/errors/failure_message.dart';

class LessonState {
  const LessonState({
    this.loading = true,
    this.lesson,
    this.comments = const [],
    this.error,
    this.commentError,
    this.attendanceError,
    this.sending = false,
    this.attending = false,
    this.attended = false,
    this.lastPending = false,
  });
  final RemoteLesson? lesson;
  final List<RemoteComment> comments;
  final String? error, commentError, attendanceError;
  final bool loading, sending, attending, attended, lastPending;

  LessonState copyWith({
    bool? loading,
    RemoteLesson? lesson,
    List<RemoteComment>? comments,
    String? error,
    String? commentError,
    String? attendanceError,
    bool? sending,
    bool? attending,
    bool? attended,
    bool? lastPending,
    bool clearError = false,
    bool clearCommentError = false,
    bool clearAttendanceError = false,
  }) => LessonState(
    loading: loading ?? this.loading,
    lesson: lesson ?? this.lesson,
    comments: comments ?? this.comments,
    error: clearError ? null : error ?? this.error,
    commentError: clearCommentError ? null : commentError ?? this.commentError,
    attendanceError: clearAttendanceError
        ? null
        : attendanceError ?? this.attendanceError,
    sending: sending ?? this.sending,
    attending: attending ?? this.attending,
    attended: attended ?? this.attended,
    lastPending: lastPending ?? this.lastPending,
  );
}

/// Owns lesson requests and mutation confirmation independently of widget life.
class LessonCubit extends Cubit<LessonState> {
  LessonCubit(this.repository, this.lessonId) : super(const LessonState());
  final LessonRepository repository;
  final String lessonId;
  int _loadEpoch = 0, _commentEpoch = 0;

  Future<void> load() async {
    if (isClosed) return;
    final epoch = ++_loadEpoch;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final lesson = await repository.lesson(lessonId);
      if (isClosed || epoch != _loadEpoch) return;
      emit(
        state.copyWith(
          lesson: lesson,
          loading: false,
          attended: state.attended || lesson.isAttended,
        ),
      );
      await loadComments();
    } catch (error) {
      if (!isClosed && epoch == _loadEpoch) {
        emit(state.copyWith(loading: false, error: failureMessage(error)));
      }
    }
  }

  Future<void> loadComments() async {
    if (isClosed) return;
    final epoch = ++_commentEpoch;
    try {
      final comments = await repository.comments(lessonId);
      if (!isClosed && epoch == _commentEpoch) {
        emit(
          state.copyWith(
            comments: List.unmodifiable(comments),
            clearCommentError: true,
          ),
        );
      }
    } catch (error) {
      if (!isClosed && epoch == _commentEpoch) {
        emit(state.copyWith(commentError: failureMessage(error)));
      }
    }
  }

  Future<bool> sendComment(String text) async {
    if (isClosed || state.sending) return false;
    final validation = AppValidators.comment(text);
    if (validation != null) {
      emit(state.copyWith(commentError: validation));
      return false;
    }
    emit(state.copyWith(sending: true, clearCommentError: true));
    try {
      await repository.addComment(lessonId, text.trim());
      if (isClosed) return true;
      await loadComments();
      return true;
    } catch (error) {
      if (!isClosed) emit(state.copyWith(commentError: failureMessage(error)));
      return false;
    } finally {
      if (!isClosed) emit(state.copyWith(sending: false));
    }
  }

  Future<void> attend() async {
    final lesson = state.lesson;
    if (isClosed ||
        state.attending ||
        (state.attended && !state.lastPending) ||
        lesson == null) {
      return;
    }
    emit(state.copyWith(attending: true, clearAttendanceError: true));
    try {
      if (!state.attended) {
        await repository.attendLesson(lessonId);
        if (isClosed) return;
        emit(state.copyWith(attended: true, lastPending: true));
      }
      await repository.lastAttended(lesson.semesterId);
      if (!isClosed) emit(state.copyWith(lastPending: false));
    } catch (error) {
      if (!isClosed) {
        emit(state.copyWith(attendanceError: failureMessage(error)));
      }
    } finally {
      if (!isClosed) emit(state.copyWith(attending: false));
    }
  }

  Future<Uri> resolveVideo() => repository.resolveVideo(state.lesson!);
}
