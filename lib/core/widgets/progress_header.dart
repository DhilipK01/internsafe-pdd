import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/brand/app_typography.dart';
import 'package:internsfe/core/brand/internsafe_logo.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';

/// Signature scan pulse — neural ring + brand mark.
class ProgressHeader extends StatelessWidget {
  const ProgressHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    this.icon,
  });

  final String title;
  final String subtitle;
  final double progress;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 132,
              height: 132,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                backgroundColor: context.borderColor,
                color: AppPalette.neonMint,
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .rotate(duration: 4000.ms),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.neonMint.withValues(alpha: 0.2),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const InternsafeLogo(size: 72, showGlow: true, animate: true),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(title, style: AppTypography.headline(dark: context.isDark)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: AppTypography.body(dark: context.isDark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: context.borderColor,
            color: AppPalette.emeraldBright,
          ),
        ),
      ],
    );
  }
}
