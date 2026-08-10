import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/scan_providers.dart';
import 'package:internsfe/core/constants/app_colors.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/widgets/primary_button.dart';
import 'package:internsfe/core/widgets/result_gauge.dart';
import 'package:internsfe/core/widgets/safety_badge.dart';
import 'package:internsfe/core/widgets/share_result_button.dart';
import 'package:internsfe/domain/entities/company_verification.dart';
import 'package:internsfe/domain/repositories/share_repository.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CompanyResultBody extends ConsumerWidget {
  const CompanyResultBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(companyResultProvider);
    if (result == null) {
      return const Center(child: Text('No verification loaded'));
    }

    final trustColor = _scoreColor(result.trustScore);
    final confidenceColor = _scoreColor(result.confidence);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            result.companyName,
            style: context.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          _ScoreGaugesRow(
            trustScore: result.trustScore,
            trustColor: trustColor,
            confidence: result.confidence,
            confidenceColor: confidenceColor,
          ),
          const SizedBox(height: AppSpacing.md),
          SafetyBadge(level: result.status),
          if (result.analyzedAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Analyzed: ${result.analyzedAt}',
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(color: context.mutedColor),
            ),
          ],
          if (result.evidenceCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '${result.evidenceCount} evidence signal(s) analyzed',
                textAlign: TextAlign.center,
                style: context.textTheme.labelSmall?.copyWith(color: context.mutedColor),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          _GlassSection(
            icon: LucideIcons.brain,
            title: 'AI analysis',
            child: Text(
              result.recommendation,
              style: context.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (result.communityIntelligence != null)
            _CommunityIntelligenceSection(intel: result.communityIntelligence!),
          const SizedBox(height: AppSpacing.md),
          _CommunityReportsCard(result: result),
          if (_hasInternetIntel(result)) ...[
            const SizedBox(height: AppSpacing.md),
            _InternetIntelligenceSection(result: result),
          ],
          if (result.positiveIndicators.isNotEmpty ||
              result.warningIndicators.isNotEmpty ||
              result.dangerIndicators.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _RiskFactorsSection(result: result),
          ],
          if (result.suspiciousIndicators.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _GlassSection(
              icon: LucideIcons.radar,
              title: 'Public signals',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: result.suspiciousIndicators
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text('• $s', style: context.textTheme.bodySmall),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          if (result.badges.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            ...result.badges
                .where(
                  (b) =>
                      b.label != 'Internet intelligence' || !_hasInternetIntel(result),
                )
                .map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _GlassSection(
                      icon: b.verified
                          ? LucideIcons.badgeCheck
                          : LucideIcons.alertTriangle,
                      title: b.label,
                      child: Text(b.detail, style: context.textTheme.bodySmall),
                    ),
                  ),
                ),
          ],
          const SizedBox(height: AppSpacing.lg),
          ShareResultButton(
            resourceType: ShareResourceType.companyVerify,
            companyName: result.companyName,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: 'Done', onPressed: () => context.pop()),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 70) return AppColors.successGreen;
    if (score >= 45) return AppColors.warningAmber;
    if (score > 0) return AppColors.dangerRed;
    return AppColors.mutedLight;
  }

  static bool _hasInternetIntel(CompanyVerification result) {
    final intel = result.internetIntelligence;
    if (intel == null && (result.internetSummary?.isEmpty ?? true)) {
      return false;
    }
    if (intel != null &&
        (intel.snippetCount > 0 ||
            intel.reputationSummary?.isNotEmpty == true ||
            intel.internetStatus == 'completed' ||
            intel.internetStatus == 'partial')) {
      return true;
    }
    return result.internetSummary?.isNotEmpty == true;
  }
}

class _ScoreGaugesRow extends StatelessWidget {
  const _ScoreGaugesRow({
    required this.trustScore,
    required this.trustColor,
    required this.confidence,
    required this.confidenceColor,
  });

  final int trustScore;
  final Color trustColor;
  final int confidence;
  final Color confidenceColor;

  @override
  Widget build(BuildContext context) {
    const gaugeSize = 132.0;
    const gaugeFont = 36.0;

    Widget trustGauge() => ResultGauge(
          score: trustScore,
          label: 'Trust score',
          color: trustColor,
          diameter: gaugeSize,
          fontSize: gaugeFont,
        );

    Widget confidenceGauge() => ResultGauge(
          score: confidence,
          label: 'AI confidence',
          color: confidenceColor,
          diameter: gaugeSize,
          fontSize: gaugeFont,
        );

    if (confidence <= 0) {
      return Center(child: trustGauge());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = constraints.maxWidth < 340;
        if (stackVertically) {
          return Column(
            children: [
              trustGauge(),
              const SizedBox(height: AppSpacing.xl),
              confidenceGauge(),
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(child: Center(child: trustGauge())),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: Center(child: confidenceGauge())),
            ],
          ),
        );
      },
    );
  }
}

