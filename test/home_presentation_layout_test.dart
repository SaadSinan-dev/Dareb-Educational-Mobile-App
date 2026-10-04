import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/theme/app_theme.dart';
import 'package:tamkeen2/features/assessments/domain/quiz_question.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/domain/course_repository.dart';
import 'package:tamkeen2/features/courses/domain/get_courses.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';
import 'package:tamkeen2/features/courses/presentation/widgets/course_cards.dart';
import 'package:tamkeen2/features/courses/presentation/widgets/category_grid.dart';
import 'package:tamkeen2/features/home/presentation/widgets/home_design_slider.dart';
import 'package:tamkeen2/features/home/presentation/widgets/home_materials_strip.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';

class _Catalog implements CourseRepository {
  @override
  Future<List<Course>> getCourses() async => const [];
  @override
  Future<List<QuizQuestion>> getQuestions(String courseId) async => const [];
}

void main() {
  testWidgets(
    'Home materials collection swipes horizontally inside the vertical page',
    (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      final categories = [
        for (var index = 0; index < 8; index++) 'Backend material $index',
      ];
      for (final language in ['ar', 'en']) {
        for (final width in [320.0, 360.0, 390.0, 430.0, 600.0, 768.0]) {
          for (final height in [932.0, 360.0]) {
            tester.view.physicalSize = Size(width, height);
            String? selected;
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.light,
                home: Directionality(
                  textDirection: language == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: Scaffold(
                    body: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        CategoryGrid(
                          horizontal: true,
                          categories: categories,
                          onSelect: (value) => selected = value,
                        ),
                        const SizedBox(height: 900),
                      ],
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final scroll = find.byKey(const ValueKey('home-materials-scroll'));
            expect(
              tester.widget<SingleChildScrollView>(scroll).scrollDirection,
              Axis.horizontal,
            );
            expect(
              find.descendant(of: scroll, matching: find.byType(Row)),
              findsOneWidget,
            );
            final scrollState = tester.state<ScrollableState>(
              find.descendant(of: scroll, matching: find.byType(Scrollable)),
            );
            expect(scrollState.position.maxScrollExtent, greaterThan(0));
            final cards = find.descendant(
              of: scroll,
              matching: find.byType(InkWell),
            );
            expect(cards, findsNWidgets(categories.length));
            final first = tester.getRect(cards.first);
            final second = tester.getRect(cards.at(1));
            expect(first.width, 127);
            expect(second.width, 127);
            expect(
              language == 'ar'
                  ? first.left - second.right
                  : second.left - first.right,
              10,
            );
            expect(
              first.overlaps(Rect.fromLTWH(16, 0, width - 32, height)),
              isTrue,
            );
            expect(
              second.overlaps(Rect.fromLTWH(16, 0, width - 32, height)),
              isTrue,
            );
            await tester.tap(cards.first);
            expect(selected, categories.first);
            await tester.drag(scroll, Offset(language == 'ar' ? 240 : -240, 0));
            await tester.pumpAndSettle();
            expect(scrollState.position.pixels, greaterThan(0));
            expect(
              (tester.getRect(cards.first).left - first.left).abs(),
              greaterThan(100),
            );
            await tester.drag(scroll, Offset(language == 'ar' ? -240 : 240, 0));
            await tester.pumpAndSettle();
            expect(scrollState.position.pixels, closeTo(0, 1));
            expect(
              tester.takeException(),
              isNull,
              reason: '$language/$width/$height',
            );
            await tester.pumpWidget(const SizedBox.shrink());
          }
        }
      }
    },
  );

  testWidgets(
    'Home slider overlap and horizontal cards survive responsive matrix',
    (tester) async {
      const capture = bool.fromEnvironment('HOME_UI_CAPTURE');
      final boundaryKey = GlobalKey();
      final repository = _Catalog();
      final cubit = CourseCubit(GetCourses(repository), repository);
      addTearDown(cubit.close);
      addTearDown(tester.view.reset);
      final courses = [
        for (var index = 0; index < 3; index++)
          Course(
            id: '$index',
            title: 'Real material title',
            category: 'History',
            teacher: 'Backend teacher',
            description: '',
            lessons: const [],
            isFree: true,
            price: 0,
            accent: 0,
          ),
      ];
      if (capture) {
        await tester.runAsync(() async {
          await Directory('build/home-ui').create(recursive: true);
          await (FontLoader('NotoSansArabic')
                ..addFont(rootBundle.load('assets/fonts/NotoSansArabic.ttf')))
              .load();
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
        });
      }
      tester.view.devicePixelRatio = 1;
      for (final locale in ['ar', 'en']) {
        for (final width in [320.0, 360.0, 390.0, 430.0, 600.0, 768.0]) {
          for (final height in [932.0, 360.0]) {
            for (final scale in [1.0, 2.0]) {
              tester.view.physicalSize = Size(width, height);
              var taps = 0;
              await tester.pumpWidget(
                RepaintBoundary(
                  key: boundaryKey,
                  child: BlocProvider.value(
                    value: cubit,
                    child: MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.light,
                      locale: Locale(locale),
                      supportedLocales: AppLocalizations.supportedLocales,
                      localizationsDelegates: const [
                        AppLocalizations.delegate,
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                      home: Scaffold(
                        body: MediaQuery(
                          data: MediaQueryData(
                            size: Size(width, height),
                            textScaler: TextScaler.linear(scale),
                          ),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  HomeDesignSlider(onAccountTap: () => taps++),
                                  const SizedBox(height: 24),
                                  HomeMaterialsStrip(courses: courses),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '$locale/$width/$height/$scale',
              );
              final slider = find.byType(HomeDesignSlider);
              final art = find.descendant(
                of: slider,
                matching: find.byType(Image),
              );
              final background = find
                  .descendant(of: slider, matching: find.byType(DecoratedBox))
                  .first;
              expect(
                tester.getRect(art).top,
                lessThan(tester.getRect(background).top),
              );
              final image = tester.widget<Image>(art);
              expect(
                image.image,
                isA<AssetImage>().having(
                  (asset) => asset.assetName,
                  'asset',
                  'assets/illustrations/graduates.png',
                ),
              );
              expect(image.fit, BoxFit.contain);
              await tester.ensureVisible(
                find.descendant(
                  of: slider,
                  matching: find.byType(OutlinedButton),
                ),
              );
              await tester.pumpAndSettle();
              await tester.tap(
                find.descendant(
                  of: slider,
                  matching: find.byType(OutlinedButton),
                ),
              );
              expect(taps, 1);
              final strip = find.byType(HomeMaterialsStrip);
              await tester.ensureVisible(strip);
              await tester.pumpAndSettle();
              final horizontal = find.descendant(
                of: strip,
                matching: find.byType(SingleChildScrollView),
              );
              expect(
                tester
                    .widget<SingleChildScrollView>(horizontal)
                    .scrollDirection,
                Axis.horizontal,
              );
              final scrollable = tester.state<ScrollableState>(
                find.descendant(of: strip, matching: find.byType(Scrollable)),
              );
              expect(scrollable.position.maxScrollExtent, greaterThan(0));
              final cards = find.byType(CourseCard);
              expect(cards, findsNWidgets(3));
              expect(
                tester.widget<CourseCard>(cards.first).course,
                same(courses.first),
              );
              await tester.drag(
                horizontal,
                Offset(locale == 'ar' ? 200 : -200, 0),
              );
              await tester.pumpAndSettle();
              expect(scrollable.position.pixels, greaterThan(0));
              expect(tester.takeException(), isNull);
              if (capture && scale == 1 && height == 932) {
                scrollable.position.jumpTo(0);
                await tester.runAsync(() async {
                  await precacheImage(
                    const AssetImage('assets/illustrations/graduates.png'),
                    tester.element(slider),
                  );
                });
                await tester.pumpAndSettle();
                await tester.runAsync(() async {
                  final boundary =
                      boundaryKey.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary;
                  final image = await boundary.toImage();
                  final bytes = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  await File(
                    'build/home-ui/sections-$locale-$width.png',
                  ).writeAsBytes(bytes!.buffer.asUint8List());
                  image.dispose();
                });
              }
              await tester.pumpWidget(const SizedBox.shrink());
            }
          }
        }
      }
    },
  );
}
