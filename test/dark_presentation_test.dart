import 'package:tamkeen2/features/courses/presentation/widgets/course_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/theme/app_theme.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/auth/data/unavailable_auth_repository.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/auth/presentation/auth_pages.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';

void main() {
  testWidgets('shared card and skeleton use dark semantic surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Column(
            children: [
              SurfaceCard(child: Text('Card')),
              SkeletonBlock(height: 20),
            ],
          ),
        ),
      ),
    );

    final card = tester.widget<Container>(
      find
          .ancestor(of: find.text('Card'), matching: find.byType(Container))
          .first,
    );
    final decoration = card.decoration! as BoxDecoration;
    expect(decoration.color, AppPalette.dark.surface);
    expect(decoration.border!.top.color, AppPalette.dark.border);
    final skeleton = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(SkeletonBlock),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      (skeleton.decoration! as BoxDecoration).color,
      AppPalette.dark.skeleton,
    );
  });

  testWidgets('login page uses dark background and dark theme heading', (
    tester,
  ) async {
    final auth = AuthCubit(UnavailableAuthRepository());
    addTearDown(auth.close);
    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: auth,
        child: MaterialApp(theme: AppTheme.dark, home: const LoginPage()),
      ),
    );

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppPalette.dark.background,
    );
    final heading =
        tester
                .widget<RichText>(
                  find
                      .descendant(
                        of: find.byType(AuthHeading),
                        matching: find.byType(RichText),
                      )
                      .first,
                )
                .text
            as TextSpan;
    Iterable<TextSpan> spans(InlineSpan value) sync* {
      if (value is TextSpan) {
        yield value;
        for (final child in value.children ?? const <InlineSpan>[]) {
          yield* spans(child);
        }
      }
    }

    expect(
      spans(
        heading,
      ).any((span) => span.style?.color == AppPalette.dark.primary),
      isTrue,
    );
  });

  testWidgets('course card uses API image and keeps preview illustration', (
    tester,
  ) async {
    Course course(String? imageUrl) => Course(
      id: '42',
      title: 'Course',
      category: 'Science',
      teacher: 'Teacher',
      description: '',
      lessons: const [],
      isFree: true,
      price: 0,
      accent: 0,
      imageUrl: imageUrl,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: CourseCard(
            course: course('https://example.test/image.png'),
            compact: true,
          ),
        ),
      ),
    );
    expect(
      tester
          .widgetList<Image>(find.byType(Image))
          .any(
            (image) =>
                image.image is NetworkImage &&
                (image.image as NetworkImage).url ==
                    'https://example.test/image.png',
          ),
      isTrue,
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: CourseCard(course: course('javascript:invalid'), compact: true),
        ),
      ),
    );
    expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: CourseCard(course: course(null), compact: true)),
      ),
    );
    expect(
      tester
          .widgetList<Image>(find.byType(Image))
          .any(
            (image) =>
                image.image is AssetImage &&
                (image.image as AssetImage).assetName ==
                    'assets/illustrations/teacher.png',
          ),
      isTrue,
    );
  });

  testWidgets('search hint follows the selected language', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(body: AppSearch(onChanged: (_) {})),
      ),
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration?.hintText,
      'Search here...',
    );
  });
}
