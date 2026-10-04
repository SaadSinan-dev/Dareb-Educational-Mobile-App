import 'package:tamkeen2/features/assessments/domain/assessment.dart';

abstract interface class AssessmentRepository {
  Future<List<RemoteAssessment>> history({required bool activities});
  Future<RemoteAssessment> result(String id);
  Future<void> submitAnswers(List<String> ids);
}
