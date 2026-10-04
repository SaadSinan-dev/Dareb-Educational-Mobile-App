import 'package:tamkeen2/features/assessments/domain/quiz_question.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/domain/course_repository.dart';
import 'package:tamkeen2/features/courses/domain/get_courses.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';

void main() {
  test('live lesson flags grant only the access returned by the API', () async {
    final repository = _StaticRepository([
      _course(
        'paid',
        lessons: const [
          Lesson(title: 'Locked', minutes: 0),
          Lesson(title: 'Free preview', minutes: 0, isFree: true),
          Lesson(title: 'Free semester', minutes: 0, semesterIsFree: true),
          Lesson(
            title: 'Subscribed semester',
            minutes: 0,
            semesterIsSubscribed: true,
          ),
          Lesson(title: 'Subscribed lesson', minutes: 0, isSubscribed: true),
        ],
      ),
    ]);
    final cubit = CourseCubit(GetCourses(repository), repository);
    addTearDown(cubit.close);
    await cubit.load();

    expect(cubit.hasAccess('paid'), isFalse);
    expect(cubit.canOpenLesson('paid', 0), isFalse);
    for (final index in [1, 2, 3, 4]) {
      expect(cubit.hasLessonAccess('paid', index), isTrue);
      expect(cubit.canOpenLesson('paid', index), isTrue);
    }
    expect(cubit.canOpenLesson('paid', 5), isFalse);
    expect(cubit.completeLesson('paid', 1), isFalse);
    expect(cubit.purchase('paid'), isFalse);
    expect(cubit.state.completedLessonIds, isEmpty);
    expect(cubit.state.purchasedIds, isEmpty);
  });

  test(
    'course subscription and course free flags grant their lessons',
    () async {
      final repository = _StaticRepository([
        _course('subscribed', isSubscribed: true),
        _course('free', isFree: true),
      ]);
      final cubit = CourseCubit(GetCourses(repository), repository);
      addTearDown(cubit.close);
      await cubit.load();

      expect(cubit.hasAccess('subscribed'), isTrue);
      expect(cubit.hasAccess('free'), isTrue);
      expect(cubit.canOpenLesson('subscribed', 0), isTrue);
      expect(cubit.canOpenLesson('free', 0), isTrue);
    },
  );
}

Course _course(
  String id, {
  bool isFree = false,
  bool isSubscribed = false,
  List<Lesson> lessons = const [Lesson(title: 'Paid lesson', minutes: 0)],
}) => Course(
  id: id,
  title: id,
  category: 'Subject',
  teacher: 'Teacher',
  description: '',
  lessons: lessons,
  isFree: isFree,
  isSubscribed: isSubscribed,
  price: 10,
  accent: 0,
);

class _StaticRepository implements CourseRepository {
  const _StaticRepository(this.courses);
  final List<Course> courses;

  @override
  Future<List<Course>> getCourses() async => courses;

  @override
  Future<List<QuizQuestion>> getQuestions(String courseId) async =>
      throw const AppFailure.unavailable();
}
