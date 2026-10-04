import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/features/account/domain/account_content.dart';
import 'package:tamkeen2/features/account/domain/account_content_repository.dart';

enum FaqStatus { initial, loading, ready, failure }

class FaqState {
  const FaqState({
    this.status = FaqStatus.initial,
    this.items = const [],
    this.error,
  });

  final FaqStatus status;
  final List<AccountFaq> items;
  final String? error;
}

class FaqCubit extends Cubit<FaqState> {
  FaqCubit(this.repository) : super(const FaqState());

  final AccountContentRepository repository;
  int _generation = 0;

  Future<void> load() async {
    if (isClosed || state.status == FaqStatus.loading) return;
    final operation = ++_generation;
    emit(const FaqState(status: FaqStatus.loading));
    try {
      final items = await repository.loadFaqs();
      if (!isClosed && operation == _generation) {
        emit(FaqState(status: FaqStatus.ready, items: items));
      }
    } catch (error) {
      if (!isClosed && operation == _generation) {
        emit(
          FaqState(
            status: FaqStatus.failure,
            error: error is AppFailure
                ? error.message
                : AppCopy.unexpectedClientError,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    ++_generation;
    return super.close();
  }
}
