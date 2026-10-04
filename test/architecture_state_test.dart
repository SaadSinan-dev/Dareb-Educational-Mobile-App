import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/features/auth/domain/auth_repository.dart';
import 'package:tamkeen2/features/auth/domain/auth_user.dart';
import 'package:tamkeen2/features/auth/domain/registration_options.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/auth/presentation/registration_options_cubit.dart';
import 'package:tamkeen2/features/assessments/domain/assessment.dart';
import 'package:tamkeen2/features/assessments/domain/assessment_repository.dart';
import 'package:tamkeen2/features/assessments/presentation/exam_cubit.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/lessons/domain/lesson.dart';
import 'package:tamkeen2/features/lessons/domain/lesson_repository.dart';
import 'package:tamkeen2/features/lessons/presentation/lesson_cubit.dart';

const _user = AuthUser(id: 'qa', phone: '0912345678');

class _Auth implements AuthRepository {
  Future<AuthUser?> Function() session = () async => _user;
  final lookups = <String, Completer<List<RegistrationOption>>>{};
  @override
  Future<AuthUser?> restoreSession() => session();
  @override
  Future<void> logout() async {}
  @override
  Future<List<GovernorateOption>> governorates() async => const [
    GovernorateOption(key: 'one', name: 'One'),
    GovernorateOption(key: 'two', name: 'Two'),
  ];
  @override
  Future<List<RegistrationOption>> branches() async => const [];
  @override
  Future<List<RegistrationOption>> schools({
    required int type,
    required String governorate,
  }) =>
      (lookups['$governorate/$type'] ??= Completer<List<RegistrationOption>>())
          .future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Lessons implements LessonRepository {
  int attendance = 0, last = 0;
  bool failLast = true;
  final lookups = <Completer<List<RemoteComment>>>[];
  @override
  Future<RemoteLesson> lesson(String id) async => RemoteLesson(
    id: id,
    title: 'Lesson',
    kind: LessonKind.video,
    semesterId: '1',
    isAttended: false,
    hasAccess: true,
  );
  @override
  Future<List<RemoteComment>> comments(String id) {
    final result = Completer<List<RemoteComment>>();
    lookups.add(result);
    return result.future;
  }

  @override
  Future<void> attendLesson(String id) async {
    attendance++;
  }

  @override
  Future<void> lastAttended(String id) async {
    last++;
    if (failLast) throw const AppFailure('Refresh failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Exams implements AssessmentRepository {
  @override
  Future<RemoteAssessment> result(String id) async => RemoteAssessment(
    id: id,
    title: id,
    questions: const [
      RemoteQuestion('q', 'Question', [RemoteAnswer('a', 'A', true)]),
    ],
  );
  @override
  Future<void> submitAnswers(List<String> ids) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'resume retains the authenticated destination and coalesces checks',
    () async {
      final repository = _Auth();
      final cubit = AuthCubit(repository);
      addTearDown(cubit.close);
      await cubit.restore();
      final pending = Completer<AuthUser?>();
      int requests = 0;
      repository.session = () {
        requests++;
        return pending.future;
      };
      final statuses = <AuthStatus>[];
      final subscription = cubit.stream.listen((s) => statuses.add(s.status));
      final check = cubit.refreshSession();
      bool secondFinished = false;
      final second = cubit.refreshSession().then((_) => secondFinished = true);
      await Future<void>.value();
      expect(secondFinished, isFalse);
      expect(cubit.state.user, _user);
      expect(requests, 1);
      pending.complete(_user);
      await check;
      await second;
      expect(secondFinished, isTrue);
      expect(statuses, isNot(contains(AuthStatus.restoring)));
      expect(cubit.state.status, AuthStatus.authenticated);
      await subscription.cancel();
    },
  );
  test(
    'removed credentials revoke the authenticated destination on resume',
    () async {
      final repository = _Auth();
      final cubit = AuthCubit(repository);
      addTearDown(cubit.close);
      await cubit.restore();
      repository.session = () async => null;
      await cubit.refreshSession();
      expect(cubit.state.user, isNull);
      expect(cubit.state.status, AuthStatus.initial);
    },
  );
  test(
    'resume transport failure preserves the session and its specific error',
    () async {
      final repository = _Auth();
      final cubit = AuthCubit(repository);
      addTearDown(cubit.close);
      await cubit.restore();
      repository.session = () async => throw const AppFailure('Offline');
      await cubit.refreshSession();
      expect(cubit.state.user, _user);
      expect(cubit.state.error, 'Offline');
    },
  );
  test('late resume result cannot restore a logged-out user', () async {
    final repository = _Auth();
    final cubit = AuthCubit(repository);
    addTearDown(cubit.close);
    await cubit.restore();
    final pending = Completer<AuthUser?>();
    repository.session = () => pending.future;
    final check = cubit.refreshSession();
    await cubit.logout();
    pending.complete(_user);
    await check;
    expect(cubit.state.user, isNull);
  });
  test('new governorate wins over an older school response', () async {
    final repository = _Auth();
    final cubit = RegistrationOptionsCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();
    final older = cubit.select(type: 1);
    final newer = cubit.select(governorate: 'two');
    repository.lookups['two/1']!.complete(const [
      RegistrationOption(id: 2, name: 'New'),
    ]);
    await newer;
    repository.lookups['one/1']!.complete(const [
      RegistrationOption(id: 1, name: 'Old'),
    ]);
    await older;
    expect(cubit.state.schools.single.id, 2);
    expect(() => cubit.state.schools.clear(), throwsUnsupportedError);
  });
  test(
    'new exam clears the previous selection and submission confirmation',
    () async {
      final cubit = ExamCubit(_Exams());
      addTearDown(cubit.close);
      await cubit.load('1');
      cubit.select('q', 'a');
      expect(await cubit.submit(), isTrue);
      await cubit.load('2');
      expect(cubit.state.answers, isEmpty);
      expect(cubit.state.confirmed, isFalse);
      expect(cubit.state.data!.id, '2');
    },
  );
  test(
    'attendance retry refreshes history without reposting confirmed attendance',
    () async {
      final repository = _Lessons();
      final cubit = LessonCubit(repository, '9');
      addTearDown(cubit.close);
      final loading = cubit.load();
      await Future<void>.delayed(Duration.zero);
      repository.lookups.single.complete(const []);
      await loading;
      await cubit.attend();
      expect(cubit.state.attended, isTrue);
      expect(cubit.state.lastPending, isTrue);
      repository.failLast = false;
      await cubit.attend();
      expect(repository.attendance, 1);
      expect(repository.last, 2);
      expect(cubit.state.lastPending, isFalse);
    },
  );
  test('older comments cannot overwrite a newer result', () async {
    final repository = _Lessons();
    final cubit = LessonCubit(repository, '9');
    addTearDown(cubit.close);
    final older = cubit.loadComments();
    final newer = cubit.loadComments();
    repository.lookups[1].complete(const [RemoteComment(id: '2', text: 'New')]);
    await newer;
    repository.lookups[0].complete(const [RemoteComment(id: '1', text: 'Old')]);
    await older;
    expect(cubit.state.comments.single.id, '2');
  });
}
