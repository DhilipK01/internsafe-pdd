import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/core/constants/app_colors.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/widgets/result_gauge.dart';
import 'package:internsfe/domain/entities/blacklist_entry.dart';
import 'package:internsfe/domain/entities/company_verification.dart';
import 'package:lucide_icons/lucide_icons.dart';

final companyReportsProvider =
    FutureProvider.family<CompanyCommunityReports, String>((ref, query) {
  return ref.read(companyRepositoryProvider).fetchCommunityReports(query);
});

class CommunityReportsScreen extends ConsumerWidget {
  const CommunityReportsScreen({super.key, required this.companyQuery});

  final String companyQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(companyReportsProvider(companyQuery));

    return AppScaffold(
      title: 'Community Reports',
      showBackToHome: false,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load reports: $e')),
        data: (data) => _ReportsBody(data: data),
      ),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  const _ReportsBody({required this.data});

  final CompanyCommunityReports data;

  @override
  Widget build(BuildContext context) {
    if (data.reports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.shieldCheck,
                  size: 48, color: context.mutedColor),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No community reports found for "${data.query}".',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    final trustColor = data.trustScore >= 70
        ? AppColors.successGreen
        : data.trustScore >= 45
            ? AppColors.warningAmber
            : AppColors.dangerRed;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        Text(
          data.companyName,
          style: context.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              width: 120,
              child: ResultGauge(
                score: data.trustScore,
                label: 'Trust',
                color: trustColor,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(label: 'Reports', value: '${data.reportCount}'),
                _StatRow(label: 'Danger index', value: '${data.dangerScore}'),
                if (data.fraudTypes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      data.fraudTypes.take(3).join(', '),
                      style: context.textTheme.bodySmall
                          ?.copyWith(color: context.mutedColor),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        ...data.reports.map((r) => _ReportTile(report: r)),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: RichText(
        text: TextSpan(
          style: context.textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(color: context.mutedColor),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});

  final CommunityReport report;

  Color _riskColor(BuildContext context) {
    if (report.severity >= 4) return AppColors.dangerRed;
    if (report.severity >= 3) return AppColors.warningAmber;
    return context.mutedColor;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: context.surfaceColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showReportDetail(context, report),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        report.displayTitle,
                        style: context.textTheme.titleSmall,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _riskColor(context).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.riskLevelLabel,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: _riskColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  report.fraudType ?? report.reportType,
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: context.mutedColor),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  report.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(LucideIcons.clock, size: 14, color: context.mutedColor),
                    const SizedBox(width: 4),
                    Text(report.date, style: context.textTheme.bodySmall),
                    const Spacer(),
                    Text(
                      'Trust impact −${report.trustImpact}',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: AppColors.dangerRed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(LucideIcons.chevronRight,
                        size: 18, color: context.mutedColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReportDetail(BuildContext context, CommunityReport report) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scroll) {
            return SingleChildScrollView(
              controller: scroll,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ctx.mutedColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(report.displayTitle,
                      style: ctx.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  _DetailChip(
                    label: 'Risk',
                    value: report.riskLevelLabel,
                    color: _riskColor(ctx),
                  ),
                  _DetailChip(
                    label: 'Type',
                    value: report.fraudType ?? report.reportType,
                  ),
                  if (report.college.isNotEmpty &&
                      report.college != 'Unknown')
                    _DetailChip(label: 'College', value: report.college),
                  _DetailChip(label: 'Reported', value: report.date),
                  if (report.status != null)
                    _DetailChip(label: 'Status', value: report.status!),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Complaint', style: ctx.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(report.description, style: ctx.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.lg),
                  Text('AI risk summary', style: ctx.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _aiSummary(report),
                    style: ctx.textTheme.bodyMedium
                        ?.copyWith(color: ctx.mutedColor),
                  ),
                  if (report.evidenceCount > 0) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Icon(LucideIcons.paperclip,
                            size: 16, color: ctx.mutedColor),
                        const SizedBox(width: 6),
                        Text(
                          '${report.evidenceCount} evidence file(s) attached',
                          style: ctx.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _aiSummary(CommunityReport report) {
    final type = (report.fraudType ?? report.reportType).toLowerCase();
    if (report.severity >= 4) {
      return 'High-severity community report flagged as $type. '
          'Multiple students reported similar concerns. Avoid upfront fees '
          'and verify recruiter identity before sharing documents.';
    }
    if (report.severity >= 3) {
      return 'Moderate-risk community signal for $type. Cross-check the '
          'employer domain, offer letter, and payment requests independently.';
    }
    return 'Community report logged as $type. Treat as a caution signal and '
        'verify through official channels.';
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(label,
                style: context.textTheme.bodySmall
                    ?.copyWith(color: context.mutedColor)),
          ),
          Expanded(
            child: Text(
              value,
              style: context.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
