import 'dart:typed_data';

import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/features/account/domain/account_models.dart';
import 'package:tamkeen2/features/account/domain/account_repository.dart';

enum AccountStatus { initial, loading, ready, failure }

enum AccountActionStatus { idle, submitting, preview, success, failure }

class AccountState {
  const AccountState({
    this.status = AccountStatus.initial,
    this.data = const AccountData(),
    this.error,
    this.actionStatus = AccountActionStatus.idle,
    this.actionMessage,
  });
  final AccountStatus status;
  final AccountData data;
  final String? error;
  final AccountActionStatus actionStatus;
  final String? actionMessage;

  AccountState copyWith({
    AccountStatus? status,
    AccountData? data,
    String? error,
    AccountActionStatus? actionStatus,
    String? actionMessage,
  }) => AccountState(
    status: status ?? this.status,
    data: data ?? this.data,
    error: error,
    actionStatus: actionStatus ?? this.actionStatus,
    actionMessage: actionMessage,
  );
}

class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this.repository) : super(const AccountState());
  final AccountRepository repository;
  int _generation = 0;
  String? _loadedUserId;

  bool _current(int operation) => !isClosed && operation == _generation;
  String _safeError(Object error) =>
      error is AppFailure ? error.message : AppCopy.unexpectedClientError;

  Future<void> load(String userId) async {
    if (isClosed ||
        userId.isEmpty ||
        (state.status == AccountStatus.loading && _loadedUserId == userId)) {
      return;
    }
    final operation = ++_generation;
    _loadedUserId = userId;
    emit(const AccountState(status: AccountStatus.loading));
    try {
      final data = await repository.load(userId);
      if (_current(operation)) {
        emit(AccountState(status: AccountStatus.ready, data: data.immutable));
      }
    } catch (error) {
      if (_current(operation)) {
        emit(
          AccountState(status: AccountStatus.failure, error: _safeError(error)),
        );
      }
    }
  }

  Future<void> saveProfile(String userId, AccountProfile profile) async {
    if (isClosed || state.actionStatus == AccountActionStatus.submitting) {
      return;
    }
    final validation = profile.validationError;
    if (validation != null) {
      emit(
        state.copyWith(
          actionStatus: AccountActionStatus.failure,
          actionMessage: validation,
        ),
      );
      return;
    }
    final operation = ++_generation;
    emit(state.copyWith(actionStatus: AccountActionStatus.submitting));
    try {
      final saved = await repository.saveProfile(userId, profile);
      if (_current(operation)) {
        emit(
          state.copyWith(
            data: state.data.copyWith(profile: saved).immutable,
            actionStatus: AccountActionStatus.success,
            actionMessage: state.data.preview
                ? AppCopy.previewDataSavedLocally
                : AppCopy.profileUpdatedMessage,
          ),
        );
      }
    } catch (error) {
      if (_current(operation)) {
        emit(
          state.copyWith(
            actionStatus: AccountActionStatus.failure,
            actionMessage: _safeError(error),
          ),
        );
      }
    }
  }

  Future<void> updateImage(
    String userId,
    Uint8List bytes,
    String filename,
    String? mimeType,
  ) async {
    if (isClosed || state.actionStatus == AccountActionStatus.submitting) {
      return;
    }
    final operation = ++_generation;
    emit(state.copyWith(actionStatus: AccountActionStatus.submitting));
    try {
      final profile = await repository.updateImage(
        userId,
        bytes,
        filename,
        mimeType,
      );
      if (_current(operation)) {
        emit(
          state.copyWith(
            data: state.data.copyWith(profile: profile).immutable,
            actionStatus: AccountActionStatus.success,
            actionMessage: AppCopy.profileUpdatedMessage,
          ),
        );
      }
    } catch (error) {
      if (_current(operation)) {
        emit(
          state.copyWith(
            actionStatus: AccountActionStatus.failure,
            actionMessage: _safeError(error),
          ),
        );
      }
    }
  }

  Future<void> markNotificationRead(String userId, String id) async {
    if (isClosed || state.data.readNotificationIds.contains(id)) return;
    final operation = _generation;
    try {
      await repository.markNotificationRead(userId, id);
      if (_current(operation)) {
        emit(
          state.copyWith(
            data: state.data
                .copyWith(
                  readNotificationIds: {...state.data.readNotificationIds, id},
                )
                .immutable,
          ),
        );
      }
    } catch (error) {
      if (_current(operation)) emit(state.copyWith(error: _safeError(error)));
    }
  }

  void clearAction() {
    if (isClosed) return;
    emit(state.copyWith(actionStatus: AccountActionStatus.idle));
  }

  void reset() {
    if (isClosed) return;
    ++_generation;
    _loadedUserId = null;
    emit(const AccountState());
  }

  @override
  Future<void> close() {
    ++_generation;
    return super.close();
  }
}
