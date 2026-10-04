import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/features/courses/data/course_data_source.dart';
import 'package:tamkeen2/features/courses/data/course_repository_impl.dart';
import 'package:tamkeen2/features/courses/domain/get_courses.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';
import 'package:tamkeen2/features/subscriptions/presentation/screens/plans_page.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';

void main() {
  Future<void> openDetails(
    WidgetTester tester, {
    required bool demoMode,
  }) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = CourseRepositoryImpl(const MockCourseDataSource());
    final cubit = CourseCubit(
      GetCourses(repository),
      repository,
      demoMode: demoMode,
    );
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const PlansPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.detailsLabel).first);
    await tester.pumpAndSettle();
  }

  testWidgets('preview plan details show scrollable illustrative rows', (
    tester,
  ) async {
    await openDetails(tester, demoMode: true);

    final grid = tester.widget<GridView>(
      find.byKey(const Key('preview-plan-subject-grid')),
    );
    expect(grid.controller!.position.maxScrollExtent, greaterThan(0));
    expect(find.byKey(const Key('preview-plan-subject-0')), findsOneWidget);
    expect(find.byKey(const Key('preview-plan-subject-9')), findsNothing);

    await tester.drag(
      find.byKey(const Key('preview-plan-subject-grid')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('preview-plan-subject-9')), findsOneWidget);
  });

  testWidgets(
    'normal plan details do not infer package contents from courses',
    (tester) async {
      await openDetails(tester, demoMode: false);

      expect(find.byKey(const Key('preview-plan-subject-grid')), findsNothing);
      expect(find.text(AppCopy.serviceCurrentlyUnavailable), findsOneWidget);
    },
  );
}
