import 'package:flutter/material.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';

/// Grand Hotel branding — app title only. All other UI uses Plus Jakarta Sans.
abstract final class BrandTypography {
  static const String fontFamily = 'GrandHotel';

  static TextStyle appTitle(
    BuildContext context, {
    double fontSize = 34,
    bool includeAiSuffix = true,
  }) {
    final isDark = context.isDark;
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.05,
      color: isDark ? AppPalette.textPrimaryDark : AppPalette.ink,
    );
  }

  static TextStyle appTitleAi(BuildContext context, {double fontSize = 14}) {
    return TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      height: 1.0,
      color: AppPalette.emeraldBright,
    );
  }
}
