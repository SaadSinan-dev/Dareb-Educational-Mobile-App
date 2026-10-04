import 'package:tamkeen2/features/assessments/presentation/preview_quiz_cubit.dart';
import 'package:tamkeen2/features/home/presentation/home_cubit.dart';
import 'package:tamkeen2/features/search/presentation/search_cubit.dart';
import 'dart:async';

import 'package:tamkeen2/features/account/presentation/account_cubit.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';

/// Coordinates owner-scoped caches; widgets never orchestrate feature requests.
class AppSessionCoordinator {
  AppSessionCoordinator(
    AuthCubit auth,
    this.learning,
    this.account,
    this.home,
    this.search,
    this.quiz,
  ) {
    _subscription = auth.stream.listen(_sessionChanged);
  }
  final PreviewQuizCubit quiz;
  final HomeCubit home;
  final SearchCubit search;
  final CourseCubit learning;
  final AccountCubit account;
  late final StreamSubscription<AuthState> _subscription;
  String? _owner;
  int _generation = 0;
  bool _disposed = false;

  Future<void> _sessionChanged(AuthState state) async {
    final id = state.status == AuthStatus.loggingOut ? null : state.user?.id;
    if (id == _owner) return;
    final generation = ++_generation;
    _owner = id;
    quiz.reset();
    home.reset();
    search.reset();
    learning.reset();
    account.reset();
    if (id == null) return;
    await learning.setOwner(id);
    if (_disposed || generation != _generation) return;
    await Future.wait([learning.load(), account.load(id)]);
  }

  void dispose() {
    _disposed = true;
    ++_generation;
    unawaited(_subscription.cancel());
  }
}
