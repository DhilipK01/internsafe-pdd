import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/brand/internsafe_logo.dart';
import 'package:internsfe/core/constants/app_colors.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/enums/risk_level.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/services/share_service.dart';
import 'package:internsfe/core/share/shareable_item.dart';
import 'package:internsfe/core/utils/ist_datetime.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/dialogs/confirmation_dialog_service.dart';
import 'package:internsfe/core/widgets/info_card.dart';
import 'package:internsfe/core/widgets/primary_button.dart';
import 'package:internsfe/core/widgets/result_gauge.dart';
import 'package:internsfe/core/widgets/safety_badge.dart';
import 'package:internsfe/core/widgets/share_options_sheet.dart';
import 'package:internsfe/data/api/api_exception.dart';
import 'package:internsfe/domain/entities/library_detail.dart';
import 'package:internsfe/domain/repositories/share_repository.dart';
import 'package:internsfe/presentation/features/history/widgets/document_content_preview.dart';
import 'package:lucide_icons/lucide_icons.dart';

final reportDetailProvider = FutureProvider.autoDispose
    .family<LibraryDetail, ReportDetailKey>((ref, key) {
  return ref
      .read(libraryRepositoryProvider)
      .fetchDetail(kind: key.kind, id: key.id);
});

class ReportDetailKey {
  const ReportDetailKey({required this.kind, required this.id});

  final String kind;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is ReportDetailKey && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}

/// Premium AI report viewer — history, uploads, and saved analyses.
class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({
    super.key,
    required this.kind,
    required this.id,
    this.activityId,
  });

  final String kind;
  final String id;
  final String? activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = ReportDetailKey(kind: kind, id: id);
    final async = ref.watch(reportDetailProvider(key));

    return async.when(
      loading: () => AppScaffold(
        title: 'Report',
        showBackToHome: false,
        body: const _ReportDetailLoading(),
      ),
      error: (e, _) {
        final msg = e is ApiException
            ? e.message
            : 'Could not load this report.';
        return AppScaffold(
          title: 'Report',
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.alertCircle, size: 48),
                  const SizedBox(height: AppSpacing.md),
                  Text(msg, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'Retry',
                    onPressed: () => ref.invalidate(reportDetailProvider(key)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      data: (detail) => AppScaffold(
        title: detail.title,
        showBackToHome: false,
        actions: [
          _ReportActions(
            detail: detail,
            activityId: activityId ?? detail.meta.activityId,
            onDeleted: () {
              ref.invalidate(reportDetailProvider(key));
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.history);
              }
            },
          ),
        ],
        body: _ReportDetailBody(
          detail: detail,
          onRefresh: () async {
            ref.invalidate(reportDetailProvider(key));
          },
        ),
      ),
    );
  }
}