class _CommunityIntelligenceSection extends StatelessWidget {
  const _CommunityIntelligenceSection({required this.intel});

  final CompanyCommunityIntel intel;

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      icon: LucideIcons.users,
      title: 'Community intelligence',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${intel.totalReports} report(s) in INTERNSAFE',
            style: context.textTheme.titleSmall,
          ),
          if (intel.aiSummary != null && intel.aiSummary!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(intel.aiSummary!, style: context.textTheme.bodyMedium),
          ],
          if (intel.fraudTypeBreakdown.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: intel.fraudTypeBreakdown
                  .map(
                    (f) => _IntelChip(
                      label: f.type,
                      value: '${f.count}',
                      highlight: f.count >= 2,
                    ),
                  )
                  .toList(),
            ),
          ],
          if (intel.summaries.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...intel.summaries.take(4).map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $s', style: context.textTheme.bodySmall),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _CommunityReportsCard extends StatelessWidget {
  const _CommunityReportsCard({required this.result});

  final CompanyVerification result;

  @override
  Widget build(BuildContext context) {
    final hasReports = result.hasCommunityReports;
    final color = hasReports ? AppColors.dangerRed : AppColors.successGreen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.companyCommunityReportsFor(result.companyName),
        ),
        borderRadius: BorderRadius.circular(16),
        child: _GlassSection(
          icon: LucideIcons.users,
          title: 'Community reports',
          trailing: Icon(LucideIcons.chevronRight, color: context.mutedColor),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${result.reportCount}',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  hasReports
                      ? 'Tap to view ${result.reportCount} report(s) from INTERNSAFE database'
                      : 'No reports yet — tap to search community database',
                  style: context.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InternetIntelligenceSection extends StatelessWidget {
  const _InternetIntelligenceSection({required this.result});

  final CompanyVerification result;

  @override
  Widget build(BuildContext context) {
    final intel = result.internetIntelligence;
    final summary = intel?.reputationSummary ?? result.internetSummary ?? '';

    return _GlassSection(
      icon: LucideIcons.globe,
      title: 'Internet intelligence',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary.isNotEmpty)
            Text(summary, style: context.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (intel != null) ...[
                _IntelChip(
                  label: 'Web complaints',
                  value: '${intel.complaintCount}',
                  highlight: intel.complaintCount > 0,
                ),
                _IntelChip(
                  label: 'Snippets',
                  value: '${intel.snippetCount}',
                ),
                if (intel.webTrustScore != null)
                  _IntelChip(
                    label: 'Web trust',
                    value: '${intel.webTrustScore}',
                  ),
                _IntelChip(
                  label: 'Positive',
                  value: '${intel.positiveMentions}',
                ),
                _IntelChip(
                  label: 'Hiring signals',
                  value: '${intel.hiringMentions}',
                ),
              ],
              if (result.activityStatus != null)
                _IntelChip(
                  label: 'Activity',
                  value: _formatActivity(result.activityStatus!),
                ),
            ],
          ),
          if (intel?.activitySummary != null &&
              intel!.activitySummary!.isNotEmpty &&
              intel.activitySummary != intel.reputationSummary) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              intel.activitySummary!,
              style: context.textTheme.bodySmall?.copyWith(color: context.mutedColor),
            ),
          ],
          if (intel?.evidenceSnippets.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Evidence snippets', style: context.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            ...intel!.evidenceSnippets.take(3).map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      '“${s.length > 120 ? '${s.substring(0, 120)}…' : s}”',
                      style: context.textTheme.bodySmall
                          ?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  String _formatActivity(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class _RiskFactorsSection extends StatelessWidget {
  const _RiskFactorsSection({required this.result});

  final CompanyVerification result;

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      icon: LucideIcons.shield,
      title: 'Risk factors',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.positiveIndicators.isNotEmpty)
            _FactorGroup(
              title: 'Positive',
              color: AppColors.successGreen,
              items: result.positiveIndicators,
            ),
          if (result.warningIndicators.isNotEmpty)
            _FactorGroup(
              title: 'Warnings',
              color: AppColors.warningAmber,
              items: result.warningIndicators,
            ),
          if (result.dangerIndicators.isNotEmpty)
            _FactorGroup(
              title: 'Danger',
              color: AppColors.dangerRed,
              items: result.dangerIndicators,
            ),
        ],
      ),
    );
  }
}

class _FactorGroup extends StatelessWidget {
  const _FactorGroup({
    required this.title,
    required this.color,
    required this.items,
  });

  final String title;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textTheme.labelLarge?.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 6, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item, style: context.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntelChip extends StatelessWidget {
  const _IntelChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.dangerRed : context.mutedColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: context.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  const _GlassSection({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.surfaceColor.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.primaryGreen),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(title, style: context.textTheme.titleSmall),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
