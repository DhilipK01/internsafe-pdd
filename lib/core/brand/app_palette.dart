import 'package:flutter/material.dart';

/// INTERNSAFE premium cyber-intelligence palette.
abstract final class AppPalette {
  // Core brand
  static const Color emeraldDeep = Color(0xFF062A1F);
  static const Color emeraldCore = Color(0xFF0B7A57);
  static const Color emeraldBright = Color(0xFF12C48A);
  static const Color neonMint = Color(0xFF3DFFA8);
  static const Color neonMintDim = Color(0xFF1A9E6A);

  // Neutrals — dark
  static const Color voidBlack = Color(0xFF04060A);
  static const Color navyVoid = Color(0xFF060B14);
  static const Color navyDeep = Color(0xFF0A111D);
  static const Color navyElevated = Color(0xFF121C2E);
  static const Color navySurface = Color(0xFF182436);
  static const Color graphite = Color(0xFF243044);
  static const Color slateBorder = Color(0xFF2E3F56);

  // Neutrals — light
  static const Color frost = Color(0xFFF3F6FB);
  static const Color pearl = Color(0xFFE8EDF5);
  static const Color mist = Color(0xFFCFD8E8);
  static const Color ink = Color(0xFF0B1220);
  static const Color inkSoft = Color(0xFF3D4F66);

  // Semantic
  static const Color crimson = Color(0xFFFF3B5C);
  static const Color crimsonDeep = Color(0xFFB8183A);
  static const Color amber = Color(0xFFFFB020);
  static const Color amberDeep = Color(0xFFC47A00);
  static const Color trust = Color(0xFF2EE6A6);
  static const Color cyberBlue = Color(0xFF4DA3FF);

  // Text
  static const Color textPrimaryDark = Color(0xFFF0F4FA);
  static const Color textSecondaryDark = Color(0xFF8B9CB5);
  static const Color textPrimaryLight = Color(0xFF0B1220);
  static const Color textSecondaryLight = Color(0xFF5A6B82);

  // Gradients (3+ stops require colorStops on current Flutter)
  static const List<double> stops3 = [0.0, 0.5, 1.0];

  static const LinearGradient brandHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emeraldDeep, navyVoid, Color(0xFF0A1F18)],
    stops: stops3,
  );

  static const LinearGradient brandHeroLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [frost, Color(0xFFE8F2EE), pearl],
    stops: stops3,
  );

  static const LinearGradient brandGlow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A5C45), emeraldDeep],
  );

  static const LinearGradient buttonPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emeraldBright, emeraldCore, Color(0xFF065A40)],
    stops: stops3,
  );

  static const LinearGradient scanPulse = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonMint, emeraldBright, cyberBlue],
    stops: stops3,
  );

  static const LinearGradient glassHighlight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FFFFFF),
      Color(0x08FFFFFF),
    ],
  );

  static Color glow(Color c, {double opacity = 0.45}) =>
      c.withValues(alpha: opacity);
}
