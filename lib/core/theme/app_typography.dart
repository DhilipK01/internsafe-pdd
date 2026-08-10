import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:internsfe/core/brand/app_palette.dart';

/// INTERNSAFE typography — Google Sans–inspired stack via [GoogleFonts].
///
/// Licensed stack (no proprietary Google Sans redistribution):
/// - **Plus Jakarta Sans** — display, headings, UI, body (closest to Google Sans / Product Sans)
/// - **JetBrains Mono** — trust scores, danger scores, analytics
/// - **Inter** — system fallback in [fontFamilyFallback]
///
/// Optional: place licensed `GoogleSans-*.ttf` under `assets/fonts/google_sans/` and
/// set [_useLocalGoogleSans] to true after adding them to [pubspec.yaml].
abstract final class AppTypography {
  static const bool _useLocalGoogleSans = false;
  static const String _localGoogleSansFamily = 'Google Sans';
  static const String _uiFamily = 'Plus Jakarta Sans';
  static const List<String> _fallbackFamilies = [
    'Inter',
    'SF Pro Display',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  // —— Preload at app start (see main.dart) ——————————————————————————————————
  static Future<void> preload() async {
    await GoogleFonts.pendingFonts([
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w300),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      GoogleFonts.outfit(fontWeight: FontWeight.w500),
      GoogleFonts.outfit(fontWeight: FontWeight.w600),
      GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w500),
      GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w600),
    ]);
  }

  // —— Color helpers —————————————————————————————————————————————————————————
  static Color _primary(bool dark) =>
      dark ? AppPalette.textPrimaryDark : AppPalette.textPrimaryLight;

  static Color _secondary(bool dark) =>
      dark ? AppPalette.textSecondaryDark : AppPalette.textSecondaryLight;

  static Color _muted(bool dark) =>
      dark ? AppPalette.textSecondaryDark : AppPalette.textSecondaryLight;

  // —— Core builders —————————————————————————————————————————————————————————
  static TextStyle _sans({
    required double size,
    required FontWeight weight,
    required double height,
    required double letterSpacing,
    Color? color,
    bool dark = true,
  }) {
    if (_useLocalGoogleSans) {
      return TextStyle(
        fontFamily: _localGoogleSansFamily,
        fontFamilyFallback: _fallbackFamilies,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color ?? _primary(dark),
      );
    }
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? _primary(dark),
    ).copyWith(fontFamilyFallback: _fallbackFamilies);
  }

  static TextStyle _mono({
    required double size,
    required FontWeight weight,
    double height = 1.1,
    double letterSpacing = -0.5,
    Color? color,
    bool dark = true,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? AppPalette.neonMint,
    ).copyWith(fontFamilyFallback: const ['Inter', 'monospace']);
  }

  // —— Display (splash, onboarding hero, major AI results) ———————————————————
  static TextStyle displayLarge({Color? color, bool dark = true}) => _sans(
        size: 48,
        weight: FontWeight.w700,
        height: 1.08,
        letterSpacing: -1.4,
        color: color,
        dark: dark,
      );

  static TextStyle displayMedium({Color? color, bool dark = true}) => _sans(
        size: 36,
        weight: FontWeight.w700,
        height: 1.12,
        letterSpacing: -1.0,
        color: color,
        dark: dark,
      );

  static TextStyle displaySmall({Color? color, bool dark = true}) => _sans(
        size: 30,
        weight: FontWeight.w600,
        height: 1.15,
        letterSpacing: -0.6,
        color: color,
        dark: dark,
      );

  // —— Headings (sections, features, analysis titles) ————————————————————————
  static TextStyle headlineLarge({Color? color, bool dark = true}) => _sans(
        size: 26,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.5,
        color: color,
        dark: dark,
      );

  static TextStyle headline({Color? color, bool dark = true}) =>
      headlineMedium(color: color, dark: dark);

  static TextStyle headlineMedium({Color? color, bool dark = true}) => _sans(
        size: 22,
        weight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.35,
        color: color,
        dark: dark,
      );

  static TextStyle headlineSmall({Color? color, bool dark = true}) => _sans(
        size: 20,
        weight: FontWeight.w600,
        height: 1.28,
        letterSpacing: -0.25,
        color: color,
        dark: dark,
      );

  // —— Titles (cards, app bar, list headers) ———————————————————————————————
  static TextStyle titleLarge({Color? color, bool dark = true}) => _sans(
        size: 18,
        weight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.15,
        color: color,
        dark: dark,
      );

  static TextStyle title({Color? color, bool dark = true}) =>
      titleMedium(color: color, dark: dark);

  static TextStyle titleMedium({Color? color, bool dark = true}) => _sans(
        size: 16,
        weight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.1,
        color: color,
        dark: dark,
      );

  static TextStyle titleSmall({Color? color, bool dark = true}) => _sans(
        size: 14,
        weight: FontWeight.w600,
        height: 1.35,
        letterSpacing: 0,
        color: color,
        dark: dark,
      );

  // —— Body (recommendations, reports, assistant) ———————————————————————————
  static TextStyle bodyLarge({Color? color, bool dark = true}) => _sans(
        size: 16,
        weight: FontWeight.w400,
        height: 1.55,
        letterSpacing: 0.1,
        color: color ?? _primary(dark),
        dark: dark,
      );

  static TextStyle body({Color? color, bool dark = true}) =>
      bodyMedium(color: color ?? _secondary(dark), dark: dark);

  static TextStyle bodyMedium({Color? color, bool dark = true}) => _sans(
        size: 14,
        weight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.15,
        color: color ?? _secondary(dark),
        dark: dark,
      );

  static TextStyle bodySmall({Color? color, bool dark = true}) =>
      caption(color: color, dark: dark);

  // —— Labels & captions ———————————————————————————————————————————————————
  static TextStyle labelLarge({Color? color, bool dark = true}) => _sans(
        size: 14,
        weight: FontWeight.w500,
        height: 1.35,
        letterSpacing: 0.2,
        color: color ?? _primary(dark),
        dark: dark,
      );

  static TextStyle label({Color? color, bool dark = true}) =>
      labelMedium(color: color, dark: dark);

  static TextStyle labelMedium({Color? color, bool dark = true}) => _sans(
        size: 13,
        weight: FontWeight.w500,
        height: 1.35,
        letterSpacing: 0.25,
        color: color ?? _primary(dark),
        dark: dark,
      );

  static TextStyle labelSmall({Color? color, bool dark = true}) => _sans(
        size: 11,
        weight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.35,
        color: color ?? _muted(dark),
        dark: dark,
      );

  static TextStyle caption({Color? color, bool dark = true}) => _sans(
        size: 12,
        weight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0.2,
        color: color ?? _muted(dark),
        dark: dark,
      );

  static TextStyle overline({Color? color, bool dark = true}) => _sans(
        size: 11,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 1.1,
        color: color ?? _muted(dark),
        dark: dark,
      );

  // —— Buttons ———————————————————————————————————————————————————————————————
  static TextStyle button({Color? color, bool dark = true}) => _sans(
        size: 15,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.1,
        color: color,
        dark: dark,
      );

  // —— Brand & AI surfaces ———————————————————————————————————————————————————
  static TextStyle brandWordmark({Color? color, bool dark = false}) =>
      GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.05,
        letterSpacing: -0.5,
        color: color ??
            (dark ? AppPalette.textPrimaryDark : AppPalette.textPrimaryLight),
      );

  static TextStyle brandAiTag({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: color ?? AppPalette.emeraldBright,
      );

  static TextStyle onboardingSubtitle({Color? color, bool dark = true}) =>
      _sans(
        size: 17,
        weight: FontWeight.w300,
        height: 1.5,
        letterSpacing: 0.2,
        color: color ?? _secondary(dark),
        dark: dark,
      );

  static TextStyle assistant({Color? color, bool dark = true}) => bodyLarge(
        color: color,
        dark: dark,
      );

  // —— Analytics / scores ————————————————————————————————————————————————————
  static TextStyle metric({Color? color, double size = 44, bool dark = true}) =>
      _mono(
        size: size,
        weight: FontWeight.w600,
        letterSpacing: -1.2,
        color: color ?? AppPalette.neonMint,
        dark: dark,
      );

  static TextStyle metricLarge({Color? color, bool dark = true}) =>
      metric(color: color, size: 56, dark: dark);

  static TextStyle metricSmall({Color? color, bool dark = true}) =>
      metric(color: color, size: 32, dark: dark);

  static TextStyle metricLabel({Color? color, bool dark = true}) => _mono(
        size: 11,
        weight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 1.4,
        color: color ?? _muted(dark),
        dark: dark,
      );

  static TextStyle analyticsValue({Color? color, bool dark = true}) => _mono(
        size: 24,
        weight: FontWeight.w600,
        letterSpacing: -0.8,
        color: color ?? _primary(dark),
        dark: dark,
      );

  /// Default UI font family for [ThemeData.fontFamily].
  static String get uiFontFamily =>
      _useLocalGoogleSans ? _localGoogleSansFamily : _uiFamily;

  /// Full Material 3 [TextTheme] for [ThemeData].
  static TextTheme materialTextTheme({required bool isDark}) {
    return TextTheme(
      displayLarge: displayLarge(dark: isDark),
      displayMedium: displayMedium(dark: isDark),
      displaySmall: displaySmall(dark: isDark),
      headlineLarge: headlineLarge(dark: isDark),
      headlineMedium: headlineMedium(dark: isDark),
      headlineSmall: headlineSmall(dark: isDark),
      titleLarge: titleLarge(dark: isDark),
      titleMedium: titleMedium(dark: isDark),
      titleSmall: titleSmall(dark: isDark),
      bodyLarge: bodyLarge(dark: isDark),
      bodyMedium: bodyMedium(dark: isDark),
      bodySmall: bodySmall(dark: isDark),
      labelLarge: labelLarge(dark: isDark),
      labelMedium: labelMedium(dark: isDark),
      labelSmall: labelSmall(dark: isDark),
    );
  }

  /// Primary text theme merged into [ThemeData] (disables implicit Roboto).
  static TextTheme themeTextTheme({required bool isDark}) {
    final base = materialTextTheme(isDark: isDark);
    if (_useLocalGoogleSans) return base;
    return GoogleFonts.plusJakartaSansTextTheme(base);
  }
}

