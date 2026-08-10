import 'package:flutter/material.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/enums/risk_level.dart';

class RiskChip extends StatelessWidget {
  const RiskChip({
    super.key,
    required this.label,
    required this.level,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final RiskLevel level;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      selectedColor: level.color.withValues(alpha: 0.2),
      checkmarkColor: level.color,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? level.color : null,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
      side: BorderSide(
        color: selected ? level.color : Colors.grey.withValues(alpha: 0.3),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
    );
  }
}
