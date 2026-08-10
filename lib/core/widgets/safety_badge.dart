import 'package:flutter/material.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/enums/risk_level.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SafetyBadge extends StatelessWidget {
  const SafetyBadge({
    super.key,
    required this.level,
    this.compact = false,
  });

  final RiskLevel level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.md : AppSpacing.lg,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: level.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(compact ? 12 : 20),
        border: Border.all(color: level.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _iconFor(level),
            size: compact ? 14 : 18,
            color: level.color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            level.label,
            style: (compact
                    ? context.textTheme.labelSmall
                    : context.textTheme.labelMedium)
                ?.copyWith(
              color: level.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(RiskLevel level) => switch (level) {
        RiskLevel.safe || RiskLevel.genuine => LucideIcons.shieldCheck,
        RiskLevel.warning || RiskLevel.suspicious => LucideIcons.alertTriangle,
        RiskLevel.danger || RiskLevel.fake => LucideIcons.shieldOff,
      };
}
