import 'package:tamkeen2/features/assessments/domain/quiz_question.dart';
import 'package:tamkeen2/features/lessons/domain/lesson.dart';
import 'package:tamkeen2/features/lessons/domain/lesson_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/theme/app_theme.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/domain/course_repository.dart';
import 'package:tamkeen2/features/courses/domain/get_courses.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';
import 'package:tamkeen2/features/courses/presentation/screens/detail_page.dart';
import 'package:tamkeen2/features/lessons/presentation/screens/lesson_page.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';

void main() {
  Future<void> render(
    WidgetTester tester,
    Widget page, {
    String? imageUrl,
    ThemeData? theme,
  }) async {
    final repository = _StaticRepository(
      Course(
        id: '5',
        title: 'Live course',
        category: 'Live subject',
        teacher: 'Teacher',
        description: 'Live description',
        lessons: const [
          Lesson(
            title: 'Real exam',
            minutes: 0,
            kind: LessonKind.exam,
            id: '25',
            isFree: true,
          ),
          Lesson(
            title: 'Real video',
            minutes: 0,
            kind: LessonKind.video,
            id: '30',
            durationText: '17:13:26',
            isFree: true,
          ),
        ],
        isFree: false,
        price: 54,
        accent: 0,
        imageUrl: imageUrl,
      ),
    );
    final cubit = CourseCubit(GetCourses(repository), repository);
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: RepositoryProvider<LessonRepository>.value(
          value: _Lessons(),
          child: BlocProvider.value(value: cubit, child: page),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'live detail shows exam and exact server time without fake minutes',
    (tester) async {
      await render(tester, const DetailPage(courseId: '5'));
      await tester.scrollUntilVisible(find.text('Real exam'), 300);
      expect(find.text('Real exam'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('17:13:26'), 200);
      expect(find.text('17:13:26'), findsOneWidget);
      expect(find.text('0 دقيقة'), findsNothing);
      expect(find.byIcon(Icons.quiz_outlined), findsWidgets);
    },
  );

  testWidgets(
    'direct exam lesson reports the observed missing exam without video UI',
    (tester) async {
      await render(tester, const LessonPage(courseId: '5', index: 0));
      expect(find.text(AppCopy.examMissing), findsOneWidget);
      expect(find.text(AppCopy.videoPlaybackUnavailable), findsNothing);
      expect(find.byIcon(Icons.videocam_off_outlined), findsNothing);
    },
  );

  testWidgets('live detail uses theme color and verified remote image', (
    tester,
  ) async {
    await render(
      tester,
      const DetailPage(courseId: '5'),
      imageUrl: 'https://example.test/course.png',
      theme: AppTheme.dark,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url ==
                'https://example.test/course.png',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color ==
                AppPalette.dark.primary,
      ),
      findsWidgets,
    );
  });
}

class _StaticRepository implements CourseRepository {
  const _StaticRepository(this.course);
  final Course course;

  @override
  Future<List<Course>> getCourses() async => [course];

  @override
  Future<List<QuizQuestion>> getQuestions(String courseId) async =>
      throw const AppFailure.unavailable();
}

class _Lessons implements LessonRepository {
  @override
  Future<RemoteLesson> lesson(String id) async => RemoteLesson(
    id: id,
    title: 'Real exam',
    kind: LessonKind.exam,
    semesterId: '1',
    isAttended: false,
    hasAccess: true,
  );
  @override
  Future<List<RemoteComment>> comments(String id) async => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
