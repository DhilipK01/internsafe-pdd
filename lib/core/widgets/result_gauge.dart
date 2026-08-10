import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:internsfe/core/brand/app_typography.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';

/// Signature trust meter — mono numerics + glow arc.
class ResultGauge extends StatelessWidget {
  const ResultGauge({
    super.key,
    required this.score,
    required this.label,
    required this.color,
    this.maxScore = 100,
    this.diameter = 168,
    this.fontSize = 44,
  });

  final int score;
  final String label;
  final Color color;
  final int maxScore;
  final double diameter;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final progress = score / maxScore;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 28,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: diameter,
                height: diameter,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: context.borderColor,
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutBack,
                  ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: AppTypography.metric(color: color, size: fontSize),
                  ),
                  Text(
                    '/ $maxScore',
                    style: AppTypography.metricLabel(dark: context.isDark),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          label.toUpperCase(),
          style: AppTypography.metricLabel(color: color, dark: context.isDark),
        ),
      ],
    );
  }
}

class ConfidenceGauge extends StatelessWidget {
  const ConfidenceGauge({
    super.key,
    required this.percentage,
    required this.color,
  });

  final int percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ResultGauge(
      score: percentage,
      label: 'Confidence',
      color: color,
      maxScore: 100,
    );
  }
}
