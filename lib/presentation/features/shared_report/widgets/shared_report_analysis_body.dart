import 'package:flutter/material.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/constants/app_colors.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/enums/risk_level.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/widgets/info_card.dart';
import 'package:internsfe/core/widgets/result_gauge.dart';
import 'package:internsfe/core/widgets/safety_badge.dart';
import 'package:internsfe/core/widgets/section_title.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Full AI analysis sections — parity with web share page & report viewer.
class SharedReportAnalysisBody {
  static List<Widget> build(
    BuildContext context,
    String type,
    Map<String, dynamic> s,
  ) {
    switch (type) {
      case 'company_verify':
      case 'blacklist':
        return _company(context, s);
      case 'offer_check':
        return _offer(context, s);
      case 'scan':
        return _scan(context, s);
      case 'data_safety':
        return _dataSafety(context, s);
      case 'upload':
        if (_looksLikeScan(s)) return _scan(context, s);
        if (_looksLikeOffer(s)) return _offer(context, s);
        return _uploadOnly(context, s);
      default:
        if (_looksLikeScan(s)) return _scan(context, s);
        if (_looksLikeOffer(s)) return _offer(context, s);
        return [
          InfoCard(
            child: Text(
              s['message']?.toString() ?? 'Shared content',
            ),
          ),
        ];
    }
  }

  static bool _looksLikeScan(Map<String, dynamic> s) =>
      s['safetyScore'] != null ||
      s['dangerScore'] != null ||
      (s['findings'] as List?)?.isNotEmpty == true;

  static bool _looksLikeOffer(Map<String, dynamic> s) {
    final a = s['analysis'] as Map?;
    return a != null &&
        ((a['reasons'] as List?)?.isNotEmpty == true ||
            a['fraudScore'] != null);
  }

