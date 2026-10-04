import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/core/errors/failure_message.dart';
import 'package:tamkeen2/features/auth/domain/auth_repository.dart';
import 'package:tamkeen2/features/auth/domain/registration_options.dart';

class RegistrationOptionsState {
  const RegistrationOptionsState({
    this.governorates = const [],
    this.branches = const [],
    this.schools = const [],
    this.governorate,
    this.type,
    this.loading = false,
    this.loadingSchools = false,
    this.schoolLookupAttempted = false,
    this.error,
    this.schoolsError,
  });
  final List<GovernorateOption> governorates;
  final List<RegistrationOption> branches;
  final List<RegistrationOption> schools;
  final String? governorate;
  final int? type;
  final bool loading;
  final bool loadingSchools;
  final bool schoolLookupAttempted;
  final String? error;
  final String? schoolsError;
}

/// Owns dependent lookups and rejects results from superseded selections.
class RegistrationOptionsCubit extends Cubit<RegistrationOptionsState> {
  RegistrationOptionsCubit(this._repository)
    : super(const RegistrationOptionsState());
  final AuthRepository _repository;
  int _optionsEpoch = 0;
  int _schoolsEpoch = 0;

  RegistrationOptionsState _copy({
    List<GovernorateOption>? governorates,
    List<RegistrationOption>? branches,
    List<RegistrationOption>? schools,
    String? governorate,
    int? type,
    bool? loading,
    bool? loadingSchools,
    bool? attempted,
    String? error,
    String? schoolsError,
  }) => RegistrationOptionsState(
    governorates: governorates ?? state.governorates,
    branches: branches ?? state.branches,
    schools: schools ?? state.schools,
    governorate: governorate ?? state.governorate,
    type: type ?? state.type,
    loading: loading ?? state.loading,
    loadingSchools: loadingSchools ?? state.loadingSchools,
    schoolLookupAttempted: attempted ?? state.schoolLookupAttempted,
    error: error,
    schoolsError: schoolsError,
  );

  Future<void> load() async {
    if (isClosed || state.loading) return;
    final epoch = ++_optionsEpoch;
    emit(_copy(loading: true));
    try {
      // Typed futures execute concurrently without casting a heterogeneous list.
      late List<GovernorateOption> governors;
      late List<RegistrationOption> branches;
      await Future.wait<void>([
        _repository.governorates().then<void>((value) => governors = value),
        _repository.branches().then<void>((value) => branches = value),
      ]);
      if (isClosed || epoch != _optionsEpoch) return;
      final selected = governors.any((g) => g.key == state.governorate)
          ? state.governorate
          : governors.firstOrNull?.key;
      ++_schoolsEpoch;
      emit(
        _copy(
          governorates: List.unmodifiable(governors),
          branches: List.unmodifiable(branches),
          governorate: selected,
          schools: const [],
          loading: false,
          loadingSchools: false,
          attempted: false,
        ),
      );
      await loadSchools();
    } catch (error) {
      if (!isClosed && epoch == _optionsEpoch) {
        emit(_copy(loading: false, error: failureMessage(error)));
      }
    }
  }

  Future<void> select({String? governorate, int? type}) async {
    if (isClosed) return;
    ++_schoolsEpoch;
    emit(
      _copy(
        governorate: governorate,
        type: type,
        schools: const [],
        loadingSchools: false,
        attempted: false,
      ),
    );
    await loadSchools();
  }

  Future<void> loadSchools() async {
    final governorate = state.governorate;
    final type = state.type;
    if (isClosed || governorate == null || type == null) return;
    final epoch = ++_schoolsEpoch;
    emit(_copy(schools: const [], loadingSchools: true, attempted: true));
    try {
      final schools = await _repository.schools(
        type: type,
        governorate: governorate,
      );
      if (!isClosed && epoch == _schoolsEpoch) {
        emit(_copy(schools: List.unmodifiable(schools), loadingSchools: false));
      }
    } catch (error) {
      if (!isClosed && epoch == _schoolsEpoch) {
        emit(_copy(loadingSchools: false, schoolsError: failureMessage(error)));
      }
    }
  }

  @override
  Future<void> close() {
    ++_optionsEpoch;
    ++_schoolsEpoch;
    return super.close();
  }
}
