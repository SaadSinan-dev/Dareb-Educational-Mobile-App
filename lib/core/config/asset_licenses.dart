import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void registerAssetLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final name in [
      'icon-credits',
      'Lucide-LICENSE',
      'Iconoir-LICENSE',
      'MaterialSymbols-LICENSE',
      'WeUI-LICENSE',
      'NotoSansArabic-OFL',
      'Roboto-OFL',
    ]) {
      yield LicenseEntryWithLineBreaks([
        'Dareb design assets',
      ], await rootBundle.loadString('assets/licenses/$name.txt'));
    }
  });
}
