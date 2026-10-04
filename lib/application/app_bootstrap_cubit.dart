import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tamkeen2/core/preferences/app_preferences_cubit.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';

enum BootstrapStatus {
  initializing,
  authenticated,
  unauthenticated,
  sessionError,
}

class BootstrapState {
  const BootstrapState(this.status, {this.error});
  final BootstrapStatus status;
  final String? error;
  bool get resolved =>
      status == BootstrapStatus.authenticated ||
      status == BootstrapStatus.unauthenticated;
}

/// Resolves credentials and appearance before the application router exists.
class AppBootstrapCubit extends Cubit<BootstrapState> {
  AppBootstrapCubit(this.auth, this.preferences)
    : super(const BootstrapState(BootstrapStatus.initializing));
  final AuthCubit auth;
  final AppPreferencesCubit preferences;
  bool _running = false;

  Future<void> initialize() async {
    if (isClosed || _running) return;
    _running = true;
    emit(const BootstrapState(BootstrapStatus.initializing));
    await Future.wait([auth.restore(), preferences.restore()]);
    _running = false;
    if (isClosed) return;
    emit(
      auth.state.status == AuthStatus.failure
          ? BootstrapState(
              BootstrapStatus.sessionError,
              error: auth.state.error,
            )
          : BootstrapState(
              auth.state.user == null
                  ? BootstrapStatus.unauthenticated
                  : BootstrapStatus.authenticated,
            ),
    );
  }
}
