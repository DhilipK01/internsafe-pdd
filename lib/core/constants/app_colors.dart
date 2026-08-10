import 'package:flutter/material.dart';
import 'package:internsfe/core/brand/app_palette.dart';

/// Legacy aliases — prefer [AppPalette] for new code.
abstract final class AppColors {
  static const Color primaryGreen = AppPalette.emeraldCore;
  static const Color successGreen = AppPalette.trust;
  static const Color warningAmber = AppPalette.amber;
  static const Color dangerRed = AppPalette.crimson;
  static const Color backgroundLight = AppPalette.frost;
  static const Color backgroundDark = AppPalette.navyVoid;
  static const Color textDark = AppPalette.textPrimaryLight;
  static const Color textLight = AppPalette.textPrimaryDark;
  static const Color cardLight = Colors.white;
  static const Color cardDark = AppPalette.navyElevated;
  static const Color borderLight = AppPalette.mist;
  static const Color borderDark = AppPalette.slateBorder;
  static const Color mutedLight = AppPalette.textSecondaryLight;
  static const Color mutedDark = AppPalette.textSecondaryDark;
  static const Color accentGreenLight = Color(0xFFE6F7F0);
  static const Color accentGreenDark = AppPalette.emeraldDeep;
}
