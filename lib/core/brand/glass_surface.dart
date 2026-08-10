import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:internsfe/core/brand/app_elevation.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/constants/app_spacing.dart';

/// Signature INTERNSAFE card — glass layer + glow edge.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.accentColor,
    this.borderRadius = AppSpacing.cardRadius,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? accentColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? AppPalette.emeraldBright;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppPalette.navyElevated.withValues(alpha: 0.92),
                          AppPalette.navySurface.withValues(alpha: 0.78),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          AppPalette.frost.withValues(alpha: 0.88),
                        ],
                ),
                border: AppElevation.signatureBorder(isDark, accent: accent),
                boxShadow: AppElevation.card(isDark),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Ambient mesh background for hero sections.
class BrandMeshBackground extends StatelessWidget {
  const BrandMeshBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: isDark ? AppPalette.brandHero : AppPalette.brandHeroLight,
          ),
        ),
        if (isDark)
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.neonMint.withValues(alpha: 0.12),
                    blurRadius: 80,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
        child,
      ],
    );
  }
}
