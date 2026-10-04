import 'package:tamkeen2/features/assessments/domain/quiz_question.dart';
import 'package:tamkeen2/features/courses/presentation/widgets/course_cards.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/account/domain/account_models.dart';
import 'package:tamkeen2/features/account/domain/account_repository.dart';
import 'package:tamkeen2/features/account/presentation/account_common.dart';
import 'package:tamkeen2/features/account/presentation/account_cubit.dart';
import 'package:tamkeen2/features/auth/data/unavailable_auth_repository.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/domain/course_repository.dart';
import 'package:tamkeen2/features/courses/domain/get_courses.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';

class _Courses implements CourseRepository {
  @override
  Future<List<Course>> getCourses() async => [];
  @override
  Future<List<QuizQuestion>> getQuestions(String courseId) async => [];
}

class _PendingAccount implements AccountRepository {
  final pending = Completer<AccountData>();
  @override
  Future<AccountData> load(String userId) => pending.future;
  @override
  Future<AccountProfile> saveProfile(
    String userId,
    AccountProfile profile,
  ) async => profile;
  @override
  Future<AccountProfile> updateImage(
    String userId,
    Uint8List bytes,
    String filename,
    String? mimeType,
  ) async => throw UnimplementedError();
  @override
  Future<void> markNotificationRead(String userId, String id) async {}
  @override
  Future<ContactResult> submitContact(ContactMessage message) async =>
      const ContactResult(delivered: false, message: 'غير متاح');
}

void main() {
  testWidgets('catalog loading mirrors course card geometry', (tester) async {
    addTearDown(tester.view.reset);
    final repo = _Courses();
    final cubit = CourseCubit(GetCourses(repo), repo);
    addTearDown(cubit.close);
    for (final width in <double>[320, 360, 390, 430, 600, 768]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 932);
      await tester.pumpWidget(
        BlocProvider<CourseCubit>.value(
          value: cubit,
          child: MaterialApp(
            home: LoadingContent(
              state: const CourseState(status: LoadStatus.loading),
              child: const SizedBox(),
            ),
          ),
        ),
      );
      expect(find.byType(SkeletonBlock), findsAtLeastNWidgets(12));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('account loading mirrors profile rows', (tester) async {
    final repo = _PendingAccount();
    final account = AccountCubit(repo);
    final auth = AuthCubit(UnavailableAuthRepository());
    addTearDown(account.close);
    addTearDown(auth.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AccountCubit>.value(value: account),
          BlocProvider<AuthCubit>.value(value: auth),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AccountContent(builder: _loaded)),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(SkeletonBlock), findsAtLeastNWidgets(12));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('gallery and notifications use their own loading shapes', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    final repo = _PendingAccount();
    final account = AccountCubit(repo);
    final auth = AuthCubit(UnavailableAuthRepository());
    addTearDown(account.close);
    addTearDown(auth.close);
    Future<void> show(AccountSkeletonKind kind) => tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AccountCubit>.value(value: account),
          BlocProvider<AuthCubit>.value(value: auth),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AccountContent(
              key: ValueKey(kind),
              loadingKind: kind,
              builder: _loaded,
            ),
          ),
        ),
      ),
    );
    for (final width in <double>[320, 360, 390, 430, 600, 768]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 932);
      await show(AccountSkeletonKind.gallery);
      await tester.pump();
      expect(find.byType(GridView), findsOneWidget);
      expect(tester.takeException(), isNull);
      await show(AccountSkeletonKind.notifications);
      await tester.pump();
      expect(find.byType(GridView), findsNothing);
      expect(find.byType(SkeletonBlock), findsAtLeastNWidgets(15));
      expect(tester.takeException(), isNull);
    }
  });
}

Widget _loaded(BuildContext context, AccountState state) =>
    const Text('loaded');
