import 'package:flutter/material.dart';
import 'package:internsfe/core/constants/app_colors.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';

class TimelineItem extends StatelessWidget {
  const TimelineItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    this.color = AppColors.primaryGreen,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final String time;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: context.borderColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: context.textTheme.titleMedium,
                        ),
                      ),
                      Text(time, style: context.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: context.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
