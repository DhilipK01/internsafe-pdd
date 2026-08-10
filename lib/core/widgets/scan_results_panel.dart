import 'package:flutter/material.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/enums/risk_level.dart';
import 'package:internsfe/domain/entities/scan_analysis_result.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ScanResultsPanel extends StatelessWidget {
  const ScanResultsPanel({super.key, required this.result});

  final ScanAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ScoreCard(result: result),
        if (result.ocrConfidence != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'OCR confidence: ${(result.ocrConfidence! * 100).toStringAsFixed(0)}%',
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (result.explanation.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('AI guidance', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(result.explanation),
        ],
        if (result.findings.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Detected issues (${result.findings.length})',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...result.findings.map((f) => _FindingTile(finding: f)),
        ],
        if (result.actionItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Recommended actions', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...result.actionItems.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.checkCircle2,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(a)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.result});

  final ScanAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = result.safetyScore;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(LucideIcons.shield, size: 40, color: result.riskLevel.color),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    score != null ? 'Safety score: $score/100' : 'Analysis complete',
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    'Risk: ${result.riskLevel.label}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: result.riskLevel.color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FindingTile extends StatelessWidget {
  const _FindingTile({required this.finding});

  final ScanFinding finding;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(finding.type.replaceAll('_', ' ').toUpperCase()),
        subtitle: Text(
          [
            finding.value,
            if (finding.confidence != null)
              'Confidence: ${(finding.confidence! * 100).toStringAsFixed(0)}%',
            if (finding.reason != null) finding.reason,
            if (finding.recommendation != null) finding.recommendation,
          ].whereType<String>().join('\n'),
        ),
        trailing: Chip(
          label: Text(finding.riskLevel),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
