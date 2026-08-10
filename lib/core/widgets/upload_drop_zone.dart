import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/brand/app_typography.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:lucide_icons/lucide_icons.dart';

class UploadDropZone extends StatelessWidget {
  const UploadDropZone({
    super.key,
    required this.title,
    this.subtitle,
    this.onTap,
    this.icon = LucideIcons.upload,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.heroRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xxl,
            horizontal: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.heroRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppPalette.navySurface.withValues(alpha: 0.6),
                      AppPalette.emeraldDeep.withValues(alpha: 0.35),
                    ]
                  : [
                      const Color(0xFFE6F7F0),
                      Colors.white,
                    ],
            ),
            border: Border.all(
              color: AppPalette.emeraldBright.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppPalette.emeraldBright.withValues(alpha: 0.12),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppPalette.scanPulse,
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.neonMint.withValues(alpha: 0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Icon(icon, color: AppPalette.ink, size: 30),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.06, 1.06),
                    duration: 1800.ms,
                  ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: AppTypography.title(dark: isDark),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle!,
                  style: AppTypography.caption(dark: isDark),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
