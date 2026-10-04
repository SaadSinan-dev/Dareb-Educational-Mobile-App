import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/features/assessments/domain/assessment.dart';
import 'package:tamkeen2/features/assessments/domain/assessment_repository.dart';
import 'package:tamkeen2/core/errors/failure_message.dart';
import 'package:tamkeen2/core/state/remote_status.dart';
export 'package:tamkeen2/core/state/remote_status.dart';

class ExamState {
  const ExamState({
    this.status = RemoteStatus.initial,
    this.data,
    this.error,
    this.busy = false,
    this.confirmed = false,
    this.answers = const {},
  });
  final RemoteStatus status;
  final RemoteAssessment? data;
  final String? error;
  final bool busy, confirmed;
  final Map<String, String> answers;
}

class ExamCubit extends Cubit<ExamState> {
  ExamCubit(this.repository) : super(const ExamState());
  final AssessmentRepository repository;
  int _request = 0;
  String? _examId;
  Future<void> load(String id, {RemoteAssessment? initial}) async {
    if (isClosed || state.busy) return;
    final sameExam = _examId == id;
    final request = ++_request;
    _examId = id;
    emit(
      ExamState(
        status: RemoteStatus.loading,
        data: initial ?? (sameExam ? state.data : null),
        confirmed: sameExam && state.confirmed,
        answers: sameExam ? state.answers : const {},
      ),
    );
    try {
      final record = await repository.result(id);
      if (!isClosed && request == _request) {
        emit(
          ExamState(
            status: record.questions.isEmpty
                ? RemoteStatus.empty
                : RemoteStatus.ready,
            data: record,
            confirmed: state.confirmed,
            answers: state.answers,
          ),
        );
      }
    } catch (error) {
      if (!isClosed && request == _request) {
        emit(
          ExamState(
            status: RemoteStatus.failure,
            data: state.data,
            error: failureMessage(error),
            confirmed: state.confirmed,
            answers: state.answers,
          ),
        );
      }
    }
  }

  void select(String questionId, String answerId) {
    if (isClosed || state.busy || state.confirmed) return;
    final questions = state.data?.questions ?? [];
    if (!questions.any(
      (q) => q.id == questionId && q.answers.any((a) => a.id == answerId),
    )) {
      return;
    }
    emit(
      ExamState(
        status: state.status,
        data: state.data,
        answers: Map.unmodifiable({...state.answers, questionId: answerId}),
      ),
    );
  }

  Future<bool> submit() async {
    final exam = state.data;
    if (isClosed ||
        state.busy ||
        state.confirmed ||
        exam == null ||
        exam.questions.isEmpty ||
        state.answers.length != exam.questions.length) {
      return false;
    }
    emit(
      ExamState(
        status: state.status,
        data: exam,
        busy: true,
        answers: state.answers,
      ),
    );
    try {
      await repository.submitAnswers(
        exam.questions.map((q) => state.answers[q.id]!).toList(),
      );
      if (isClosed) return true;
      emit(
        ExamState(
          status: RemoteStatus.ready,
          data: exam,
          confirmed: true,
          answers: state.answers,
        ),
      );
      await load(_examId!);
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          ExamState(
            status: RemoteStatus.failure,
            data: state.data,
            error: failureMessage(error),
            confirmed: state.confirmed,
            answers: state.answers,
          ),
        );
      }
      return false;
    }
  }
}
