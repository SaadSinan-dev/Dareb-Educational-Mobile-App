import 'quiz_question.dart';

abstract interface class PreviewQuizRepository {
  Future<List<QuizQuestion>> getQuestions(String courseId);
}
