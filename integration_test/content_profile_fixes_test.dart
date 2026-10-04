import 'package:tamkeen2/features/account/presentation/account_common.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tamkeen2/app.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/core/preferences/app_preferences_cubit.dart';
import 'package:tamkeen2/core/theme/app_theme.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/features/account/data/live_account_content_repository.dart';
import 'package:tamkeen2/features/account/data/postman_account_data_source.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/content/presentation/screens/policy_page.dart';
import 'package:tamkeen2/features/gallery/presentation/screens/gallery_page.dart';
import 'package:tamkeen2/features/gallery/presentation/widgets/gallery_image.dart';
import 'package:tamkeen2/features/profile/presentation/screens/profile_page.dart';
import 'package:tamkeen2/features/profile/presentation/widgets/profile_modal.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import '../test/support/memory_store.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget localized(String language, Widget page) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightFor(language),
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: [
      ...GlobalMaterialLocalizations.delegates,
      AppLocalizations.delegate,
    ],
    home: page,
  );

  testWidgets('device displays live backend gallery and privacy content', (
    tester,
  ) async {
    final client = ApiClient();
    final repository = LiveAccountContentRepository(
      PostmanAccountDataSource(
        publicClient: client,
        authenticatedClient: client,
      ),
    );
    final albums = await repository.loadGallerySummaries();
    await binding.convertFlutterSurfaceToImage();
    for (final language in ['ar', 'en']) {
      await tester.pumpWidget(
        localized(
          language,
          GalleryPage(
            key: UniqueKey(),
            repository: repository,
            previewMode: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (find.byType(AccountGalleryGridSkeleton).evaluate().isNotEmpty &&
          DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.pumpAndSettle();
      expect(find.byType(AccountGalleryGridSkeleton), findsNothing);
      expect(
        find.byType(GalleryImage),
        albums.any((album) => album.images.isNotEmpty)
            ? findsWidgets
            : findsNothing,
      );
      await binding.takeScreenshot('fixes-live-gallery-$language');
      if (albums.isNotEmpty) {
        await tester.pumpWidget(
          localized(
            language,
            AlbumPage(
              key: UniqueKey(),
              albumId: albums.first.id.toString(),
              repository: repository,
              previewMode: false,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await binding.takeScreenshot('fixes-live-album-$language');
      }
      await tester.pumpWidget(
        localized(
          language,
          PolicyPage(
            key: UniqueKey(),
            privacy: true,
            repository: repository,
            previewMode: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.text(AppCopy.referenceLegalTextNotice), findsNothing);
      await binding.takeScreenshot('fixes-live-privacy-$language');
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    client.dio.close();
  });

  testWidgets(
    'device image grid and zoom load HTTP media through the backend parser',
    (tester) async {
      // A local HTTP fixture verifies populated responses because the live server
      // currently supplies no photos. It is confined to this integration test.
      await binding.convertFlutterSurfaceToImage();
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final base = 'http://127.0.0.1:${server.port}';
      final bytes = (await rootBundle.load(
        'assets/images/gallery_4.png',
      )).buffer.asUint8List();
      server.listen((request) async {
        if (request.uri.path == '/api/galleries/all') {
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode({
              'data': [
                {
                  'id': 8,
                  'name': 'HTTP image fixture',
                  'images': [
                    '$base/photo.png',
                    {'image': '$base/photo2.png'},
                  ],
                },
              ],
            }),
          );
        } else {
          request.response.headers.contentType = ContentType('image', 'png');
          request.response.add(bytes);
        }
        await request.response.close();
      });
      final client = ApiClient(baseUrl: '$base/api');
      final repository = LiveAccountContentRepository(
        PostmanAccountDataSource(
          publicClient: client,
          authenticatedClient: client,
        ),
      );
      await tester.pumpWidget(
        localized(
          'ar',
          AlbumPage(albumId: '8', repository: repository, previewMode: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GalleryImage), findsNWidgets(2));
      expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
      await binding.takeScreenshot('fixes-http-image-grid');
      await tester.tap(find.byKey(const ValueKey('album-photo-0')));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
      await binding.takeScreenshot('fixes-http-image-preview');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      client.dio.close();
      await server.close(force: true);
    },
  );

  testWidgets('device Profile stays beneath modal and success/error messages', (
    tester,
  ) async {
    await binding.convertFlutterSurfaceToImage();
    await services.reset();
    configureDependencies(demoMode: true, store: MemoryStore());
    await tester.pumpWidget(const LearningApp());
    await tester.pumpAndSettle();
    final auth = services<AuthCubit>();
    await auth.requestCode('0912345678');
    await auth.verifyCode('1234');
    await tester.pumpAndSettle();
    for (final language in ['ar', 'en']) {
      await services<AppPreferencesCubit>().setLanguage(language);
      for (var tab = 0; tab < 4; tab++) {
        await tester.tap(find.byKey(ValueKey('bottom-tab-$tab')));
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(AppHeader));
        expect(
          Theme.of(context).textTheme.bodyMedium!.fontFamily,
          language == 'ar' ? 'NotoSansArabic' : 'Roboto',
        );
        await binding.takeScreenshot('fixes-font-$language-tab-$tab');
      }
      final context = tester.element(find.byType(ProfilePage));
      showAppMessage(
        context,
        language == 'ar' ? 'رسالة نجاح' : 'Success message',
      );
      await tester.pumpAndSettle();
      await binding.takeScreenshot('fixes-profile-success-$language');
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      final router = GoRouter.of(context);
      for (final route in ['/profile/edit', '/contact', '/about', '/logout']) {
        router.push(route);
        await tester.pumpAndSettle();
        expect(find.byType(ProfilePage), findsOneWidget);
        showAppMessage(
          tester.element(find.byType(ProfileModal)),
          language == 'ar' ? 'رسالة خطأ' : 'Error message',
        );
        await tester.pumpAndSettle();
        await binding.takeScreenshot(
          'fixes-profile-${route.split('/').last}-$language',
        );
        router.pop();
        await tester.pumpAndSettle();
        expect(tester.widget<AppShell>(find.byType(AppShell)).index, 3);
      }
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await services.reset();
  });
}
