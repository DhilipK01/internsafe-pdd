import 'package:flutter/material.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/brand/internsafe_logo.dart';
import 'package:internsfe/core/brand/app_typography.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/widgets/info_card.dart';

class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      onTap: onTap,
      borderColor: color,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.title(dark: context.isDark)),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTypography.caption(dark: context.isDark)),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: context.mutedColor,
          ),
        ],
      ),
    );
  }
}

class ProtectionStatusCard extends StatelessWidget {
  const ProtectionStatusCard({
    super.key,
    required this.status,
    required this.message,
    required this.score,
  });

  final String status;
  final String message;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppPalette.buttonPrimary,
        borderRadius: BorderRadius.circular(AppSpacing.heroRadius),
        border: Border.all(
          color: AppPalette.neonMint.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.emeraldBright.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const InternsafeLogo(size: 28, showGlow: false),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppPalette.neonMint.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '$score ACTIVITY',
                  style: AppTypography.metricLabel(
                    color: AppPalette.neonMint,
                    dark: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            status,
            style: AppTypography.headline(color: AppPalette.textPrimaryDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.body(
              color: AppPalette.textPrimaryDark.withValues(alpha: 0.88),
              dark: true,
            ),
          ),
        ],
      ),
    );
  }
}
