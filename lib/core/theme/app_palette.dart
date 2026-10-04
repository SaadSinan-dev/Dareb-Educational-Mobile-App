import 'package:flutter/material.dart';

/// Semantic colors shared by Material and the custom design components.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.secondary,
    required this.primaryDark,
    required this.background,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.border,
    required this.accent,
    required this.onBrand,
    required this.softBlue,
    required this.softTeal,
    required this.skeleton,
    required this.error,
    required this.success,
    required this.shadow,
    required this.tabIdle,
    required this.successSoft,
    required this.errorSoft,
    required this.splashStart,
    required this.splashEnd,
  });

  final Color primary, secondary, primaryDark, background, surface;
  final Color ink, muted, border, accent, onBrand;
  final Color softBlue, softTeal, skeleton, error, success, shadow;
  final Color tabIdle, successSoft, errorSoft;
  final Color splashStart, splashEnd;

  static const light = AppPalette(
    primary: Color(0xFF2FB8BB),
    secondary: Color(0xFF598AF4),
    primaryDark: Color(0xFF148F98),
    background: Colors.white,
    surface: Colors.white,
    ink: Color(0xFF243237),
    muted: Color(0xFF7D8A8D),
    border: Color(0xFFE5EBEC),
    accent: Color(0xFFFFC661),
    onBrand: Colors.white,
    softBlue: Color(0xFFE1E8FF),
    softTeal: Color(0xFFF1FCFC),
    skeleton: Color(0xFFE8ECEF),
    error: Color(0xFFD74395),
    success: Color(0xFF50C665),
    shadow: Color(0xAA161616),
    tabIdle: Color(0xFFF4F7FA),
    successSoft: Color(0xFFE1FFE9),
    errorSoft: Color(0xFFFFECEC),
    splashStart: Color(0xFF2FB8BB),
    splashEnd: Color(0xFF7EBFC1),
  );

  static const dark = AppPalette(
    primary: Color(0xFF53C9CC),
    secondary: Color(0xFF91B0FF),
    primaryDark: Color(0xFF32B2B8),
    background: Color(0xFF10191D),
    surface: Color(0xFF19262B),
    ink: Color(0xFFF0F7F7),
    muted: Color(0xFFB0C0C2),
    border: Color(0xFF34474D),
    accent: Color(0xFFFFCE75),
    onBrand: Color(0xFF071719),
    softBlue: Color(0xFF26395B),
    softTeal: Color(0xFF17363B),
    skeleton: Color(0xFF2A3C42),
    error: Color(0xFFFF829F),
    success: Color(0xFF8FE4A0),
    shadow: Color(0x99000000),
    tabIdle: Color(0xFF1D2D33),
    successSoft: Color(0xFF173A27),
    errorSoft: Color(0xFF4A262F),
    splashStart: Color(0xFF173A3C),
    splashEnd: Color(0xFF205357),
  );

  @override
  AppPalette copyWith({
    Color? primary,
    Color? secondary,
    Color? primaryDark,
    Color? background,
    Color? surface,
    Color? ink,
    Color? muted,
    Color? border,
    Color? accent,
    Color? onBrand,
    Color? softBlue,
    Color? softTeal,
    Color? skeleton,
    Color? error,
    Color? success,
    Color? shadow,
    Color? tabIdle,
    Color? successSoft,
    Color? errorSoft,
    Color? splashStart,
    Color? splashEnd,
  }) => AppPalette(
    primary: primary ?? this.primary,
    secondary: secondary ?? this.secondary,
    primaryDark: primaryDark ?? this.primaryDark,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    border: border ?? this.border,
    accent: accent ?? this.accent,
    onBrand: onBrand ?? this.onBrand,
    softBlue: softBlue ?? this.softBlue,
    softTeal: softTeal ?? this.softTeal,
    skeleton: skeleton ?? this.skeleton,
    error: error ?? this.error,
    success: success ?? this.success,
    shadow: shadow ?? this.shadow,
    tabIdle: tabIdle ?? this.tabIdle,
    successSoft: successSoft ?? this.successSoft,
    errorSoft: errorSoft ?? this.errorSoft,
    splashStart: splashStart ?? this.splashStart,
    splashEnd: splashEnd ?? this.splashEnd,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      primary: mix(primary, other.primary),
      secondary: mix(secondary, other.secondary),
      primaryDark: mix(primaryDark, other.primaryDark),
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      border: mix(border, other.border),
      accent: mix(accent, other.accent),
      onBrand: mix(onBrand, other.onBrand),
      softBlue: mix(softBlue, other.softBlue),
      softTeal: mix(softTeal, other.softTeal),
      skeleton: mix(skeleton, other.skeleton),
      error: mix(error, other.error),
      success: mix(success, other.success),
      shadow: mix(shadow, other.shadow),
      tabIdle: mix(tabIdle, other.tabIdle),
      successSoft: mix(successSoft, other.successSoft),
      errorSoft: mix(errorSoft, other.errorSoft),
      splashStart: mix(splashStart, other.splashStart),
      splashEnd: mix(splashEnd, other.splashEnd),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
