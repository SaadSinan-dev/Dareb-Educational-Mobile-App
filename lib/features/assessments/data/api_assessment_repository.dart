import 'package:dio/dio.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/features/assessments/domain/assessment.dart';
import 'package:tamkeen2/features/assessments/domain/assessment_repository.dart';
import 'package:tamkeen2/core/network/api_values.dart';
import 'package:tamkeen2/features/assessments/data/assessment_mapper.dart';

class ApiAssessmentRepository implements AssessmentRepository {
  const ApiAssessmentRepository(this.client);
  final ApiClient client;
  Future<Object?> _get(String path, [Map<String, dynamic>? query]) async {
    final response = await client.request<Object?>(
      path,
      queryParameters: query,
    );
    final root = ApiValues.object(response.data);
    if (!root.containsKey('data')) {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: root);
    }
    return root['data'];
  }

  Future<void> _post(String path, FormData form) async {
    await client.request<Object?>(path, method: 'POST', data: form);
  }

  @override
  Future<List<RemoteAssessment>> history({required bool activities}) async =>
      List.unmodifiable(
        ApiValues.objects(
          await _get(activities ? 'daily-activities/my' : 'exams/my'),
        ).map(AssessmentMapper.fromJson),
      );
  @override
  Future<RemoteAssessment> result(String examId) async =>
      AssessmentMapper.fromJson(
        ApiValues.object(
          await _get('exams/result', {'id': ApiValues.requestId(examId)}),
        ),
      );
  @override
  Future<void> submitAnswers(List<String> ids) async {
    if (ids.isEmpty || ids.toSet().length != ids.length) {
      throw const AppFailure(AppCopy.requestValidationFailed);
    }
    final form = FormData();
    for (final answerId in ids) {
      form.fields.add(
        MapEntry('answers_id[]', '${ApiValues.requestId(answerId)}'),
      );
    }
    await _post('exams/attend-exam', form);
  }
}
