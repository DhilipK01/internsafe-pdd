import 'package:flutter/material.dart';
import 'package:internsfe/core/constants/app_colors.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/brand/app_typography.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/widgets/info_card.dart';
import 'package:internsfe/core/widgets/safety_badge.dart';
import 'package:internsfe/core/enums/risk_level.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.companyName,
    required this.reportType,
    required this.date,
    required this.college,
    this.dangerScore,
    this.onTap,
  });

  final String companyName;
  final String reportType;
  final String date;
  final String college;
  final int? dangerScore;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  companyName,
                  style: context.textTheme.titleMedium,
                ),
              ),
              if (dangerScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.dangerRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$dangerScore',
                    style: AppTypography.analyticsValue(
                      color: AppColors.dangerRed,
                      dark: context.isDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const SafetyBadge(level: RiskLevel.danger, compact: true),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(LucideIcons.flag, size: 14, color: context.mutedColor),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(reportType, style: context.textTheme.bodySmall),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(LucideIcons.graduationCap,
                  size: 14, color: context.mutedColor),
              const SizedBox(width: AppSpacing.xs),
              Text(college, style: context.textTheme.bodySmall),
              const Spacer(),
              Text(date, style: context.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.time,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String time;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textTheme.titleMedium),
                Text(subtitle, style: context.textTheme.bodySmall),
              ],
            ),
          ),
          Text(time, style: context.textTheme.bodySmall),
        ],
      ),
    );
  }
}
