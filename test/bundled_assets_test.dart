import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/widgets/source_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'dynamic artwork, source icons, font and licenses remain bundled',
    () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();
      final required = [
        for (final icon in SourceIconName.values) 'assets/icons/${icon.asset}',
        for (final tab in ['home', 'learning', 'gallery', 'profile'])
          'assets/icons/nav_$tab.png',
        for (final art in ['graduates', 'student', 'teacher'])
          'assets/illustrations/$art.png',
        for (final image in [
          'avatar',
          'lesson_intro',
          'news',
          'logo_white',
          'logo_color',
        ])
          'assets/images/$image.png',
        for (final social in ['facebook', 'instagram', 'telegram', 'whatsapp'])
          'assets/images/about_$social.png',
        for (final category in ['math', 'science', 'social'])
          'assets/icons/$category.png',
        'assets/icons/header_notification.png',
        'assets/icons/activity.png',
        'assets/icons/quiz.png',
      ];
      expect(assets, containsAll(required));
      for (final path in assets.where(
        (path) => path.startsWith('assets/') && path.endsWith('.png'),
      )) {
        final bytes = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        final frame = await codec.getNextFrame();
        expect(frame.image.width, greaterThan(0), reason: path);
        frame.image.dispose();
        codec.dispose();
      }
      for (final family in ['NotoSansArabic', 'Roboto']) {
        final font = await rootBundle.load('assets/fonts/$family.ttf');
        expect(font.lengthInBytes, greaterThan(0));
        await (FontLoader(
          'AssetAudit$family',
        )..addFont(Future.value(font))).load();
      }
      for (final license in [
        'icon-credits.txt',
        'Lucide-LICENSE.txt',
        'Iconoir-LICENSE.txt',
        'MaterialSymbols-LICENSE.txt',
        'WeUI-LICENSE.txt',
        'NotoSansArabic-OFL.txt',
        'Roboto-OFL.txt',
      ]) {
        expect(
          await rootBundle.loadString('assets/licenses/$license'),
          isNotEmpty,
        );
      }
    },
  );
}
