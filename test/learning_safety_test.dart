import 'package:tamkeen2/features/courses/data/stored_course_progress_repository.dart';
import 'package:tamkeen2/features/assessments/presentation/preview_quiz_cubit.dart';
import 'package:tamkeen2/features/assessments/domain/quiz_question.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/storage/key_value_store.dart';
import 'package:tamkeen2/features/courses/data/course_data_source.dart';
import 'package:tamkeen2/features/courses/data/course_repository_impl.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/domain/course_repository.dart';
import 'package:tamkeen2/features/courses/domain/get_courses.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';

void main() {
  final repo = CourseRepositoryImpl(const MockCourseDataSource());
  test(
    'unexpected catalog exception is not described as a server outage',
    () async {
      final delayed = _DelayedRepository();
      final cubit = CourseCubit(GetCourses(delayed), delayed);
      final loading = cubit.load();
      delayed.catalog.completeError(StateError('secret-client-detail'));
      await loading;
      expect(cubit.state.status, LoadStatus.failure);
      expect(
        cubit.state.error,
        'حدث خطأ غير متوقع في التطبيق. يرجى المحاولة مجدداً.',
      );
      await cubit.close();
    },
  );
  test('out of range quiz answers cannot award points', () async {
    final cubit = PreviewQuizCubit(repo);
    addTearDown(cubit.close);
    await cubit.startQuiz('math');
    cubit.selectAnswer(-1);
    expect(cubit.state.selectedAnswer, isNull);
    cubit.selectAnswer(100);
    expect(cubit.state.selectedAnswer, isNull);
    expect(cubit.nextQuestion(), isFalse);
    expect(cubit.state.questionIndex, 0);
  });
  test('normal mode never grants purchases or downloads', () async {
    final cubit = CourseCubit(GetCourses(repo), repo);
    addTearDown(cubit.close);
    await cubit.load();
    cubit.purchase('arabic');
    cubit.download('math');
    expect(cubit.state.purchasedIds, isEmpty);
    expect(cubit.state.downloadedIds, isEmpty);
    expect(cubit.purchasePlan('plan-year'), isFalse);
    expect(cubit.state.purchasedIds, isEmpty);
  });
  test('unavailable data source reports recoverable failures', () async {
    final unavailable = CourseRepositoryImpl(
      const UnavailableCourseDataSource(),
    );
    final cubit = CourseCubit(GetCourses(unavailable), unavailable);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.status, LoadStatus.failure);
    expect(cubit.state.error, isNotNull);
    final quiz = PreviewQuizCubit(unavailable);
    addTearDown(quiz.close);
    await quiz.startQuiz('math');
    expect(quiz.state.quizStatus, QuizStatus.failure);
    expect(quiz.state.questions, isEmpty);
  });
  test('preview plan grants valid catalog entries only', () async {
    final cubit = CourseCubit(GetCourses(repo), repo, demoMode: true);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.purchasePlan('missing'), isFalse);
    expect(cubit.purchasePlan('plan-free'), isTrue);
    expect(cubit.state.purchasedIds, {'math', 'science'});
    expect(cubit.purchasePlan('plan-year'), isTrue);
    expect(cubit.state.purchasedIds.length, 4);
  });
  test('normal mode ignores persisted preview entitlements', () async {
    final store = _MemoryStore();
    store.values['learning.v1.alice'] =
        '{"purchases":["arabic"],"downloads":["math"],"completed":["math:0"]}';
    final cubit = CourseCubit(
      GetCourses(repo),
      repo,
      progress: StoredCourseProgressRepository(store),
    );
    addTearDown(cubit.close);
    await cubit.setOwner('alice');
    await cubit.load();
    expect(cubit.hasAccess('arabic'), isFalse);
    expect(cubit.state.downloadedIds, isEmpty);
    expect(cubit.state.completedLessonIds, isEmpty);
  });
  test('state collections cannot be modified by consumers', () async {
    final cubit = CourseCubit(GetCourses(repo), repo, demoMode: true);
    addTearDown(cubit.close);
    await cubit.load();
    cubit.toggleSaved('math');
    expect(() => cubit.state.savedIds.add('arabic'), throwsUnsupportedError);
    expect(() => cubit.state.courses.clear(), throwsUnsupportedError);
  });
  test('reset invalidates pending catalog and quiz work', () async {
    final delayed = _DelayedRepository();
    final cubit = CourseCubit(GetCourses(delayed), delayed);
    addTearDown(cubit.close);
    final loading = cubit.load();
    final quizCubit = PreviewQuizCubit(delayed);
    addTearDown(quizCubit.close);
    final quiz = quizCubit.startQuiz('math');
    cubit.reset();
    quizCubit.reset();
    delayed.catalog.complete(await repo.getCourses());
    delayed.quiz.complete(await repo.getQuestions('math'));
    await Future.wait([loading, quiz]);
    expect(cubit.state.courses, isEmpty);
    expect(quizCubit.state.questions, isEmpty);
  });
  test('closing during a request does not emit stale results', () async {
    final delayed = _DelayedRepository();
    final cubit = CourseCubit(GetCourses(delayed), delayed);
    final loading = cubit.load();
    await cubit.close();
    delayed.catalog.complete(await repo.getCourses());
    await expectLater(loading, completes);
  });
  test('whole quiz requires every answer and submits only once', () async {
    final cubit = PreviewQuizCubit(repo);
    addTearDown(cubit.close);
    await cubit.startQuiz('math');
    expect(cubit.submitQuiz(), isFalse);
    cubit.answerQuestion(0, 0);
    cubit.answerQuestion(1, 1);
    expect(cubit.submitQuiz(), isTrue);
    expect(cubit.state.score, 1);
    cubit.answerQuestion(1, 0);
    expect(cubit.submitQuiz(), isFalse);
    expect(cubit.state.score, 1);
  });
  test(
    'corrupt preferences recover and owner switches isolate state',
    () async {
      final store = _MemoryStore();
      store.values['learning.v1.alice'] = '{bad json';
      final cubit = CourseCubit(
        GetCourses(repo),
        repo,
        progress: StoredCourseProgressRepository(store),
        demoMode: true,
      );
      addTearDown(cubit.close);
      await cubit.setOwner('alice');
      await cubit.load();
      cubit.toggleSaved('math');
      expect(cubit.state.savedIds, {'math'});
      await cubit.setOwner('bob');
      expect(cubit.state.savedIds, isEmpty);
      expect(cubit.state.purchasedIds, isEmpty);
    },
  );
  test('preview validates identifiers and comments', () async {
    final cubit = CourseCubit(GetCourses(repo), repo, demoMode: true);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.purchase('missing'), isFalse);
    expect(cubit.addComment('math', 0, ' '), isFalse);
    expect(cubit.addComment('math', 0, 'شرح واضح'), isTrue);
    expect(cubit.state.comments['math:0'], ['شرح واضح']);
    expect(cubit.completeLesson('math', 2), isFalse);
    expect(cubit.completeLesson('math', 0), isTrue);
    expect(cubit.canOpenLesson('math', 1), isTrue);
  });
}

class _DelayedRepository implements CourseRepository {
  final catalog = Completer<List<Course>>();
  final quiz = Completer<List<QuizQuestion>>();
  @override
  Future<List<Course>> getCourses() => catalog.future;
  @override
  Future<List<QuizQuestion>> getQuestions(String courseId) => quiz.future;
}

class _MemoryStore implements KeyValueStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}
