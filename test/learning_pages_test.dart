import 'package:tamkeen2/features/assessments/presentation/preview_quiz_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/features/courses/data/course_data_source.dart';
import 'package:tamkeen2/features/courses/data/course_repository_impl.dart';
import 'package:tamkeen2/features/courses/domain/get_courses.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';
import 'package:tamkeen2/features/courses/presentation/screens/my_learning_page.dart';
import 'package:tamkeen2/features/lessons/presentation/screens/lesson_page.dart';
import 'package:tamkeen2/features/assessments/presentation/screens/quiz_page.dart';

void main() {
  Future<CourseCubit> render(WidgetTester tester, Widget page) async {
    final repo = CourseRepositoryImpl(const MockCourseDataSource());
    final cubit = CourseCubit(GetCourses(repo), repo, demoMode: true);
    final quiz = PreviewQuizCubit(repo);
    addTearDown(quiz.close);
    await cubit.load();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider.value(value: quiz),
          ],
          child: Directionality(textDirection: TextDirection.rtl, child: page),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('lesson shows unavailable media and preview progress honestly', (
    tester,
  ) async {
    final cubit = await render(
      tester,
      const LessonPage(courseId: 'math', index: 0),
    );
    expect(find.text('تشغيل الفيديو غير متاح حالياً'), findsOneWidget);
    await tester.ensureVisible(find.text('تسجيل إكمال الدرس للمعاينة'));
    await tester.tap(find.text('تسجيل إكمال الدرس للمعاينة'));
    await tester.pumpAndSettle();
    expect(cubit.state.completedLessonIds, contains('math:0'));
  });
  testWidgets('whole quiz keeps result disabled until all questions answered', (
    tester,
  ) async {
    await render(tester, const QuizPage(courseId: 'math'));
    final cubit = tester
        .element(find.byType(QuizPage))
        .read<PreviewQuizCubit>();
    final result = find.widgetWithText(FilledButton, 'النتيجة');
    await tester.scrollUntilVisible(result, 350);
    expect(tester.widget<FilledButton>(result).onPressed, isNull);
    cubit.answerQuestion(0, 0);
    cubit.answerQuestion(1, 1);
    await tester.pumpAndSettle();
    await tester.ensureVisible(result);
    await tester.tap(result);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('50%'), -350);
    expect(find.text('50%'), findsOneWidget);
    expect(cubit.state.quizSubmitted, isTrue);
  });
  testWidgets('my learning switches between materials chapters and plans', (
    tester,
  ) async {
    await render(tester, const MyLearningPage());
    await tester.tap(find.text('الفصول'));
    await tester.pumpAndSettle();
    expect(find.text('الفصل 1'), findsWidgets);
    await tester.tap(find.text('الباقات'));
    await tester.pumpAndSettle();
    expect(find.text('استعراض الاشتراكات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
