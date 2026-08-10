import 'package:equatable/equatable.dart';
import 'package:internsfe/core/enums/risk_level.dart';

class OfferResult extends Equatable {
  const OfferResult({
    required this.level,
    required this.confidence,
    required this.reasons,
    required this.summary,
  });

  final RiskLevel level;
  final int confidence;
  final List<String> reasons;
  final String summary;

  bool get isGenuine => level == RiskLevel.genuine;
  bool get isFake => level == RiskLevel.fake;

  @override
  List<Object?> get props => [level, confidence, reasons, summary];
}
