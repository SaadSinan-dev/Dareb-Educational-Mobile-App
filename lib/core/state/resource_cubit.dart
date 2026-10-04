import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';

enum ResourceStatus { loading, ready, failure }

class ResourceState<T> {
  const ResourceState({
    this.status = ResourceStatus.loading,
    this.data,
    this.error,
  });
  final ResourceStatus status;
  final T? data;
  final String? error;
}

/// Shared request lifecycle: retry, safe errors and stale response protection.
abstract class ResourceCubit<T> extends Cubit<ResourceState<T>> {
  ResourceCubit() : super(const ResourceState());
  int _epoch = 0;
  void reset() {
    ++_epoch;
    if (!isClosed) emit(const ResourceState());
  }

  Future<T> fetch();
  Future<void> load() async {
    if (isClosed) return;
    final epoch = ++_epoch;
    emit(ResourceState(status: ResourceStatus.loading, data: state.data));
    try {
      final data = await fetch();
      if (!isClosed && epoch == _epoch) {
        emit(ResourceState(status: ResourceStatus.ready, data: data));
      }
    } catch (error) {
      if (!isClosed && epoch == _epoch) {
        emit(
          ResourceState(
            status: ResourceStatus.failure,
            data: state.data,
            error: error is AppFailure
                ? error.message
                : AppCopy.unexpectedClientError,
          ),
        );
      }
    }
  }
}
