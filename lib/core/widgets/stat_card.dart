import 'package:flutter/material.dart';
import 'package:internsfe/core/brand/app_typography.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/widgets/info_card.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? context.accentColor;
    return InfoCard(
      borderColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: AppTypography.metric(color: accent, size: 28),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.caption(dark: context.isDark)),
        ],
      ),
    );
  }
}
