import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/theme/app_theme.dart';
import 'package:tamkeen2/features/gallery/presentation/widgets/gallery_image.dart';
import 'package:tamkeen2/features/contact/presentation/contact_cubit.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/preferences/app_preferences_cubit.dart';
import 'package:tamkeen2/features/account/domain/account_content.dart';
import 'package:tamkeen2/features/account/domain/account_content_repository.dart';
import 'package:tamkeen2/features/account/domain/account_models.dart';
import 'package:tamkeen2/features/account/domain/account_repository.dart';
import 'package:tamkeen2/features/account/presentation/account_common.dart';
import 'package:tamkeen2/features/account/presentation/account_cubit.dart';
import 'package:tamkeen2/features/gallery/presentation/screens/gallery_page.dart';
import 'package:tamkeen2/features/content/data/cms_text_mapper.dart';
import 'package:tamkeen2/features/content/presentation/screens/policy_page.dart';
import 'package:tamkeen2/features/profile/presentation/screens/profile_page.dart';
import 'package:tamkeen2/features/contact/presentation/screens/contact_page.dart';
import 'package:tamkeen2/features/content/presentation/screens/about_page.dart';
import 'package:tamkeen2/features/auth/data/unavailable_auth_repository.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';

import 'support/memory_store.dart';

class _ContentRepository implements AccountContentRepository {
  @override
  Future<List<AccountFaq>> loadFaqs() async => const [];
  Future<AccountPage> Function(AccountPageKind) onPage = (_) async =>
      const AccountPage(id: 1, value: 'content');
  Future<List<AccountGallerySummary>> Function() onGallery = () async =>
      const [];
  Future<AccountContactInfo> Function() onContact = () async =>
      const AccountContactInfo(
        email: 'support@example.test',
        phone: '0993571184',
      );
  int pageCalls = 0;
  int galleryCalls = 0;
  int contactCalls = 0;

  @override
  Future<AccountPage> loadPage(AccountPageKind kind) {
    pageCalls++;
    return onPage(kind);
  }

  @override
  Future<List<AccountGallerySummary>> loadGallerySummaries() {
    galleryCalls++;
    return onGallery();
  }

  @override
  Future<AccountContactInfo> loadContactInfo() {
    contactCalls++;
    return onContact();
  }
}

class _UnavailableAccountRepository implements AccountRepository {
  @override
  Future<AccountData> load(String userId) async =>
      throw const AppFailure.unavailable();

  @override
  Future<AccountProfile> saveProfile(
    String userId,
    AccountProfile profile,
  ) async => throw const AppFailure.unavailable();

  @override
  Future<AccountProfile> updateImage(
    String userId,
    Uint8List bytes,
    String filename,
    String? mimeType,
  ) async => throw const AppFailure.unavailable();

  @override
  Future<void> markNotificationRead(String userId, String id) async =>
      throw const AppFailure.unavailable();

  @override
  Future<ContactResult> submitContact(ContactMessage message) async =>
      throw const AppFailure.unavailable();
}

