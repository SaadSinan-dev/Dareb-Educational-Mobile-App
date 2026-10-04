import 'package:tamkeen2/features/account/domain/account_content_repository.dart';
import 'package:tamkeen2/features/contact/presentation/contact_cubit.dart';
import 'package:tamkeen2/features/assessments/domain/quiz_question.dart';
import 'package:tamkeen2/features/profile/presentation/school_options_cubit.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/storage/key_value_store.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:tamkeen2/features/account/data/demo_account_repository.dart';
import 'package:tamkeen2/features/account/domain/account_models.dart';
import 'package:tamkeen2/features/account/domain/account_repository.dart';
import 'package:tamkeen2/features/account/presentation/account_pages.dart';
import 'package:tamkeen2/features/auth/data/unavailable_auth_repository.dart';
import 'package:tamkeen2/features/auth/domain/auth_user.dart';
import 'package:tamkeen2/features/auth/domain/registration_draft.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/courses/domain/course_repository.dart';
import 'package:tamkeen2/features/courses/domain/get_courses.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';

class _Store implements KeyValueStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> remove(String key) async => values.remove(key);
}

class _Auth extends AuthCubit {
  _Auth() : super(UnavailableAuthRepository()) {
    emit(
      const AuthState(
        status: AuthStatus.authenticated,
        user: AuthUser(
          id: 'user',
          phone: '0501234567',
          firstName: 'سارة',
          lastName: 'أحمد',
          school: 'مدرسة النجاح',
        ),
      ),
    );
  }
}

class _AccountRepository implements AccountRepository {
  @override
  Future<AccountData> load(String userId) async => const AccountData(
    profile: AccountProfile(
      firstName: 'سارة',
      lastName: 'أحمد',
      school: 'مدرسة النجاح',
      schoolId: 1,
      schoolGovernorate: 'damascus',
    ),
    summary: AccountSummaryStats(
      badges: 1,
      lessons: 17,
      courses: 2,
      points: 33,
      chapters: 4,
    ),
    achievements: [
      AccountAchievement(
        title: 'الفلك',
        iconAsset: 'assets/icons/science.png',
        subjectProgress: .3,
        points: 77,
        pointsTotal: 100,
        pointsProgress: .77,
        chapters: 2,
        chaptersTotal: 5,
        chaptersProgress: .4,
        lessons: 6,
        lessonsTotal: 10,
        lessonsProgress: .6,
      ),
    ],
  );
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
      const ContactResult(
        delivered: false,
        message: 'معاينة فقط؛ لم تُرسل الرسالة.',
      );
}

class _Courses implements CourseRepository {
  static const course = Course(
    id: 'statistics',
    title: 'الإحصاء',
    category: 'الرياضيات',
    teacher: 'مدرس',
    description: '',
    lessons: [
      Lesson(title: 'مقدمة الإحصاء', minutes: 22),
      Lesson(
        title: 'ملخص الإحصاء',
        minutes: 0,
        kind: LessonKind.document,
        pages: 40,
      ),
    ],
    isFree: true,
    price: 0,
    accent: 0xFF5589F5,
  );
  @override
  Future<List<Course>> getCourses() async => [course];
  @override
  Future<List<QuizQuestion>> getQuestions(String courseId) async => [];
}

class _Learning extends CourseCubit {
  _Learning() : super(GetCourses(_Courses()), _Courses(), demoMode: true) {
    emit(
      const CourseState(
        status: LoadStatus.ready,
        courses: [_Courses.course],
        downloadedIds: {'statistics'},
      ),
    );
  }
}

