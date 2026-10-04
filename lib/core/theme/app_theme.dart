import 'design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';

abstract final class AppRadius {
  static const card = 22.0;
  static const control = 10.0;
  static const pill = 100.0;
}

abstract final class AppTheme {
  static ThemeData get light => _build(AppPalette.light, Brightness.light);
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  static ThemeData lightFor(String languageCode) =>
      _build(AppPalette.light, Brightness.light, languageCode);
  static ThemeData darkFor(String languageCode) =>
      _build(AppPalette.dark, Brightness.dark, languageCode);

  static ThemeData _build(
    AppPalette colors,
    Brightness brightness, [
    String languageCode = 'ar',
  ]) => ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: AppTypography.forLanguage(languageCode),
    fontFamilyFallback: AppTypography.fallbackFor(languageCode),
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onBrand,
      secondary: colors.secondary,
      surface: colors.surface,
      onSurface: colors.ink,
      error: colors.error,
    ),
    extensions: [colors],
    scaffoldBackgroundColor: colors.background,
    canvasColor: colors.background,
    cardColor: colors.surface,
    dividerColor: colors.border,
    dialogTheme: DialogThemeData(backgroundColor: colors.surface),
    cardTheme: CardThemeData(color: colors.surface),
    iconTheme: IconThemeData(color: colors.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.w700,
        color: colors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: colors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: colors.ink,
      ),
      bodyLarge: TextStyle(fontSize: 15, color: colors.ink),
      bodyMedium: TextStyle(fontSize: 13, color: colors.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      hintStyle: TextStyle(color: colors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: colors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onBrand,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.secondary,
        side: BorderSide(color: colors.secondary),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: colors.primary),
    ),
  );
}
