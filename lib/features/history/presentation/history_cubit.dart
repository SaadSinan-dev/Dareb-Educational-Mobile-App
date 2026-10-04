import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/features/assessments/domain/assessment.dart';
import 'package:tamkeen2/features/assessments/domain/assessment_repository.dart';
import 'package:tamkeen2/core/errors/failure_message.dart';
import 'package:tamkeen2/core/state/remote_status.dart';
export 'package:tamkeen2/core/state/remote_status.dart';

class HistoryState {
  const HistoryState({
    this.status = RemoteStatus.initial,
    this.data,
    this.error,
    this.activities = false,
  });
  final RemoteStatus status;
  final List<RemoteAssessment>? data;
  final String? error;
  final bool activities;
}

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this.repository) : super(const HistoryState());
  final AssessmentRepository repository;
  bool get activities => state.activities;
  int _request = 0;
  Future<void> load({bool? activities}) async {
    final same = activities == null || activities == this.activities;
    final selectedActivities = activities ?? this.activities;
    final request = ++_request;
    emit(
      HistoryState(
        status: RemoteStatus.loading,
        data: same ? state.data : null,
        activities: selectedActivities,
      ),
    );
    try {
      final records = await repository.history(activities: selectedActivities);
      if (!isClosed && request == _request) {
        emit(
          HistoryState(
            status: records.isEmpty ? RemoteStatus.empty : RemoteStatus.ready,
            data: records,
            activities: selectedActivities,
          ),
        );
      }
    } catch (error) {
      if (!isClosed && request == _request) {
        emit(
          HistoryState(
            status: RemoteStatus.failure,
            data: state.data,
            activities: selectedActivities,
            error: failureMessage(error),
          ),
        );
      }
    }
  }
}