void main() {
  test('CMS HTML becomes plain text and removes active markup', () {
    final text = accountHtmlToText(
      '<div>أول &amp; ثانٍ</div><script>evil()</script>'
      '<p>سطر<br>جديد &#x1F600;</p><style>hidden</style>',
    );
    expect(text, contains('أول & ثانٍ'));
    expect(text, contains('سطر\nجديد 😀'));
    expect(text, isNot(contains('<')));
    expect(text, isNot(contains('evil')));
    expect(text, isNot(contains('hidden')));
  });

  testWidgets('terms show verified remote text after loading', (tester) async {
    final repository = _ContentRepository();
    final completer = Completer<AccountPage>();
    repository.onPage = (kind) {
      expect(kind, AccountPageKind.termsConditions);
      return completer.future;
    };
    await tester.pumpWidget(
      MaterialApp(
        home: PolicyPage(
          privacy: false,
          repository: repository,
          previewMode: false,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete(
      const AccountPage(
        id: 2,
        value: '<div>شروط &amp; أحكام</div><script>evil()</script>',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('شروط & أحكام'), findsOneWidget);
    expect(find.textContaining('evil'), findsNothing);
    expect(find.text(AppCopy.referenceLegalTextNotice), findsNothing);
    expect(repository.pageCalls, 1);
  });

  testWidgets('live page empty and failure states are visible and retryable', (
    tester,
  ) async {
    final repository = _ContentRepository();
    repository.onPage = (_) async => throw const AppFailure('فشل التحميل');
    await tester.pumpWidget(
      MaterialApp(
        home: PolicyPage(
          privacy: true,
          repository: repository,
          previewMode: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('فشل التحميل'), findsOneWidget);
    repository.onPage = (_) async =>
        const AccountPage(id: 1, value: '<div></div>');
    await tester.tap(find.text(AppCopy.retryAction));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.pageContentEmpty), findsOneWidget);
    expect(repository.pageCalls, 2);
  });

  testWidgets('privacy uses backend value even when preview mode is enabled', (
    tester,
  ) async {
    final repository = _ContentRepository();
    repository.onPage = (_) async =>
        const AccountPage(id: 1, value: '<p>Backend privacy policy</p>');
    await tester.pumpWidget(
      MaterialApp(
        home: PolicyPage(
          privacy: true,
          repository: repository,
          previewMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Backend privacy policy'), findsOneWidget);
    expect(find.text(AppCopy.referenceLegalTextNotice), findsNothing);
    expect(repository.pageCalls, 1);
  });

  testWidgets('about sheet displays server value in normal mode', (
    tester,
  ) async {
    final repository = _ContentRepository();
    repository.onPage = (kind) async {
      expect(kind, AccountPageKind.aboutApplication);
      return const AccountPage(id: 3, value: 'نص عن التطبيق');
    };
    await tester.pumpWidget(
      MaterialApp(home: AboutPage(repository: repository, previewMode: false)),
    );
    await tester.pumpAndSettle();
    expect(find.text('نص عن التطبيق'), findsOneWidget);
    expect(find.text(AppCopy.aboutAppDescription), findsNothing);
  });

  testWidgets('contact sheet shows verified public support details', (
    tester,
  ) async {
    final repository = _ContentRepository();
    final account = AccountCubit(_UnavailableAccountRepository());
    final auth = AuthCubit(UnavailableAuthRepository());
    addTearDown(account.close);
    addTearDown(auth.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AccountCubit>.value(value: account),
          BlocProvider<AuthCubit>.value(value: auth),
        ],
        child: MaterialApp(
          home: _contactPage(contentRepository: repository, previewMode: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('support@example.test'), findsOneWidget);
    expect(find.text('0993571184'), findsOneWidget);
    expect(repository.contactCalls, 1);
  });

  testWidgets('gallery shows verified summaries without invented photos', (
    tester,
  ) async {
    final repository = _ContentRepository();
    final completer = Completer<List<AccountGallerySummary>>();
    repository.onGallery = () => completer.future;
    await tester.pumpWidget(
      MaterialApp(
        home: GalleryPage(repository: repository, previewMode: false),
      ),
    );
    expect(find.byType(AccountGalleryGridSkeleton), findsOneWidget);
    completer.complete(const [
      AccountGallerySummary(id: 8, name: 'ألبوم حقيقي'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('ألبوم حقيقي (0)'), findsOneWidget);
    expect(find.text(AppCopy.galleryImagesUnavailable), findsOneWidget);
    expect(find.byType(AccountPhoto), findsNothing);
    expect(repository.galleryCalls, 1);
  });

  testWidgets('live albums open backend images and a zoomable preview', (
    tester,
  ) async {
    final repository = _ContentRepository();
    repository.onGallery = () async => const [
      AccountGallerySummary(
        id: 8,
        name: 'Real album',
        images: [
          'https://images.example.test/1.png',
          'https://images.example.test/2.png',
        ],
      ),
    ];
    final router = GoRouter(
      initialLocation: '/gallery',
      routes: [
        GoRoute(
          path: '/gallery',
          builder: (_, _) =>
              GalleryPage(repository: repository, previewMode: false),
        ),
        GoRoute(
          path: '/gallery/:id',
          builder: (_, state) => AlbumPage(
            albumId: state.pathParameters['id']!,
            repository: repository,
            previewMode: false,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('Real album (2)'), findsOneWidget);
    expect(find.text(AppCopy.galleryImagesUnavailable), findsNothing);
    expect(find.byType(AccountPhoto), findsNothing);
    await tester.tap(find.text('Real album (2)'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('album-photo-0')), findsOneWidget);
    final images = tester.widgetList<GalleryImage>(find.byType(GalleryImage));
    expect(images.map((image) => image.url), [
      'https://images.example.test/1.png',
      'https://images.example.test/2.png',
    ]);
    await tester.tapAt(
      tester.getRect(find.byKey(const ValueKey('album-photo-0'))).bottomRight -
          const Offset(12, 12),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(
      tester
          .widget<GalleryImage>(
            find.descendant(
              of: find.byType(Dialog),
              matching: find.byType(GalleryImage),
            ),
          )
          .url,
      'https://images.example.test/1.png',
    );
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.byKey(const ValueKey('album-photo-0')), findsOneWidget);
  });

  testWidgets(
    'live album empty, missing and error states retry the documented endpoint',
    (tester) async {
      final repository = _ContentRepository();
      repository.onGallery = () async => throw const AppFailure('Album error');
      await tester.pumpWidget(
        MaterialApp(
          home: AlbumPage(
            albumId: '8',
            repository: repository,
            previewMode: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Album error'), findsOneWidget);
      repository.onGallery = () async => const [];
      await tester.tap(find.text(AppCopy.retryAction));
      await tester.pumpAndSettle();
      expect(find.text(AppCopy.albumNotFound), findsOneWidget);
      repository.onGallery = () async => const [
        AccountGallerySummary(id: 8, name: 'Empty'),
      ];
      await tester.tap(find.text(AppCopy.retryAction));
      await tester.pumpAndSettle();
      expect(find.text(AppCopy.galleryImagesUnavailable), findsOneWidget);
      expect(find.byType(GalleryImage), findsNothing);
      expect(repository.galleryCalls, 3);
    },
  );

  testWidgets('privacy long Arabic and English values scroll at 2x text', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    final repository = _ContentRepository();
    for (final language in ['ar', 'en']) {
      final text = language == 'ar'
          ? 'محتوى الخصوصية من الخادم'
          : 'Server privacy content';
      for (final size in [const Size(320, 640), const Size(600, 360)]) {
        tester.view.physicalSize = size;
        repository.onPage = (_) async => AccountPage(
          id: 1,
          value: List.generate(40, (i) => '<p>$text $i</p>').join(),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightFor(language),
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(2),
              ),
              child: Directionality(
                textDirection: language == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: PolicyPage(
                  key: UniqueKey(),
                  privacy: true,
                  repository: repository,
                  previewMode: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final selectable = tester.widget<SelectableText>(
          find.byType(SelectableText),
        );
        expect(selectable.data, contains('$text 39'));
        final scroll = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        expect(scroll.position.maxScrollExtent, greaterThan(0));
        scroll.position.jumpTo(scroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('gallery error can retry to an empty state', (tester) async {
    final repository = _ContentRepository();
    repository.onGallery = () async => throw const AppFailure('تعذر المعرض');
    await tester.pumpWidget(
      MaterialApp(
        home: GalleryPage(repository: repository, previewMode: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('تعذر المعرض'), findsOneWidget);
    repository.onGallery = () async => const [];
    await tester.tap(find.text(AppCopy.retryAction));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.galleryEmpty), findsOneWidget);
    expect(repository.galleryCalls, 2);
  });

  testWidgets('language and theme settings persist when profile load fails', (
    tester,
  ) async {
    final store = MemoryStore();
    final preferences = AppPreferencesCubit(store);
    final account = AccountCubit(_UnavailableAccountRepository());
    final auth = AuthCubit(UnavailableAuthRepository());
    addTearDown(preferences.close);
    addTearDown(account.close);
    addTearDown(auth.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AppPreferencesCubit>.value(value: preferences),
          BlocProvider<AccountCubit>.value(value: account),
          BlocProvider<AuthCubit>.value(value: auth),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfilePage())),
      ),
    );
    await tester.pumpAndSettle();
    expect(account.state.status, AccountStatus.failure);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('language-setting')),
      300,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-setting')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-option-en')));
    await tester.pumpAndSettle();
    expect(preferences.state.languageCode, 'en');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('theme-setting')),
      300,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme-setting')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme-option-dark')));
    await tester.pumpAndSettle();
    expect(preferences.state.themeMode, ThemeMode.dark);
    final restored = AppPreferencesCubit(store);
    await restored.restore();
    expect(restored.state.languageCode, 'en');
    expect(restored.state.themeMode, ThemeMode.dark);
    await restored.close();
  });
}

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
