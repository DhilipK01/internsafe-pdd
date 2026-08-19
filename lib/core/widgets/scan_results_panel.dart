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
    final isNonResume = result.isResume == false || result.status == 'invalid_document_type';

    if (isNonResume) {
      return Card(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.alertTriangle, size: 36, color: theme.colorScheme.error),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Invalid Document Type',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                result.message ??
                    'The uploaded document does not appear to be a Resume or CV. Please upload a valid resume containing standard sections like Experience, Education, or Skills.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ScoreCard(result: result),
        if (result.sectionChecks != null && result.sectionChecks!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Resume Section Check', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: result.sectionChecks!.entries.map((entry) {
              final label = entry.key.replaceAll('_', ' ').toUpperCase();
              final ok = entry.value;
              return Chip(
                avatar: Icon(
                  ok ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
                  size: 16,
                  color: ok ? Colors.green : Colors.orange,
                ),
                label: Text(label),
                backgroundColor: ok
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
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
    final safety = result.safetyScore;
    final quality = result.qualityScore;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                Icon(LucideIcons.shield, size: 36, color: result.riskLevel.color),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        safety != null ? 'Privacy Safety: $safety/100' : 'Analysis complete',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Risk: ${result.riskLevel.label}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: result.riskLevel.color, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (quality != null && quality > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$quality/100',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          'ATS Quality',
                          style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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
