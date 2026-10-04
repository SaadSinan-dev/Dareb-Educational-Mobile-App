import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/config/app_runtime.dart';
import 'package:tamkeen2/core/theme/app_theme.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/account/domain/account_content.dart';
import 'package:tamkeen2/features/account/domain/account_content_repository.dart';
import 'package:tamkeen2/features/account/domain/account_models.dart';
import 'package:tamkeen2/features/auth/data/unavailable_auth_repository.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/profile/presentation/widgets/account_summary.dart';
import 'package:tamkeen2/features/content/presentation/screens/policy_page.dart';
import 'package:tamkeen2/features/faq/presentation/faq_cubit.dart';
import 'package:tamkeen2/features/faq/presentation/screens/faq_page.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';

class _Content implements AccountContentRepository {
  @override
  Future<AccountPage> loadPage(AccountPageKind kind) async =>
      const AccountPage(id: 1, value: 'Backend policy content');
  @override
  Future<List<AccountFaq>> loadFaqs() async => const [];
  @override
  Future<List<AccountGallerySummary>> loadGallerySummaries() async => const [];
  @override
  Future<AccountContactInfo> loadContactInfo() async =>
      const AccountContactInfo(email: 'support@example.test', phone: '123');
}

void main() {
  testWidgets(
    'FAQ and privacy share course header geometry and back navigation',
    (tester) async {
      const capture = bool.fromEnvironment('UI_CAPTURE');
      final auth = AuthCubit(UnavailableAuthRepository());
      addTearDown(auth.close);
      final boundaryKey = GlobalKey();
      if (capture) {
        await tester.runAsync(() async {
          await (FontLoader('NotoSansArabic')
                ..addFont(rootBundle.load('assets/fonts/NotoSansArabic.ttf')))
              .load();
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
          await Directory('build/ui-final').create(recursive: true);
        });
      }
      Future<void> screenshot(String name) async {
        if (!capture) return;
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'build/ui-final/$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      final repository = _Content();
      final faq = FaqCubit(repository);
      addTearDown(faq.close);
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 28, bottom: 16);
      tester.view.viewPadding = const FakeViewPadding(top: 28, bottom: 16);
      for (final language in ['ar', 'en']) {
        for (final width in [320.0, 430.0, 768.0, 1024.0]) {
          for (final preview in [false, true]) {
            tester.view.physicalSize = Size(width, 932);
            final router = GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, _) => const PageLayout(
                    title: AppCopy.mySubjectsTab,
                    back: false,
                  ),
                ),
                GoRoute(path: '/faq', builder: (_, _) => const FaqPage()),
                GoRoute(
                  path: '/profile',
                  builder: (_, _) => BlocProvider.value(
                    value: auth,
                    child: const PageLayout(
                      title: AppCopy.profileTitle,
                      back: false,
                      children: [
                        AccountSummary(
                          data: AccountData(
                            profile: AccountProfile(
                              firstName: 'Backend',
                              lastName: 'Name',
                              school: 'School',
                              imageUrl: 'https://example.test/avatar.png',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GoRoute(
                  path: '/privacy',
                  builder: (_, _) =>
                      PolicyPage(privacy: true, repository: repository),
                ),
              ],
            );
            await tester.pumpWidget(
              RepaintBoundary(
                key: boundaryKey,
                child: AppRuntime(
                  preview: preview,
                  child: BlocProvider.value(
                    value: faq,
                    child: MaterialApp.router(
                      debugShowCheckedModeBanner: false,
                      routerConfig: router,
                      theme: AppTheme.light,
                      locale: Locale(language),
                      supportedLocales: AppLocalizations.supportedLocales,
                      localizationsDelegates: const [
                        AppLocalizations.delegate,
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final reference = tester.getRect(find.byType(AppHeader));
            if (!preview) await screenshot('course-$language-$width');
            for (final path in ['/faq', '/privacy']) {
              router.push(path);
              await tester.pumpAndSettle();
              expect(
                find.byType(AppHeader),
                findsOneWidget,
                reason: '$path/$language/$width/$preview',
              );
              expect(tester.getRect(find.byType(AppHeader)), reference);
              final back = find.descendant(
                of: find.byType(AppHeader),
                matching: find.byIcon(Icons.arrow_back),
              );
              expect(back, findsOneWidget);
              final header = tester.getRect(find.byType(AppHeader));
              final backRect = tester.getRect(back);
              expect(
                language == 'ar'
                    ? backRect.center.dx > header.center.dx
                    : backRect.center.dx < header.center.dx,
                isTrue,
              );
              expect(tester.takeException(), isNull);
              if (!preview) {
                await screenshot('${path.substring(1)}-$language-$width');
              }
              await tester.tap(back);
              await tester.pumpAndSettle();
              expect(router.routeInformationProvider.value.uri.path, '/');
            }
            router.push('/profile');
            await tester.pumpAndSettle();
            if (capture) {
              await tester.runAsync(
                () => precacheImage(
                  const AssetImage('assets/images/avatar.png'),
                  tester.element(find.byType(AccountSummary)),
                ),
              );
              await tester.pumpAndSettle();
            }
            expect(tester.takeException(), isNull);
            if (!preview) await screenshot('profile-$language-$width');
            await tester.pumpWidget(const SizedBox.shrink());
            router.dispose();
          }
        }
      }
    },
  );
}
