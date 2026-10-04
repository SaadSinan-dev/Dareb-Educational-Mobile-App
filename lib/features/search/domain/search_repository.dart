import 'package:tamkeen2/features/courses/domain/subject.dart';
import 'package:tamkeen2/features/assessments/domain/assessment.dart';

class HomeSearchResult {
  const HomeSearchResult({
    required this.subjects,
    this.unsupportedExamResults = 0,
    this.unsupportedActivityResults = 0,
    this.exams = const [],
    this.activities = const [],
  });

  final List<Subject> subjects;
  final List<RemoteAssessment> exams, activities;

  /// Legacy counters retained for fixture compatibility; verified records are typed.
  final int unsupportedExamResults;
  final int unsupportedActivityResults;
}

abstract interface class SearchRepository {
  Future<HomeSearchResult> search(String text);
}
