import 'package:flutter/material.dart';
import 'package:internsfe/core/brand/app_palette.dart';

abstract final class AppElevation {
  static List<BoxShadow> card(bool isDark) => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppPalette.glow(AppPalette.neonMint, opacity: 0.06),
            blurRadius: 32,
            spreadRadius: -4,
          ),
        ]
      : [
          BoxShadow(
            color: AppPalette.ink.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ];

  static List<BoxShadow> glowAccent(Color color, {double intensity = 0.35}) => [
        BoxShadow(
          color: color.withValues(alpha: intensity),
          blurRadius: 20,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: color.withValues(alpha: intensity * 0.5),
          blurRadius: 40,
          spreadRadius: -8,
        ),
      ];

  static Border signatureBorder(bool isDark, {Color? accent}) {
    final c = accent ?? (isDark ? AppPalette.neonMint : AppPalette.emeraldCore);
    return Border.all(
      color: c.withValues(alpha: isDark ? 0.22 : 0.18),
      width: 1,
    );
  }
}
