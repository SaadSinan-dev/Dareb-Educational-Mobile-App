import 'package:flutter/material.dart';

/// Values read from the supplied Design System and native-size icon exports.
abstract final class AppTypography {
  static const arabicFamily = 'NotoSansArabic';
  static const englishFamily = 'Roboto';
  // Default remains Arabic for the supplied design and existing theme callers.
  static const family = arabicFamily;
  static String forLanguage(String languageCode) =>
      languageCode == 'en' ? englishFamily : arabicFamily;
  static List<String> fallbackFor(String languageCode) => [
    languageCode == 'en' ? arabicFamily : englishFamily,
  ];
}

abstract final class AppSpacing {
  static const unit = 4.0;
  static const small = 8.0;
  static const medium = 16.0;
  static const large = 24.0;
}

abstract final class AppIconTokens {
  static const standard = 24.0;
  static const navigationCanvas = 31.0;
  static const profileCanvas = 32.0;
  static const actionBlue = Color(0xFF7CA4F2);
  static const inactiveNavigation = Color(0xFFCDDDFF);
}
