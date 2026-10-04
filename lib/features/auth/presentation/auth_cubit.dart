import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/features/auth/domain/auth_input.dart';
import 'package:tamkeen2/features/auth/domain/auth_repository.dart';
import 'package:tamkeen2/features/auth/domain/auth_user.dart';
import 'package:tamkeen2/features/auth/domain/registration_draft.dart';
import 'package:tamkeen2/features/auth/domain/registration_options.dart';

enum AuthStatus {
  initial,
  restoring,
  submitting,
  loggingOut,
  codeSent,
  authenticated,
  registrationSucceeded,
  registrationPending,
  failure,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.phone,
    this.registrationFlow = false,
  });

  final AuthStatus status;
  final AuthUser? user;
  final String? error;
  final String? phone;
  final bool registrationFlow;
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this.repository) : super(const AuthState());

  final AuthRepository repository;
  int _generation = 0;
  Future<void>? _sessionCheck;
  bool get _busy =>
      state.status == AuthStatus.submitting ||
      state.status == AuthStatus.restoring ||
      state.status == AuthStatus.loggingOut;

  Future<void> restore() async {
    if (isClosed || _busy) return;
    final operation = ++_generation;
    emit(const AuthState(status: AuthStatus.restoring));
    try {
      final user = await repository.restoreSession();
      if (!_current(operation)) return;
      emit(
        user == null
            ? const AuthState()
            : user.profileComplete
            ? AuthState(status: AuthStatus.authenticated, user: user)
            : AuthState(
                status: AuthStatus.registrationPending,
                phone: user.phone,
                registrationFlow: true,
              ),
      );
    } catch (error) {
      if (_current(operation)) {
        emit(AuthState(status: AuthStatus.failure, error: _safeError(error)));
      }
    }
  }

  /// Resume checks preserve the current destination while a valid session is
  /// revalidated. Missing/invalid credentials immediately revoke protected UI.
  Future<void> refreshSession() {
    final pending = _sessionCheck;
    if (pending != null) return pending;
    if (isClosed || _busy || state.user == null) return Future<void>.value();
    final check = _refreshSession().whenComplete(() => _sessionCheck = null);
    _sessionCheck = check;
    return check;
  }

  Future<void> _refreshSession() async {
    final operation = ++_generation;
    final previous = state;
    try {
      final user = await repository.restoreSession();
      if (!_current(operation)) return;
      emit(
        user == null
            ? const AuthState()
            : user.profileComplete
            ? AuthState(status: AuthStatus.authenticated, user: user)
            : AuthState(
                status: AuthStatus.registrationPending,
                phone: user.phone,
                registrationFlow: true,
              ),
      );
    } catch (error) {
      if (_current(operation)) {
        emit(
          AuthState(
            status: previous.status,
            user: previous.user,
            phone: previous.phone,
            error: _safeError(error),
          ),
        );
      }
    }
  }

  Future<void> requestCode(String input, {bool forRegistration = false}) async {
    if (isClosed || _busy) return;
    final phone = AuthInput.phone(input);
    if (phone == null) {
      emit(
        const AuthState(
          status: AuthStatus.failure,
          error: AppCopy.phoneLengthValidation,
        ),
      );
      return;
    }
    final operation = ++_generation;
    emit(
      AuthState(
        status: AuthStatus.submitting,
        phone: phone,
        registrationFlow: forRegistration,
      ),
    );
    try {
      await repository.requestCode(phone);
      if (_current(operation)) {
        emit(
          AuthState(
            status: AuthStatus.codeSent,
            phone: phone,
            registrationFlow: forRegistration,
          ),
        );
      }
    } catch (error) {
      if (_current(operation)) {
        emit(
          AuthState(
            status: AuthStatus.failure,
            phone: phone,
            registrationFlow: forRegistration,
            error: _safeError(error),
          ),
        );
      }
    }
  }

  Future<void> resendCode() async {
    if (isClosed || _busy) return;
    final phone = state.phone;
    final registrationFlow = state.registrationFlow;
    if (phone == null) {
      emit(
        const AuthState(
          status: AuthStatus.failure,
          error: AppCopy.phoneRequiredFirst,
        ),
      );
      return;
    }
    final operation = ++_generation;
    emit(
      AuthState(
        status: AuthStatus.submitting,
        phone: phone,
        registrationFlow: registrationFlow,
      ),
    );
    try {
      await repository.resendCode(phone);
      if (_current(operation)) {
        emit(
          AuthState(
            status: AuthStatus.codeSent,
            phone: phone,
            registrationFlow: registrationFlow,
          ),
        );
      }
    } catch (error) {
      if (_current(operation)) {
        emit(
          AuthState(
            status: AuthStatus.failure,
            phone: phone,
            registrationFlow: registrationFlow,
            error: _safeError(error),
          ),
        );
      }
    }
  }

  Future<void> verifyCode(String input) async {
    if (isClosed || _busy) return;
    final phone = state.phone;
    final registrationFlow = state.registrationFlow;
    final code = AuthInput.code(input);
    if (phone == null || code == null) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          phone: phone,
          registrationFlow: registrationFlow,
          error: AppCopy.verificationCodeLengthRequired,
        ),
      );
      return;
    }
    final operation = ++_generation;
    emit(
      AuthState(
        status: AuthStatus.submitting,
        phone: phone,
        registrationFlow: registrationFlow,
      ),
    );
    try {
      final user = await repository.verifyCode(phone, code);
      final completed = await repository.profileCompleted();
      if (_current(operation)) {
        emit(
          !completed
              ? AuthState(
                  status: AuthStatus.registrationPending,
                  phone: phone,
                  registrationFlow: true,
                )
              : AuthState(
                  status: AuthStatus.authenticated,
                  phone: phone,
                  user: user,
                ),
        );
      }
    } catch (error) {
      if (_current(operation)) {
        emit(
          AuthState(
            status: AuthStatus.failure,
            phone: phone,
            registrationFlow: registrationFlow,
            error: _safeError(error),
          ),
        );
      }
    }
  }

  Future<void> register(RegistrationDraft draft) async {
    if (isClosed || _busy) return;
    final error = draft.validationError;
    if (error != null) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          phone: state.phone,
          error: error,
          registrationFlow: state.registrationFlow,
        ),
      );
      return;
    }
    final operation = ++_generation;
    emit(
      AuthState(
        status: AuthStatus.submitting,
        phone: draft.phone,
        registrationFlow: true,
      ),
    );
    try {
      final user = await repository.register(
        draft.copyWith(phone: AuthInput.phone(draft.phone)),
      );
      if (_current(operation)) {
        emit(
          AuthState(
            status: AuthStatus.registrationSucceeded,
            user: user,
            phone: user.phone,
          ),
        );
      }
    } catch (error) {
      if (_current(operation)) {
        emit(
          AuthState(
            status: AuthStatus.failure,
            phone: draft.phone,
            registrationFlow: true,
            error: _safeError(error),
          ),
        );
      }
    }
  }

  Future<List<GovernorateOption>> governorates() => repository.governorates();
  Future<List<RegistrationOption>> branches() => repository.branches();
  Future<List<RegistrationOption>> schools({
    required int type,
    required String governorate,
  }) => repository.schools(type: type, governorate: governorate);

  Future<void> logout() async {
    if (isClosed || state.status == AuthStatus.loggingOut) return;
    final operation = ++_generation;
    emit(const AuthState(status: AuthStatus.loggingOut));
    try {
      await repository.logout();
      if (_current(operation)) emit(const AuthState());
    } catch (error) {
      if (_current(operation)) {
        emit(AuthState(status: AuthStatus.failure, error: _safeError(error)));
      }
    }
  }

  /// A rejected token is already revoked. Never send another authenticated
  /// logout request from the HTTP 401 handler or turn expiry into a retry error.
  void sessionExpired() {
    ++_generation;
    if (!isClosed) emit(const AuthState());
  }

  bool _current(int operation) => !isClosed && operation == _generation;

  String _safeError(Object error) =>
      error is AppFailure ? error.message : AppCopy.unexpectedClientError;

  @override
  Future<void> close() {
    ++_generation;
    return super.close();
  }
}