/// [ThemeExtension] for score / brand styles outside [TextTheme].
@immutable
class AppTypographyExtension extends ThemeExtension<AppTypographyExtension> {
  const AppTypographyExtension({
    required this.metric,
    required this.metricLabel,
    required this.brandWordmark,
    required this.button,
    required this.onboardingSubtitle,
  });

  final TextStyle metric;
  final TextStyle metricLabel;
  final TextStyle brandWordmark;
  final TextStyle button;
  final TextStyle onboardingSubtitle;

  factory AppTypographyExtension.forBrightness(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return AppTypographyExtension(
      metric: AppTypography.metric(dark: dark),
      metricLabel: AppTypography.metricLabel(dark: dark),
      brandWordmark: AppTypography.brandWordmark(),
      button: AppTypography.button(dark: dark),
      onboardingSubtitle: AppTypography.onboardingSubtitle(dark: dark),
    );
  }

  @override
  AppTypographyExtension copyWith({
    TextStyle? metric,
    TextStyle? metricLabel,
    TextStyle? brandWordmark,
    TextStyle? button,
    TextStyle? onboardingSubtitle,
  }) {
    return AppTypographyExtension(
      metric: metric ?? this.metric,
      metricLabel: metricLabel ?? this.metricLabel,
      brandWordmark: brandWordmark ?? this.brandWordmark,
      button: button ?? this.button,
      onboardingSubtitle: onboardingSubtitle ?? this.onboardingSubtitle,
    );
  }

  @override
  AppTypographyExtension lerp(
    ThemeExtension<AppTypographyExtension>? other,
    double t,
  ) {
    if (other is! AppTypographyExtension) return this;
    return AppTypographyExtension(
      metric: TextStyle.lerp(metric, other.metric, t)!,
      metricLabel: TextStyle.lerp(metricLabel, other.metricLabel, t)!,
      brandWordmark: TextStyle.lerp(brandWordmark, other.brandWordmark, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
      onboardingSubtitle:
          TextStyle.lerp(onboardingSubtitle, other.onboardingSubtitle, t)!,
    );
  }
}
