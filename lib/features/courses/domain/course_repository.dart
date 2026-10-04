import 'package:tamkeen2/features/assessments/domain/preview_quiz_repository.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';

abstract interface class CourseRepository implements PreviewQuizRepository {
  Future<List<Course>> getCourses();
}
