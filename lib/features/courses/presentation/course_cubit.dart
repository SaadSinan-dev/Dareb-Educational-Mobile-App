import 'dart:async';
import 'package:tamkeen2/core/validation/app_validators.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/features/courses/domain/course_progress.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/domain/course_repository.dart';
import 'package:tamkeen2/features/courses/domain/get_courses.dart';

enum LoadStatus { initial, loading, refreshing, ready, empty, failure }

class CourseState {
  const CourseState({
    this.status = LoadStatus.initial,
    this.courses = const [],
    this.error,
    this.search = '',
    this.category,
    this.savedIds = const {},
    this.downloadedIds = const {},
    this.purchasedIds = const {},
    this.completedLessonIds = const {},
    this.comments = const {},
    this.operationError,
    this.operationMessage,
  });
  final LoadStatus status;
  final List<Course> courses;
  final String? error, category, operationError, operationMessage;
  final String search;
  final Set<String> savedIds, downloadedIds, purchasedIds, completedLessonIds;
  final Map<String, List<String>> comments;
  List<Course> get visibleCourses => courses
      .where(
        (c) =>
            (category == null || c.category == category) &&
            '${c.title} ${c.teacher} ${c.category}'.toLowerCase().contains(
              search.trim().toLowerCase(),
            ),
      )
      .toList(growable: false);
  CourseState copyWith({
    LoadStatus? status,
    List<Course>? courses,
    String? error,
    String? search,
    String? category,
    bool clearCategory = false,
    Set<String>? savedIds,
    Set<String>? downloadedIds,
    Set<String>? purchasedIds,
    Set<String>? completedLessonIds,
    Map<String, List<String>>? comments,
    String? operationError,
    String? operationMessage,
  }) => CourseState(
    status: status ?? this.status,
    courses: List.unmodifiable(courses ?? this.courses),
    error: error,
    search: search ?? this.search,
    category: clearCategory ? null : category ?? this.category,
    savedIds: Set.unmodifiable(savedIds ?? this.savedIds),
    downloadedIds: Set.unmodifiable(downloadedIds ?? this.downloadedIds),
    purchasedIds: Set.unmodifiable(purchasedIds ?? this.purchasedIds),
    completedLessonIds: Set.unmodifiable(
      completedLessonIds ?? this.completedLessonIds,
    ),
    comments: Map.unmodifiable(
      (comments ?? this.comments).map(
        (k, v) => MapEntry(k, List<String>.unmodifiable(v)),
      ),
    ),
    operationError: operationError,
    operationMessage: operationMessage,
  );
}

class CourseCubit extends Cubit<CourseState> {
  CourseCubit(
    this.getCourses,
    this.repository, {
    this.progress,
    this.demoMode = false,
  }) : super(const CourseState());
  final GetCourses getCourses;
  final CourseRepository repository;
  final CourseProgressRepository? progress;
  final bool demoMode;
  int _epoch = 0, _catalogRequest = 0;
  String? _owner;
  Future<void> _writes = Future.value();
  bool _current(int epoch) => !isClosed && epoch == _epoch;
  String _safeError(Object error) =>
      error is AppFailure ? error.message : AppCopy.unexpectedClientError;
  Future<void> load() async {
    if (isClosed) return;
    final epoch = _epoch, request = ++_catalogRequest;
    emit(
      state.copyWith(
        status: state.courses.isEmpty
            ? LoadStatus.loading
            : LoadStatus.refreshing,
      ),
    );
    try {
      final courses = await getCourses();
      if (_current(epoch) && request == _catalogRequest) {
        emit(
          state.copyWith(
            status: courses.isEmpty ? LoadStatus.empty : LoadStatus.ready,
            courses: courses,
          ),
        );
      }
    } catch (e) {
      if (_current(epoch) && request == _catalogRequest) {
        emit(state.copyWith(status: LoadStatus.failure, error: _safeError(e)));
      }
    }
  }

  void reset() {
    _epoch++;
    _catalogRequest++;
    _owner = null;
    if (!isClosed) emit(const CourseState());
  }

  Future<void> setOwner(String? userId) async {
    if (_owner == userId || isClosed) return;
    reset();
    _owner = userId;
    if (userId == null || progress == null) return;
    final epoch = _epoch;
    try {
      await _writes;
      if (!_current(epoch)) return;
      final saved = await progress!.load(userId);
      if (!_current(epoch)) return;
      emit(
        state.copyWith(
          savedIds: saved.saved,
          downloadedIds: demoMode ? saved.downloads : {},
          purchasedIds: demoMode ? saved.purchases : {},
          completedLessonIds: demoMode ? saved.completed : {},
        ),
      );
    } catch (_) {
      /* Corrupt preferences must not prevent learning. */
    }
  }

