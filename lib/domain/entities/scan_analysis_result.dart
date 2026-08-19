import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:internsfe/core/enums/risk_level.dart';

class ScanFinding extends Equatable {
  const ScanFinding({
    required this.type,
    required this.value,
    required this.riskLevel,
    this.recommendation,
    this.confidence,
    this.reason,
  });

  final String type;
  final String value;
  final String riskLevel;
  final String? recommendation;
  final double? confidence;
  final String? reason;

  factory ScanFinding.fromJson(Map<String, dynamic> json) {
    return ScanFinding(
      type: json['finding_type'] as String? ?? json['type'] as String? ?? '',
      value: json['finding_value'] as String? ?? json['value'] as String? ?? '',
      riskLevel: json['risk_level'] as String? ?? 'medium',
      recommendation: json['recommendation'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      reason: json['reason'] as String?,
    );
  }

  @override
  List<Object?> get props => [type, value, riskLevel, confidence, reason];
}

class ScanAnalysisResult extends Equatable {
  const ScanAnalysisResult({
    this.safetyScore,
    this.qualityScore,
    this.isResume,
    this.status,
    this.message,
    this.sectionChecks,
    required this.riskLevel,
    required this.findings,
    required this.explanation,
    required this.actionItems,
    this.ocrConfidence,
  });

  final int? safetyScore;
  final int? qualityScore;
  final bool? isResume;
  final String? status;
  final String? message;
  final Map<String, bool>? sectionChecks;
  final RiskLevel riskLevel;
  final List<ScanFinding> findings;
  final String explanation;
  final List<String> actionItems;
  final double? ocrConfidence;

  static ScanAnalysisResult? fromResultJson(dynamic raw) {
    if (raw == null) return null;
    Map<String, dynamic> map;
    if (raw is String) {
      try {
        map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {
        return null;
      }
    } else if (raw is Map<String, dynamic>) {
      map = raw;
    } else {
      return null;
    }

    final findingsRaw = map['findings'] as List<dynamic>? ?? [];
    final findings = findingsRaw
        .whereType<Map>()
        .map((e) => ScanFinding.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final aiRec = map['ai_recommendation'];
    var explanation = '';
    var actions = <String>[];
    if (aiRec is Map) {
      explanation = aiRec['explanation'] as String? ?? '';
      actions = (aiRec['action_items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
    }

    Map<String, bool>? sectionChecks;
    final sc = map['section_checks'];
    if (sc is Map) {
      sectionChecks = sc.map((k, v) => MapEntry(k.toString(), v == true));
    }

    final riskStr = map['risk_level'] as String? ?? 'unknown';
    return ScanAnalysisResult(
      safetyScore: map['safety_score'] as int?,
      qualityScore: map['quality_score'] as int?,
      isResume: map['is_resume'] as bool?,
      status: map['status'] as String?,
      message: map['message'] as String?,
      sectionChecks: sectionChecks,
      riskLevel: _mapRisk(riskStr),
      findings: findings,
      explanation: explanation,
      actionItems: actions,
      ocrConfidence: (map['ocr_confidence'] as num?)?.toDouble(),
    );
  }

  static RiskLevel _mapRisk(String r) {
    switch (r) {
      case 'critical':
      case 'high':
        return RiskLevel.danger;
      case 'medium':
        return RiskLevel.warning;
      case 'low':
        return RiskLevel.safe;
      default:
        return RiskLevel.warning;
    }
  }

  @override
  List<Object?> get props => [
        safetyScore,
        qualityScore,
        isResume,
        status,
        message,
        sectionChecks,
        riskLevel,
        findings,
        explanation,
        ocrConfidence
      ];
}
