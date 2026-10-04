import 'package:tamkeen2/features/assessments/presentation/preview_quiz_cubit.dart';
import 'package:tamkeen2/features/assessments/domain/quiz_question.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/features/courses/data/course_data_source.dart';
import 'package:tamkeen2/features/courses/data/course_repository_impl.dart';
import 'package:tamkeen2/features/courses/domain/get_courses.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/domain/course_repository.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';

void main() {
  test('catalog filtering and quiz answers stay in the Cubit', () async {
    final repository = CourseRepositoryImpl(const MockCourseDataSource());
    final cubit = CourseCubit(GetCourses(repository), repository);
    addTearDown(cubit.close);

    await cubit.load();
    expect(cubit.state.status, LoadStatus.ready);
    expect(cubit.state.courses.length, 4);

    cubit.selectCategory('اللغات');
    expect(cubit.state.visibleCourses.length, 2);
    cubit.search('العربية');
    expect(cubit.state.visibleCourses.single.id, 'arabic');

    final quiz = PreviewQuizCubit(repository);
    addTearDown(quiz.close);
    await quiz.startQuiz('arabic');
    expect(quiz.state.quizStatus, QuizStatus.ready);
    quiz.selectAnswer(0);
    expect(quiz.nextQuestion(), isFalse);
    expect(quiz.state.score, 1);
    quiz.selectAnswer(0);
    expect(quiz.nextQuestion(), isTrue);
    expect(quiz.state.score, 2);
    expect(quiz.nextQuestion(), isFalse);
  });

  test('quiz failure becomes a recoverable state', () async {
    final repository = _FailingQuizRepository();
    final cubit = PreviewQuizCubit(repository);
    addTearDown(cubit.close);

    await cubit.startQuiz('missing');
    expect(cubit.state.quizStatus, QuizStatus.failure);
    expect(cubit.state.questions, isEmpty);
  });
}

class _FailingQuizRepository implements CourseRepository {
  @override
  Future<List<Course>> getCourses() async => const [];

  @override
  Future<List<QuizQuestion>> getQuestions(String courseId) async =>
      throw StateError('No quiz data');
}
