import 'package:tamkeen2/features/assessments/domain/quiz_question.dart';
import 'package:tamkeen2/features/home/presentation/home_cubit.dart';
import 'package:tamkeen2/features/search/presentation/search_cubit.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/domain/course_repository.dart';
import 'package:tamkeen2/features/courses/domain/get_courses.dart';
import 'package:tamkeen2/features/home/domain/home_repository.dart';
import 'package:tamkeen2/features/search/domain/search_repository.dart';
import 'package:tamkeen2/features/home/domain/get_home_overview.dart';
import 'package:tamkeen2/features/search/domain/search_home.dart';
import 'package:tamkeen2/features/courses/domain/subject.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';
import 'package:tamkeen2/features/courses/presentation/widgets/category_grid.dart';
import 'package:tamkeen2/features/home/presentation/screens/home_page.dart';
import 'package:tamkeen2/features/search/presentation/screens/search_page.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';

void main() {
  final course = Course(
    id: '15',
    title: 'Live history course',
    category: 'History',
    teacher: 'Teacher',
    description: '',
    lessons: const [],
    isFree: true,
    price: 0,
    accent: 0,
  );
  const subject = Subject(
    id: '15',
    name: 'History',
    isFree: true,
    isSubscribed: false,
  );
  const overview = HomeOverview(
    sliders: [
      HomeMedia(
        id: '1',
        imageUrl: 'https://example.test/slider.png',
        destinationUrl: 'https://example.test/course',
      ),
    ],
    news: [],
    subjects: [subject],
    featuredCourseIds: ['15'],
    completionRate: 23,
    unreadNotifications: 0,
    subjectCount: 1,
  );

  CourseCubit makeCubit(HomeRepository home) {
    final catalog = _StaticCatalog(course);
    return CourseCubit(GetCourses(catalog), catalog);
  }

  test(
    'home response and search response remain separate typed states',
    () async {
      final home = _FakeHome(overview);
      final cubit = makeCubit(home);
      final homeCubit = HomeCubit(GetHomeOverview(home));
      final searchCubit = SearchCubit(SearchHome(home));
      addTearDown(homeCubit.close);
      addTearDown(searchCubit.close);
      addTearDown(cubit.close);
      await cubit.load();
      await homeCubit.load();
      await homeCubit.load();
      expect(home.homeCalls, 1);
      expect(homeCubit.state.data?.featuredCourseIds, ['15']);

      searchCubit.search('History');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(home.queries, ['History']);
      expect(searchCubit.state.status, SearchStatus.ready);
      expect(searchCubit.state.results?.subjects.single.id, '15');
      expect(searchCubit.state.results?.unsupportedExamResults, 0);
      searchCubit.search('');
      expect(searchCubit.state.results, isNull);
    },
  );

  test('late search result cannot replace a newer query', () async {
    final home = _DelayedHome(overview);
    final cubit = SearchCubit(SearchHome(home));
    addTearDown(cubit.close);
    cubit.search('old');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    cubit.search('new');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    home.searches['new']!.complete(
      const HomeSearchResult(
        subjects: [subject],
        unsupportedExamResults: 0,
        unsupportedActivityResults: 0,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    home.searches['old']!.complete(
      const HomeSearchResult(
        subjects: [],
        unsupportedExamResults: 0,
        unsupportedActivityResults: 0,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.query, 'new');
    expect(cubit.state.results?.subjects.single.id, '15');
  });

  testWidgets('normal home uses public subjects and featured courses', (
    tester,
  ) async {
    final repository = _FakeHome(overview);
    final cubit = makeCubit(repository);
    final homeCubit = HomeCubit(GetHomeOverview(repository));
    final searchCubit = SearchCubit(SearchHome(repository));
    addTearDown(homeCubit.close);
    addTearDown(searchCubit.close);
    addTearDown(cubit.close);
    await cubit.load();
    await homeCubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider.value(value: homeCubit),
            BlocProvider.value(value: searchCubit),
          ],
          child: const HomePage(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('23%'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(CategoryGrid),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: find.byType(CategoryGrid),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SingleChildScrollView &&
              widget.scrollDirection == Axis.horizontal,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(AppCopy.excellenceStartsHere), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url.contains('slider.png'),
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/illustrations/graduates.png',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Live history course'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Live history course'), findsWidgets);
    expect(find.text('History'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('normal search shows only public subject matches', (
    tester,
  ) async {
    final repository = _FakeHome(overview);
    final cubit = makeCubit(repository);
    final homeCubit = HomeCubit(GetHomeOverview(repository));
    final searchCubit = SearchCubit(SearchHome(repository));
    addTearDown(homeCubit.close);
    addTearDown(searchCubit.close);
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider.value(value: homeCubit),
            BlocProvider.value(value: searchCubit),
          ],
          child: const SearchPage(),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'History');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(find.text('History'), findsWidgets);
    expect(find.text('Live history course'), findsOneWidget);
    expect(find.text(AppCopy.activitiesLabel), findsNothing);
    expect(find.text(AppCopy.quizzesLabel), findsNothing);
  });
}

class _StaticCatalog implements CourseRepository {
  const _StaticCatalog(this.course);
  final Course course;
  @override
  Future<List<Course>> getCourses() async => [course];
  @override
  Future<List<QuizQuestion>> getQuestions(String courseId) async =>
      throw const AppFailure.unavailable();
}

class _FakeHome implements HomeRepository, SearchRepository {
  _FakeHome(this.overview);
  final HomeOverview overview;
  int homeCalls = 0;
  final queries = <String>[];
  @override
  Future<HomeOverview> getHome() async {
    homeCalls++;
    return overview;
  }

  @override
  Future<HomeSearchResult> search(String text) async {
    queries.add(text);
    return const HomeSearchResult(
      subjects: [
        Subject(id: '15', name: 'History', isFree: true, isSubscribed: false),
      ],
      unsupportedExamResults: 0,
      unsupportedActivityResults: 0,
    );
  }
}

class _DelayedHome implements HomeRepository, SearchRepository {
  _DelayedHome(this.overview);
  final HomeOverview overview;
  final searches = <String, Completer<HomeSearchResult>>{};
  @override
  Future<HomeOverview> getHome() async => overview;
  @override
  Future<HomeSearchResult> search(String text) =>
      (searches[text] = Completer<HomeSearchResult>()).future;
}