class _ReportDetailLoading extends StatelessWidget {
  const _ReportDetailLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            const InternsafeLogo(size: 72, showGlow: true, animate: true),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Loading AI intelligence…',
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.xxl),
            ...List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: context.isDark
                        ? AppColors.cardDark.withValues(alpha: 0.5)
                        : AppPalette.pearl,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportActions extends ConsumerWidget {
  const _ReportActions({
    required this.detail,
    required this.onDeleted,
    this.activityId,
  });

  final LibraryDetail detail;
  final String? activityId;
  final VoidCallback onDeleted;

  ShareableItem? get _shareItem {
    final rt = detail.meta.resourceType;
    final rid = detail.meta.resourceId;
    if (rt == 'scan' && rid != null) {
      return ShareableItem(
        deleteType: activityId != null ? 'activity' : 'scan',
        shareType: ShareResourceType.scan,
        resourceId: rid,
        requiresSensitiveConfirm: true,
        label: detail.title,
      );
    }
    if (rt == 'offer_check' && rid != null) {
      return ShareableItem(
        deleteType: activityId != null ? 'activity' : 'offer',
        shareType: ShareResourceType.offerCheck,
        resourceId: rid,
        requiresSensitiveConfirm: true,
        label: detail.title,
      );
    }
    if (rt == 'upload' && rid != null) {
      return ShareableItem(
        deleteType: 'file',
        shareType: ShareResourceType.upload,
        resourceId: rid,
        requiresSensitiveConfirm: true,
        label: detail.title,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final share = _shareItem;
    if (share == null) {
      return const SizedBox.shrink();
    }
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.moreVertical),
      onSelected: (v) => _onSelect(context, ref, v, share),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'share', child: Text('Share')),
        const PopupMenuItem(value: 'copy', child: Text('Copy link')),
        if (_canReanalyze) const PopupMenuItem(value: 'reanalyze', child: Text('Reanalyze')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  bool get _canReanalyze {
    final t = detail.type;
    return t == 'scan' || t == 'offer_check' || t == 'upload';
  }

  Future<void> _onSelect(
    BuildContext context,
    WidgetRef ref,
    String action,
    ShareableItem share,
  ) async {
    if (action == 'share') {
      await showShareOptionsSheet(context, ref, share);
      return;
    }
    if (action == 'copy') {
      try {
        await shareService(ref).copyLink(context, share);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
      return;
    }
    if (action == 'reanalyze') {
      final proceed = await ConfirmationDialogService.confirmReanalyze(context);
      if (!proceed || !context.mounted) return;
      if (detail.type == 'scan') {
        context.push(AppRoutes.scan);
      } else if (detail.type == 'offer_check') {
        context.push(AppRoutes.offerCheck);
      } else if (detail.type == 'upload') {
        context.push(AppRoutes.scan);
      }
      return;
    }
    if (action == 'delete') {
      final ok = await ConfirmationDialogService.confirmAndRun(
        context: context,
        request: ConfirmationPresets.deleteReport(itemLabel: detail.title),
        loadingMessage: 'Deleting report…',
        successMessage: 'Report deleted successfully.',
        action: () async {
          final deleteId = activityId ?? share.resourceId ?? '';
          if (deleteId.isEmpty) {
            throw StateError('Cannot delete: missing id');
          }
          await ref.read(contentRepositoryProvider).deleteContent(
                contentType: share.deleteType,
                contentId: deleteId,
              );
        },
      );
      if (ok && context.mounted) onDeleted();
    }
  }
}

class _ReportDetailBody extends StatelessWidget {
  const _ReportDetailBody({
    required this.detail,
    required this.onRefresh,
  });

  final LibraryDetail detail;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final s = detail.snapshot;
    final doc = s['document'] as Map<String, dynamic>?;
    final fileId = doc?['fileId'] as String? ?? detail.fileId;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InternsafeLogo(size: 40, showGlow: true),
            const SizedBox(height: AppSpacing.md),
            Text(detail.title, style: context.textTheme.headlineSmall),
            if (detail.subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                detail.subtitle!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppPalette.emeraldBright,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _OwnerCard(owner: detail.owner),
            const SizedBox(height: AppSpacing.lg),
            _MetadataTimeline(meta: detail.meta),
            if (fileId != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(title: 'Uploaded content', icon: LucideIcons.file),
              const SizedBox(height: AppSpacing.sm),
              DocumentContentPreview(
                fileId: fileId,
                fileName: doc?['fileName'] as String? ?? detail.meta.fileName,
                mimeType: doc?['mimeType'] as String?,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(title: 'AI analysis', icon: LucideIcons.sparkles),
            const SizedBox(height: AppSpacing.sm),
            if (!detail.hasAnalysis)
              InfoCard(
                child: Text(
                  'No analysis available for this upload.',
                  style: context.textTheme.bodyMedium,
                ),
              )
            else
              ..._analysisSections(context, s),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  List<Widget> _analysisSections(BuildContext context, Map<String, dynamic> s) {
    switch (detail.type) {
      case 'scan':
        return _scanSections(context, s);
      case 'offer_check':
        return _offerSections(context, s);
      case 'company_verify':
      case 'blacklist':
        return _companySections(context, s);
      case 'data_safety':
        return _dataSafetySections(context, s);
      case 'upload':
        return [
          InfoCard(
            child: Text(
              s['message'] as String? ??
                  'Document stored securely. Run a resume or offer scan to generate AI findings.',
            ),
          ),
        ];
      default:
        return [
          InfoCard(
            child: Text(
              detail.summary ?? s['message'] as String? ?? 'Report details',
            ),
          ),
        ];
    }
  }

  List<Widget> _scanSections(BuildContext context, Map<String, dynamic> s) {
    final score = (s['safetyScore'] as num?)?.toInt();
    final danger = (s['dangerScore'] as num?)?.toInt();
    final findings = (s['findings'] as List?) ?? [];
    final ai = s['aiRecommendation'] as Map<String, dynamic>?;

    return [
      if (s['verdict'] != null) _VerdictBanner(text: s['verdict'] as String),
      if (score != null)
        ResultGauge(
          score: score,
          label: 'Safety score',
          color: score >= 70 ? AppColors.successGreen : AppColors.warningAmber,
        ),
      if (danger != null) ...[
        const SizedBox(height: AppSpacing.md),
        ResultGauge(
          score: danger.clamp(0, 100),
          label: 'Danger score',
          color: AppColors.dangerRed,
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      _RiskBadge(risk: s['riskLevel'] as String?),
      if (ai?['explanation'] != null) ...[
        const SizedBox(height: AppSpacing.lg),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI verdict', style: context.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(ai!['explanation'] as String),
            ],
          ),
        ),
      ] else if (detail.summary != null) ...[
        const SizedBox(height: AppSpacing.lg),
        InfoCard(child: Text(detail.summary!)),
      ],
      if (findings.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        _FindingsByRisk(findings: findings),
      ],
      ..._recommendations(context, s),
    ];
  }

  List<Widget> _offerSections(BuildContext context, Map<String, dynamic> s) {
    final analysis = s['analysis'] as Map<String, dynamic>? ?? s;
    final fraud =
        (analysis['fraudScore'] ?? analysis['scamProbability']) as num?;
    final reasons = (analysis['reasons'] as List?) ?? [];

    return [
      if (fraud != null)
        ResultGauge(
          score: fraud.round().clamp(0, 100),
          label: 'Scam probability',
          color: fraud.toInt() >= 60
              ? AppColors.dangerRed
              : AppColors.warningAmber,
        ),
      const SizedBox(height: AppSpacing.md),
      _RiskBadge(risk: analysis['riskLevel'] as String? ?? s['riskLevel'] as String?),
      const SizedBox(height: AppSpacing.md),
      InfoCard(
        child: Text(detail.summary ?? 'Offer analysis'),
      ),
      if (reasons.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        _SectionHeader(title: 'Risk findings', icon: LucideIcons.shieldAlert),
        const SizedBox(height: AppSpacing.sm),
        ...reasons.take(15).map((r) {
          final map = r is Map
              ? Map<String, dynamic>.from(r)
              : {'message': r.toString()};
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _FindingTile(
              message: map['message']?.toString() ?? r.toString(),
              severity: map['severity']?.toString() ?? 'medium',
            ),
          );
        }),
      ],
    ];
  }

  List<Widget> _companySections(BuildContext context, Map<String, dynamic> s) {
    final trust = (s['trustScore'] as num?)?.toInt() ?? 0;
    final reports = (s['reportCount'] as num?)?.toInt() ?? 0;
    final risk = reports >= 5
        ? RiskLevel.suspicious
        : reports > 0
            ? RiskLevel.warning
            : RiskLevel.safe;

    return [
      if (s['companyName'] != null)
        Text(s['companyName'] as String, style: context.textTheme.titleLarge),
      const SizedBox(height: AppSpacing.md),
      if (trust > 0)
        ResultGauge(score: trust, label: 'Trust score', color: risk.color),
      const SizedBox(height: AppSpacing.md),
      SafetyBadge(level: risk),
      const SizedBox(height: AppSpacing.md),
      InfoCard(child: Text(s['message'] as String? ?? '')),
    ];
  }

  List<Widget> _dataSafetySections(BuildContext context, Map<String, dynamic> s) {
    return [
      InfoCard(child: Text(s['summary'] as String? ?? s['message'] as String? ?? '')),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Safe now: ${s['safeCount'] ?? 0} · Share later: ${s['laterCount'] ?? 0} · Never: ${s['neverCount'] ?? 0}',
        style: context.textTheme.bodySmall,
      ),
    ];
  }

  List<Widget> _recommendations(BuildContext context, Map<String, dynamic> s) {
    final recs = (s['recommendations'] as List?) ??
        (s['aiRecommendation']?['actionItems'] as List?) ??
        [];
    if (recs.isEmpty) return [];
    return [
      const SizedBox(height: AppSpacing.lg),
      _SectionHeader(title: 'Recommendations', icon: LucideIcons.lightbulb),
      const SizedBox(height: AppSpacing.sm),
      ...recs.take(10).map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InfoCard(child: Text(r.toString())),
            ),
          ),
    ];
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.owner});

  final Map<String, dynamic> owner;

  @override
  Widget build(BuildContext context) {
    final initials = owner['initials'] as String? ?? 'IN';
    return InfoCard(
      child: Row(
        children: [
          CircleAvatar(
            child: Text(initials),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owner['name'] as String? ?? 'INTERNSAFE user',
                  style: context.textTheme.titleSmall,
                ),
                if (owner['college'] != null)
                  Text(
                    owner['college'] as String,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.mutedColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataTimeline extends StatelessWidget {
  const _MetadataTimeline({required this.meta});

  final LibraryMeta meta;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Timeline & metadata', icon: LucideIcons.clock),
          const SizedBox(height: AppSpacing.sm),
          if (meta.createdAtIst != null)
            _MetaRow(label: 'Created', value: _formatIst(meta.createdAtIst)),
          if (meta.analyzedAtIst != null)
            _MetaRow(label: 'Analyzed', value: _formatIst(meta.analyzedAtIst)),
          if (meta.reportType != null)
            _MetaRow(label: 'Report type', value: meta.reportType!),
          if (meta.status != null) _MetaRow(label: 'Status', value: meta.status!),
          if (meta.riskLevel != null)
            _MetaRow(label: 'Risk level', value: meta.riskLevel!),
          if (meta.fileName != null)
            _MetaRow(label: 'File', value: meta.fileName!),
        ],
      ),
    );
  }

  String _formatIst(String? ist) {
    if (ist == null || ist.isEmpty) return '';
    return IstDateTime.formatBullet(ist, fallback: ist);
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.mutedColor,
              ),
            ),
          ),
          Expanded(child: Text(value, style: context.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppPalette.emeraldBright),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: context.textTheme.titleMedium),
      ],
    );
  }
}

