import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/core/errors/failure_message.dart';
import 'package:tamkeen2/features/assessments/domain/preview_quiz_repository.dart';
import 'package:tamkeen2/features/assessments/domain/quiz_question.dart';

enum QuizStatus { initial, loading, ready, failure }

class PreviewQuizState {
  const PreviewQuizState({
    this.questions = const [],
    this.quizStatus = QuizStatus.initial,
    this.questionIndex = 0,
    this.selectedAnswer,
    this.score = 0,
    this.quizAnswers = const {},
    this.quizSubmitted = false,
    this.operationError,
  });
  final List<QuizQuestion> questions;
  final QuizStatus quizStatus;
  final int questionIndex, score;
  final int? selectedAnswer;
  final Map<int, int> quizAnswers;
  final bool quizSubmitted;
  final String? operationError;
  PreviewQuizState copyWith({
    List<QuizQuestion>? questions,
    QuizStatus? quizStatus,
    int? questionIndex,
    int? selectedAnswer,
    bool clearAnswer = false,
    int? score,
    Map<int, int>? quizAnswers,
    bool? quizSubmitted,
    String? operationError,
  }) => PreviewQuizState(
    questions: List.unmodifiable(questions ?? this.questions),
    quizStatus: quizStatus ?? this.quizStatus,
    questionIndex: questionIndex ?? this.questionIndex,
    selectedAnswer: clearAnswer ? null : selectedAnswer ?? this.selectedAnswer,
    score: score ?? this.score,
    quizAnswers: Map.unmodifiable(quizAnswers ?? this.quizAnswers),
    quizSubmitted: quizSubmitted ?? this.quizSubmitted,
    operationError: operationError,
  );
}

/// Preview-only assessment state; production exams use ExamCubit and real IDs.
class PreviewQuizCubit extends Cubit<PreviewQuizState> {
  PreviewQuizCubit(this.repository) : super(const PreviewQuizState());
  final PreviewQuizRepository repository;
  int _request = 0;
  void reset() {
    ++_request;
    if (!isClosed) emit(const PreviewQuizState());
  }

  Future<void> startQuiz(String courseId) async {
    if (isClosed) return;
    final request = ++_request;
    emit(const PreviewQuizState(quizStatus: QuizStatus.loading));
    try {
      final questions = await repository.getQuestions(courseId);
      if (isClosed || request != _request) return;
      final valid =
          questions.isNotEmpty &&
          questions.every(
            (q) =>
                q.answers.isNotEmpty &&
                q.correctIndex >= 0 &&
                q.correctIndex < q.answers.length,
          );
      emit(
        PreviewQuizState(
          quizStatus: valid ? QuizStatus.ready : QuizStatus.failure,
          questions: valid ? List.unmodifiable(questions) : const [],
        ),
      );
    } catch (error) {
      if (!isClosed && request == _request) {
        emit(
          PreviewQuizState(
            quizStatus: QuizStatus.failure,
            operationError: failureMessage(error),
          ),
        );
      }
    }
  }

  bool _validAnswer(int question, int answer) =>
      !isClosed &&
      state.quizStatus == QuizStatus.ready &&
      !state.quizSubmitted &&
      question >= 0 &&
      question < state.questions.length &&
      answer >= 0 &&
      answer < state.questions[question].answers.length;
  void selectAnswer(int index) {
    if (_validAnswer(state.questionIndex, index)) {
      emit(state.copyWith(selectedAnswer: index));
    }
  }

  void answerQuestion(int question, int answer) {
    if (_validAnswer(question, answer)) {
      emit(
        state.copyWith(quizAnswers: {...state.quizAnswers, question: answer}),
      );
    }
  }

  bool submitQuiz() {
    if (isClosed ||
        state.quizSubmitted ||
        state.quizStatus != QuizStatus.ready ||
        state.quizAnswers.length != state.questions.length) {
      return false;
    }
    final score = state.quizAnswers.entries
        .where((e) => e.value == state.questions[e.key].correctIndex)
        .length;
    emit(
      state.copyWith(
        quizSubmitted: true,
        score: score,
        questionIndex: state.questions.length,
        clearAnswer: true,
      ),
    );
    return true;
  }

  bool nextQuestion() {
    final answer = state.selectedAnswer;
    if (answer == null || !_validAnswer(state.questionIndex, answer)) {
      return false;
    }
    final index = state.questionIndex;
    final finished = index + 1 == state.questions.length;
    emit(
      state.copyWith(
        quizAnswers: {...state.quizAnswers, index: answer},
        score:
            state.score +
            (state.questions[index].correctIndex == answer ? 1 : 0),
        questionIndex: index + 1,
        clearAnswer: true,
        quizSubmitted: finished,
      ),
    );
    return finished;
  }
}
