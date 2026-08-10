import 'package:flutter/material.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/theme/app_typography.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;

  /// Google Sans–inspired typography tokens (Plus Jakarta Sans stack).
  AppTypographyExtension get typography =>
      theme.extension<AppTypographyExtension>()!;
  ColorScheme get colorScheme => theme.colorScheme;
  bool get isDark => theme.brightness == Brightness.dark;

  Color get surfaceColor =>
      isDark ? AppPalette.navyElevated : Colors.white;
  Color get mutedColor =>
      isDark ? AppPalette.textSecondaryDark : AppPalette.textSecondaryLight;
  Color get borderColor =>
      isDark ? AppPalette.slateBorder : AppPalette.mist;
  Color get accentColor =>
      isDark ? AppPalette.neonMint : AppPalette.emeraldCore;
}