void main() {
  testWidgets(
    'direct profile edit waits for backend profile before showing form',
    (tester) async {
      await services.reset();
      addTearDown(services.reset);
      final auth = _Auth();
      final account = AccountCubit(_AccountRepository());
      addTearDown(auth.close);
      addTearDown(account.close);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<AccountCubit>.value(value: account),
          ],
          child: MaterialApp(
            locale: Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              ...GlobalMaterialLocalizations.delegates,
              AppLocalizations.delegate,
            ],
            home: _profileEditor(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(account.state.status, AccountStatus.ready);
      final school = find.byType(DropdownButtonFormField<int>);
      expect(school, findsOneWidget);
      expect(tester.state<FormFieldState<int>>(school).value, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('home completion sheet has gender while profile edit does not', (
    tester,
  ) async {
    await services.reset();
    addTearDown(services.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 932);
    addTearDown(tester.view.reset);
    final auth = _Auth();
    final account = AccountCubit(_AccountRepository());
    await account.load('user');
    addTearDown(auth.close);
    addTearDown(account.close);

    Widget sheet({
      required bool completion,
      Locale locale = const Locale('ar'),
    }) => MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: auth),
        BlocProvider<AccountCubit>.value(value: account),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          ...GlobalMaterialLocalizations.delegates,
          AppLocalizations.delegate,
        ],
        home: BlocProvider(
          key: ValueKey(completion ? 'completion' : 'edit'),
          create: (_) => SchoolOptionsCubit(auth.repository),
          child: EditProfilePage(completion: completion),
        ),
      ),
    );

    await tester.pumpWidget(sheet(completion: true));
    expect(find.text('أكمل حسابك'), findsOneWidget);
    expect(
      tester.getCenter(find.text('التأكيد')).dx,
      greaterThan(tester.getCenter(find.text('الخروج')).dx),
    );
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    final genderField = find.byType(DropdownButtonFormField<Gender>);
    expect(genderField, findsOneWidget);
    expect(tester.state<FormFieldState<Gender>>(genderField).value, isNull);
    await tester.tap(genderField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('أنثى').last);
    await tester.pumpAndSettle();
    expect(
      tester.state<FormFieldState<Gender>>(genderField).value,
      Gender.female,
    );

    await tester.pumpWidget(sheet(completion: false));
    expect(find.text('عدل معلوماتك الشخصية'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<Gender>), findsNothing);

    await tester.pumpWidget(
      sheet(completion: true, locale: const Locale('en')),
    );
    expect(find.text('Complete your account'), findsOneWidget);
  });

  testWidgets('contact sheet asks for surname and shows preview as neutral', (
    tester,
  ) async {
    final auth = _Auth();
    final account = AccountCubit(DemoAccountRepository(_Store()));
    addTearDown(auth.close);
    addTearDown(account.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: auth),
          BlocProvider<AccountCubit>.value(value: account),
        ],
        child: MaterialApp(home: _contactPage(previewMode: true)),
      ),
    );
    expect(find.text('الكنية'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(1))
          .controller!
          .text,
      'أحمد',
    );
    await tester.enterText(find.byType(TextFormField).at(3), 'أحتاج للمساعدة');
    await tester.tap(find.text('التأكيد'));
    await tester.pumpAndSettle();
    final preview = tester.widget<Text>(find.textContaining('لم تُرسل'));
    expect(preview.style?.color, AppPalette.light.muted);
    expect(
      tester
          .element(find.byType(ContactPage))
          .read<ContactCubit>()
          .state
          .actionStatus,
      ContactStatus.preview,
    );
  });

  testWidgets('achievement page renders repository values', (tester) async {
    final auth = _Auth();
    final account = AccountCubit(_AccountRepository());
    addTearDown(auth.close);
    addTearDown(account.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: auth),
          BlocProvider<AccountCubit>.value(value: account),
        ],
        child: const MaterialApp(home: AchievementsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('17'), findsOneWidget);
    expect(find.text('الفلك'), findsOneWidget);
    expect(find.text('77'), findsOneWidget);
  });

  testWidgets('downloads list lesson media, open route and remove course', (
    tester,
  ) async {
    final learning = _Learning();
    addTearDown(learning.close);
    final router = GoRouter(
      initialLocation: AppRoutes.downloads,
      routes: [
        GoRoute(
          path: AppRoutes.downloads,
          builder: (_, _) => const DownloadsPage(),
        ),
        GoRoute(
          path: AppRoutes.lesson('statistics', 0),
          builder: (_, _) => const Scaffold(body: Text('lesson opened')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider<CourseCubit>.value(
        value: learning,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    expect(find.text('مقدمة الإحصاء'), findsOneWidget);
    expect(find.text('ملخص الإحصاء'), findsOneWidget);
    expect(find.textContaining('40 صفحة'), findsOneWidget);
    expect(find.textContaining('لم يتم تنزيل'), findsOneWidget);
    await tester.tap(find.byTooltip('تشغيل الدرس'));
    await tester.pumpAndSettle();
    expect(find.text('lesson opened'), findsOneWidget);
    router.go(AppRoutes.downloads);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('إزالة من قائمة التنزيل'));
    await tester.pumpAndSettle();
    expect(learning.state.downloadedIds, isEmpty);
    expect(find.text('مقدمة الإحصاء'), findsNothing);
  });
}

Widget _profileEditor({bool completion = false}) => Builder(
  builder: (context) => BlocProvider(
    create: (_) => SchoolOptionsCubit(context.read<AuthCubit>().repository),
    child: EditProfilePage(completion: completion),
  ),
);

Widget _contactPage({
  AccountContentRepository? contentRepository,
  bool? previewMode,
}) => Builder(
  builder: (context) => BlocProvider(
    create: (_) => ContactCubit(context.read<AccountCubit>().repository),
    child: ContactPage(
      contentRepository: contentRepository,
      previewMode: previewMode,
    ),
  ),
);
