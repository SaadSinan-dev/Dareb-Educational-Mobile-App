import 'package:tamkeen2/features/courses/domain/subject.dart';

abstract interface class SubjectRepository {
  Future<List<Subject>> getAllSubjects();
  Future<List<Subject>> getSubjectPage({
    required int page,
    required int perPage,
  });
  Future<Subject> getSubjectDetails(String id);
}