  static List<Widget> _scan(BuildContext context, Map<String, dynamic> s) {
    final score = (s['safetyScore'] as num?)?.toInt();
    final danger = (s['dangerScore'] as num?)?.toInt();
    final findings = (s['findings'] as List?) ?? [];
    final ai = s['aiRecommendation'] as Map<String, dynamic>?;
    final recs = (s['recommendations'] as List?) ?? [];
    final entities = (s['entities'] as List?) ?? [];
    final scam = (s['scamIndicators'] as List?) ?? [];

    return [
      const SectionTitle(title: 'AI analysis'),
      const SizedBox(height: AppSpacing.sm),
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
      if (s['verdict'] != null) ...[
        const SizedBox(height: AppSpacing.sm),
        _VerdictBanner(text: s['verdict'] as String),
      ],
      const SizedBox(height: AppSpacing.sm),
      _RiskChip(risk: s['riskLevel'] as String?),
      const SizedBox(height: AppSpacing.md),
      if (ai?['explanation'] != null)
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI recommendation',
                style: context.textTheme.labelLarge?.copyWith(
                  color: AppPalette.emeraldBright,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(ai!['explanation'] as String),
            ],
          ),
        )
      else if (s['summary'] != null || s['message'] != null)
        InfoCard(
          child: Text(
            s['summary'] as String? ?? s['message'] as String? ?? '',
          ),
        ),
      if (findings.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        _FindingsByRisk(findings: findings),
      ],
      if (scam.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        _BulletSection(title: 'Scam indicators', items: scam),
      ],
      if (entities.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        _BulletSection(title: 'Extracted entities', items: entities),
      ],
      if (recs.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        _BulletSection(title: 'Recommendations', items: recs),
      ],
    ];
  }

  static List<Widget> _offer(BuildContext context, Map<String, dynamic> s) {
    final analysis = s['analysis'] as Map<String, dynamic>? ?? s;
    final fraud =
        (analysis['fraudScore'] ?? analysis['scamProbability']) as num?;
    final reasons = (analysis['reasons'] as List?) ?? [];
    final phrases = (analysis['suspiciousPhrases'] as List?) ?? [];

    return [
      const SectionTitle(title: 'Offer fraud analysis'),
      const SizedBox(height: AppSpacing.sm),
      if (fraud != null)
        ResultGauge(
          score: fraud.round().clamp(0, 100),
          label: 'Scam probability',
          color: fraud.toInt() >= 60
              ? AppColors.dangerRed
              : AppColors.warningAmber,
        ),
      const SizedBox(height: AppSpacing.md),
      _RiskChip(risk: analysis['riskLevel'] as String? ?? s['riskLevel'] as String?),
      const SizedBox(height: AppSpacing.md),
      InfoCard(
        child: Text(
          s['summary'] as String? ??
              s['message'] as String? ??
              analysis['recommendation'] as String? ??
              'Offer analysis',
        ),
      ),
      if (reasons.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        const SectionTitle(title: 'Risk findings'),
        const SizedBox(height: AppSpacing.sm),
        ...reasons.take(20).map((r) => _FindingTile.fromDynamic(r)),
      ],
      if (phrases.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        _BulletSection(title: 'Suspicious phrases', items: phrases),
      ],
    ];
  }

  static List<Widget> _company(BuildContext context, Map<String, dynamic> s) {
    final name = s['companyName'] as String? ?? 'Company';
    final trust = (s['trustScore'] as num?)?.toInt() ?? 0;
    final danger = (s['dangerScore'] as num?)?.toInt();
    final reports = (s['reportCount'] as num?)?.toInt() ?? 0;
    final risk = reports >= 5
        ? RiskLevel.suspicious
        : reports > 0
            ? RiskLevel.warning
            : RiskLevel.safe;

    return [
      const SectionTitle(title: 'Company intelligence'),
      const SizedBox(height: AppSpacing.sm),
      Text(name, style: context.textTheme.titleLarge),
      if (s['verdict'] != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(s['verdict'] as String, style: context.textTheme.titleSmall),
      ],
      const SizedBox(height: AppSpacing.lg),
      if (trust > 0)
        ResultGauge(score: trust, label: 'Trust score', color: risk.color),
      if (danger != null) ...[
        const SizedBox(height: AppSpacing.md),
        ResultGauge(
          score: danger.clamp(0, 100),
          label: 'Danger score',
          color: AppColors.dangerRed,
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      SafetyBadge(level: risk),
      const SizedBox(height: AppSpacing.lg),
      InfoCard(child: Text(s['message'] as String? ?? '')),
    ];
  }

  static List<Widget> _dataSafety(BuildContext context, Map<String, dynamic> s) {
    return [
      const SectionTitle(title: 'Data safety guidance'),
      const SizedBox(height: AppSpacing.sm),
      InfoCard(
        child: Text(s['summary'] as String? ?? s['message'] as String? ?? ''),
      ),
      const SizedBox(height: AppSpacing.md),
      _listCard(context, 'Safe to share now', s['safeNow'] as List?),
      _listCard(context, 'Share later', s['shareLater'] as List?),
      _listCard(context, 'Never share', s['neverShare'] as List?),
    ];
  }

  static Widget _listCard(BuildContext context, String title, List? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            ...items.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${i is String ? i : i.toString()}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<Widget> _uploadOnly(BuildContext context, Map<String, dynamic> s) {
    final doc = s['document'] as Map<String, dynamic>?;
    return [
      InfoCard(
        child: Text(
          s['message'] as String? ??
              'Document shared. No AI analysis is attached to this file.',
        ),
      ),
      if (doc?['fileName'] != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          doc!['fileName'] as String,
          style: context.textTheme.bodySmall?.copyWith(color: context.mutedColor),
        ),
      ],
    ];
  }
}

class _VerdictBanner extends StatelessWidget {
  const _VerdictBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.emeraldBright.withValues(alpha: 0.35)),
        color: AppPalette.emeraldCore.withValues(alpha: 0.12),
      ),
      child: Text(text, style: context.textTheme.titleSmall),
    );
  }
}

class _RiskChip extends StatelessWidget {
  const _RiskChip({this.risk});
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

  Color _color(String? sev) {
    switch (sev?.toLowerCase()) {
      case 'critical':
      case 'high':
        return AppColors.dangerRed;
      case 'medium':
        return AppColors.warningAmber;
      case 'low':
        return AppColors.successGreen;
      default:
        return AppPalette.cyberBlue;
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
        const SectionTitle(title: 'Risk findings'),
        const SizedBox(height: AppSpacing.sm),
        for (final e in grouped.entries) ...[
          Text(
            e.key.toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              color: _color(e.key),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...e.value.map((f) => _FindingTile.fromMap(f, e.key)),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _FindingTile extends StatelessWidget {
  const _FindingTile({required this.message, required this.severity});

  factory _FindingTile.fromDynamic(dynamic raw) {
    final map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : {'message': raw.toString()};
    return _FindingTile.fromMap(
      map,
      map['severity']?.toString() ?? map['risk']?.toString() ?? 'medium',
    );
  }

  factory _FindingTile.fromMap(Map<String, dynamic> map, String severity) {
    return _FindingTile(
      message: map['message']?.toString() ??
          map['value']?.toString() ??
          map['type']?.toString() ??
          'Finding',
      severity: severity,
    );
  }

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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: ListTile(
          leading: Icon(LucideIcons.alertTriangle, color: color, size: 20),
          title: Text(message),
          dense: true,
        ),
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({required this.title, required this.items});
  final String title;
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          ...items.take(15).map(
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${i is String ? i : (i is Map ? (i['message'] ?? i).toString() : i.toString())}',
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
