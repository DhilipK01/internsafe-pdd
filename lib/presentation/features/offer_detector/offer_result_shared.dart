import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/application/providers/scan_providers.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/enums/risk_level.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/services/scan_poll_service.dart';
import 'package:internsfe/core/widgets/analysis_pending_card.dart';
import 'package:internsfe/core/widgets/primary_button.dart';
import 'package:internsfe/core/widgets/share_result_button.dart';
import 'package:internsfe/domain/entities/offer_analysis_result.dart';
import 'package:internsfe/domain/repositories/share_repository.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OfferResultBody extends ConsumerStatefulWidget {
  const OfferResultBody({super.key});

  @override
  ConsumerState<OfferResultBody> createState() => _OfferResultBodyState();
}

String _verdictTitle(OfferAnalysisResult analysis) {
  final r = analysis.result.toLowerCase();
  if (r == 'likely_fraud') return 'Scam likely';
  if (r == 'suspicious') return 'Moderate risk';
  return analysis.riskLevel.label;
}

class _OfferResultBodyState extends ConsumerState<OfferResultBody> {
  OfferAnalysisResult? _analysis;
  bool _polling = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final job = ref.read(offerCheckJobProvider);
      if (job != null && (job.isProcessing || job.isPending)) {
        _pollOffer(job.id);
      } else if (job != null && job.isCompleted) {
        _loadOffer(job.id);
      }
    });
  }

  Future<void> _pollOffer(String id) async {
    setState(() => _polling = true);
    try {
      await pollUntilDone<Map<String, dynamic>>(
        fetch: () => ref.read(offerRepositoryProvider).getOfferCheck(id),
        isDone: (row) =>
            row['status'] == 'completed' || row['status'] == 'failed' || row['status'] == 'invalid_document_type',
      );
      await _loadOffer(id);
    } finally {
      if (mounted) setState(() => _polling = false);
    }
  }

  Future<void> _loadOffer(String id) async {
    final row = await ref.read(offerRepositoryProvider).getOfferCheck(id);
    final analysis = OfferAnalysisResult.fromOfferRow(row);
    if (mounted) {
      setState(() {
        _analysis = analysis;
        _statusMessage = row['analysis_summary'] as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(offerCheckJobProvider);
    if (job == null) {
      return const Center(child: Text('No offer check found.'));
    }

    final theme = Theme.of(context);
    final analysis = _analysis;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_polling || job.isProcessing)
            const AnalysisPendingCard(
              message:
                  'Running real fraud detection (rules + NLP) on your offer text…',
            ),
          if (job.isFailed || (analysis == null && job.isCompleted == false && !_polling))
            AnalysisPendingCard(
              message: job.message.isNotEmpty
                  ? job.message
                  : _statusMessage ?? 'Awaiting analysis.',
            ),
          if (analysis != null && analysis.result == 'invalid_document_type') ...[
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      size: 32,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invalid Document Type',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            analysis.summary.isNotEmpty
                                ? analysis.summary
                                : 'Uploaded document is not an Offer Letter or Appointment Letter.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (analysis != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(
                      analysis.isLikelyFraud
                          ? LucideIcons.alertTriangle
                          : LucideIcons.shieldCheck,
                      size: 40,
                      color: analysis.riskLevel.color,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            analysis.isLikelyFraud
                                ? _verdictTitle(analysis)
                                : analysis.riskLevel.label,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(color: analysis.riskLevel.color),
                          ),
                          Text(
                            analysis.isLikelyFraud
                                ? 'Scam indicator confidence: ${analysis.confidence}%'
                                : 'Confidence: ${analysis.confidence}%',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (analysis.summary.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(analysis.summary, style: theme.textTheme.bodyLarge),
            ],
            if (analysis.explanation.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('AI explanation', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(analysis.explanation),
            ],
            if (analysis.reasons.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Triggered checks', style: theme.textTheme.titleMedium),
              ...analysis.reasons.map(
                (r) => ListTile(
                  dense: true,
                  leading: const Icon(LucideIcons.flag, size: 18),
                  title: Text(r),
                ),
              ),
            ],
            if (analysis.actionItems.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('What to do next', style: theme.textTheme.titleMedium),
              ...analysis.actionItems.map((a) => ListTile(
                    dense: true,
                    leading: Icon(LucideIcons.check,
                        size: 18, color: theme.colorScheme.primary),
                    title: Text(a),
                  )),
            ],
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('Reference: ${job.id}', style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          ShareResultButton(
            resourceType: ShareResourceType.offerCheck,
            resourceId: job.id,
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Back',
            onPressed: () => context.go(AppRoutes.offerCheck),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
