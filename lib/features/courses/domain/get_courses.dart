import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/domain/course_repository.dart';

class GetCourses {
  const GetCourses(this.repository);
  final CourseRepository repository;
  Future<List<Course>> call() => repository.getCourses();
}
