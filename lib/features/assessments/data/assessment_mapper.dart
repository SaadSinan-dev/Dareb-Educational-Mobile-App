import 'package:tamkeen2/core/network/api_values.dart';
import 'package:tamkeen2/features/assessments/domain/assessment.dart';

abstract final class AssessmentMapper {
  static RemoteAssessment fromJson(Map<String, dynamic> data) =>
      RemoteAssessment(
        id: ApiValues.id(data['id']),
        title: ApiValues.text(data['title']),
        professor: ApiValues.optionalText(data['professor']),
        questions: List.unmodifiable(
          ApiValues.objects(data['questions'] ?? const []).map(
            (question) => RemoteQuestion(
              ApiValues.id(question['id']),
              ApiValues.text(question['title']),
              List.unmodifiable(
                ApiValues.objects(question['answers'] ?? const []).map(
                  (answer) => RemoteAnswer(
                    ApiValues.id(answer['id']),
                    ApiValues.text(answer['title']),
                    ApiValues.flag(answer['correct']),
                  ),
                ),
              ),
            ),
          ),
        ),
        correctAnswers: ApiValues.count(data['correct_answers']),
        failedAnswers: ApiValues.count(data['failed_answers']),
        questionCount: ApiValues.count(data['questions_count']),
        isFree: ApiValues.flag(data['is_free']),
        isSubscribed: ApiValues.flag(data['is_subscription']),
      );
}