  void _persist() {
    final owner = _owner;
    if (progress == null || owner == null) return;
    final snapshot = CourseProgress(
      saved: state.savedIds,
      downloads: demoMode ? state.downloadedIds : {},
      purchases: demoMode ? state.purchasedIds : {},
      completed: demoMode ? state.completedLessonIds : {},
    );
    _writes = _writes
        .then((_) => progress!.save(owner, snapshot))
        .catchError((Object _) {});
  }

  void search(String value) {
    if (!isClosed) emit(state.copyWith(search: value));
  }

  void selectCategory(String? value) {
    if (!isClosed) {
      emit(state.copyWith(category: value, clearCategory: value == null));
    }
  }

  Course? course(String id) {
    for (final c in state.courses) {
      if (c.id == id) return c;
    }
    return null;
  }

  void toggleSaved(String id) {
    if (isClosed || course(id) == null) return;
    final ids = {...state.savedIds};
    if (!ids.remove(id)) ids.add(id);
    emit(state.copyWith(savedIds: ids));
    _persist();
  }

  bool _fail(String message) {
    if (!isClosed) emit(state.copyWith(operationError: message));
    return false;
  }

  bool purchase(String id) {
    if (isClosed) return false;
    if (!demoMode) return _fail(const AppFailure.unavailable().message);
    if (course(id) == null) return _fail(AppCopy.courseUnavailableMessage);
    emit(
      state.copyWith(
        purchasedIds: {...state.purchasedIds, id},
        operationMessage: AppCopy.previewAccessActivated,
      ),
    );
    _persist();
    return true;
  }

  bool purchasePlan(String id) {
    if (isClosed) return false;
    if (!demoMode) return _fail(const AppFailure.unavailable().message);
    if (id != 'plan-year' && id != 'plan-free') {
      return _fail(AppCopy.planUnavailableMessage);
    }
    if (state.courses.isEmpty) return _fail(AppCopy.loadSubjectsBeforePreview);
    final ids = state.courses
        .where((c) => id == 'plan-year' || c.isFree)
        .map((c) => c.id);
    emit(
      state.copyWith(
        purchasedIds: {...state.purchasedIds, ...ids},
        operationMessage: AppCopy.previewPlanActivated,
      ),
    );
    _persist();
    return true;
  }

  bool download(String id) {
    if (isClosed) return false;
    if (!demoMode) return _fail(AppCopy.lessonDownloadsUnavailable);
    if (course(id) == null) return _fail(AppCopy.courseUnavailableMessage);
    emit(
      state.copyWith(
        downloadedIds: {...state.downloadedIds, id},
        operationMessage: AppCopy.addedToPreviewList,
      ),
    );
    _persist();
    return true;
  }

  void removeDownload(String id) {
    if (!isClosed) {
      emit(state.copyWith(downloadedIds: {...state.downloadedIds}..remove(id)));
      _persist();
    }
  }

  bool hasAccess(String id) {
    final current = course(id);
    return current != null &&
        (current.isFree ||
            current.isSubscribed ||
            (demoMode && state.purchasedIds.contains(id)));
  }

  bool hasLessonAccess(String id, int index) {
    final current = course(id);
    if (current == null || index < 0 || index >= current.lessons.length) {
      return false;
    }
    final lesson = current.lessons[index];
    return hasAccess(id) ||
        lesson.semesterIsFree ||
        lesson.semesterIsSubscribed ||
        lesson.isFree ||
        lesson.isSubscribed;
  }

  bool canOpenLesson(String id, int index) =>
      hasLessonAccess(id, index) &&
      (!demoMode ||
          index == 0 ||
          state.completedLessonIds.contains('$id:${index - 1}'));
  bool completeLesson(String id, int index) {
    if (isClosed) return false;
    if (!demoMode) return _fail(AppCopy.lessonPlaybackRequired);
    if (!canOpenLesson(id, index)) {
      return _fail(AppCopy.completePreviousLessonFirst);
    }
    emit(
      state.copyWith(
        completedLessonIds: {...state.completedLessonIds, '$id:$index'},
        operationMessage: AppCopy.previewProgressRecorded,
      ),
    );
    _persist();
    return true;
  }

  bool addComment(String id, int index, String text) {
    if (isClosed) return false;
    if (AppValidators.comment(text) != null) {
      return _fail(AppCopy.commentLengthValidation);
    }
    if (!canOpenLesson(id, index)) {
      return _fail(AppCopy.lessonUnavailableMessage);
    }
    if (!demoMode) return _fail(const AppFailure.unavailable().message);
    final key = '$id:$index';
    emit(
      state.copyWith(
        comments: {
          ...state.comments,
          key: [...?state.comments[key], text.trim()],
        },
        operationMessage: AppCopy.localPreviewCommentAdded,
      ),
    );
    return true;
  }
}