class _VerdictBanner extends StatelessWidget {
  const _VerdictBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            AppPalette.emeraldBright.withValues(alpha: 0.15),
            AppPalette.emeraldDeep.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: AppPalette.emeraldBright.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: context.textTheme.titleSmall),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({this.risk});

  final String? risk;

  @override
  Widget build(BuildContext context) {
    final level = switch (risk?.toLowerCase()) {
      'critical' || 'high' => RiskLevel.suspicious,
      'medium' => RiskLevel.warning,
      'low' => RiskLevel.safe,
      _ => RiskLevel.warning,
    };
    return SafetyBadge(level: level);
  }
}

class _FindingsByRisk extends StatelessWidget {
  const _FindingsByRisk({required this.findings});

  final List<dynamic> findings;

  Color _colorFor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
      case 'high':
        return AppColors.dangerRed;
      case 'medium':
        return AppColors.warningAmber;
      case 'low':
        return AppColors.successGreen;
      default:
        return AppPalette.emeraldBright;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final raw in findings) {
      final map = raw is Map
          ? Map<String, dynamic>.from(raw)
          : {'message': raw.toString(), 'severity': 'medium'};
      final sev = (map['severity'] ?? map['risk'] ?? 'medium').toString();
      grouped.putIfAbsent(sev, () => []).add(map);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Risk findings', icon: LucideIcons.shieldAlert),
        const SizedBox(height: AppSpacing.sm),
        for (final entry in grouped.entries) ...[
          Text(
            entry.key.toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              color: _colorFor(entry.key),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...entry.value.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _FindingTile(
                message: f['message']?.toString() ??
                    f['description']?.toString() ??
                    f['type']?.toString() ??
                    '',
                severity: entry.key,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _FindingTile extends StatelessWidget {
  const _FindingTile({required this.message, required this.severity});

  final String message;
  final String severity;

  @override
  Widget build(BuildContext context) {
    final color = switch (severity.toLowerCase()) {
      'critical' || 'high' => AppColors.dangerRed,
      'medium' => AppColors.warningAmber,
      'low' => AppColors.successGreen,
      _ => AppPalette.cyberBlue,
    };
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: ListTile(
        leading: Icon(LucideIcons.alertTriangle, color: color, size: 20),
        title: Text(message),
        dense: true,
      ),
    );
  }
}
