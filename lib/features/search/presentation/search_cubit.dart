import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/validation/app_validators.dart';
import 'package:tamkeen2/features/search/domain/search_repository.dart';
import 'package:tamkeen2/features/search/domain/search_home.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';

enum SearchStatus { initial, loading, ready, empty, failure }

class SearchState {
  const SearchState({
    this.query = '',
    this.status = SearchStatus.initial,
    this.results,
    this.error,
  });
  final String query;
  final SearchStatus status;
  final HomeSearchResult? results;
  final String? error;
}

class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this.searchHome) : super(const SearchState());
  final SearchHome searchHome;
  Timer? _debounce;
  int _epoch = 0;

  void search(String value) {
    _debounce?.cancel();
    if (isClosed) return;
    final epoch = ++_epoch;
    if (!_prepare(value)) return;
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _fetch(value.trim(), epoch),
    );
  }

  Future<void> submit(String value) async {
    _debounce?.cancel();
    if (isClosed) return;
    final epoch = ++_epoch;
    if (_prepare(value)) await _fetch(value.trim(), epoch);
  }

  void retry() => submit(state.query);
  bool _prepare(String value) {
    final error = AppValidators.search(value);
    if (error != null) {
      emit(
        SearchState(query: value, status: SearchStatus.failure, error: error),
      );
      return false;
    }
    if (value.trim().isEmpty) {
      emit(SearchState(query: value));
      return false;
    }
    emit(SearchState(query: value, status: SearchStatus.loading));
    return true;
  }

  Future<void> _fetch(String query, int epoch) async {
    try {
      final results = await searchHome(query);
      if (isClosed || epoch != _epoch) return;
      emit(
        SearchState(
          query: state.query,
          results: results,
          status:
              results.subjects.isEmpty &&
                  results.exams.isEmpty &&
                  results.activities.isEmpty
              ? SearchStatus.empty
              : SearchStatus.ready,
        ),
      );
    } catch (error) {
      if (!isClosed && epoch == _epoch) {
        emit(
          SearchState(
            query: state.query,
            status: SearchStatus.failure,
            error: error is AppFailure
                ? error.message
                : AppCopy.unexpectedClientError,
          ),
        );
      }
    }
  }

  void reset() {
    ++_epoch;
    _debounce?.cancel();
    if (!isClosed) emit(const SearchState());
  }

  @override
  Future<void> close() {
    ++_epoch;
    _debounce?.cancel();
    return super.close();
  }
}
