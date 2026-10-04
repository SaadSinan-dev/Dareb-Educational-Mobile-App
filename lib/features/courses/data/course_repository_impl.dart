import 'package:tamkeen2/features/assessments/domain/quiz_question.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/domain/course_repository.dart';
import 'package:tamkeen2/features/courses/domain/subject.dart';
import 'package:tamkeen2/features/courses/domain/subject_repository.dart';
import 'package:tamkeen2/features/courses/data/course_data_source.dart';

class CourseRepositoryImpl implements CourseRepository, SubjectRepository {
  const CourseRepositoryImpl(this.source);
  final CourseDataSource source;

  @override
  Future<List<Course>> getCourses() async => (await source.readCourses())
      .map((model) => model.toEntity())
      .toList(growable: false);

  @override
  Future<List<QuizQuestion>> getQuestions(String courseId) =>
      source.readQuestions(courseId);

  @override
  Future<List<Subject>> getAllSubjects() async =>
      (await source.readAllSubjects())
          .map((model) => model.toEntity())
          .toList(growable: false);

  @override
  Future<List<Subject>> getSubjectPage({
    required int page,
    required int perPage,
  }) async => (await source.readSubjectPage(
    page: page,
    perPage: perPage,
  )).map((model) => model.toEntity()).toList(growable: false);

  @override
  Future<Subject> getSubjectDetails(String id) async =>
      (await source.readSubjectDetails(id)).toEntity();
}
