import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:internsfe/core/enums/risk_level.dart';

class OfferAnalysisResult extends Equatable {
  const OfferAnalysisResult({
    required this.result,
    required this.riskLevel,
    required this.confidence,
    required this.reasons,
    required this.summary,
    required this.explanation,
    required this.actionItems,
  });

  final String result;
  final RiskLevel riskLevel;
  final int confidence;
  final List<String> reasons;
  final String summary;
  final String explanation;
  final List<String> actionItems;

  bool get isLikelyFraud =>
      result == 'likely_fraud' ||
      result == 'suspicious' ||
      riskLevel == RiskLevel.fake ||
      riskLevel == RiskLevel.danger;

  static OfferAnalysisResult? fromOfferRow(Map<String, dynamic> row) {
    final status = row['status'] as String? ?? '';
    final res = row['result'] as String? ?? '';
    if (status != 'completed' && status != 'invalid_document_type' && res != 'invalid_document_type') return null;

    final riskStr = row['risk_level'] as String? ?? 'unknown';
    final confidence = row['confidence_score'] as int? ?? 0;
    final summary =
        row['analysis_summary'] as String? ?? row['summary'] as String? ?? '';

    var reasons = <String>[];
    final reasonsJson = row['reasons_json'];
    if (reasonsJson is String && reasonsJson.isNotEmpty) {
      try {
        final parsed = jsonDecode(reasonsJson);
        if (parsed is Map && parsed['rules'] is List) {
          for (final r in parsed['rules'] as List) {
            if (r is Map && r['label'] != null) {
              reasons.add(r['label'] as String);
            }
          }
        }
      } catch (_) {}
    }

    var explanation = '';
    var actions = <String>[];
    final aiRecRaw = row['ai_recommendation_json'];
    if (aiRecRaw is String && aiRecRaw.isNotEmpty) {
      try {
        final aiRec = jsonDecode(aiRecRaw) as Map<String, dynamic>;
        explanation = aiRec['explanation'] as String? ?? '';
        actions = (aiRec['action_items'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
      } catch (_) {}
    }

    return OfferAnalysisResult(
      result: row['result'] as String? ?? 'unknown',
      riskLevel: _mapRisk(riskStr),
      confidence: confidence,
      reasons: reasons,
      summary: summary,
      explanation: explanation,
      actionItems: actions,
    );
  }

  static RiskLevel _mapRisk(String r) {
    final v = r.toLowerCase().replaceAll(' ', '_');
    switch (v) {
      case 'critical':
      case 'high':
      case 'critical_warning':
      case 'scam_likely':
      case 'high_risk':
        return RiskLevel.fake;
      case 'medium':
      case 'moderate_risk':
        return RiskLevel.suspicious;
      case 'low':
      case 'safe':
      case 'low_risk':
        return RiskLevel.genuine;
      default:
        return RiskLevel.suspicious;
    }
  }

  @override
  List<Object?> get props =>
      [result, riskLevel, confidence, reasons, summary, explanation];
}
