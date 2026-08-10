import 'package:equatable/equatable.dart';

enum DataSafetyCategory { safeNow, shareLater, neverShare }

class DataSafetyItem extends Equatable {
  const DataSafetyItem({
    required this.label,
    required this.category,
    required this.explanation,
    this.whenSafe,
    this.saferAlternative,
  });

  final String label;
  final DataSafetyCategory category;
  final String explanation;
  final String? whenSafe;
  final String? saferAlternative;

  @override
  List<Object?> get props => [label, category, explanation, whenSafe, saferAlternative];
}

class DataSafetyResult extends Equatable {
  const DataSafetyResult({
    required this.stage,
    required this.items,
    required this.summary,
    this.warnings = const [],
    this.nextAction,
    this.analyzedAt,
  });

  final String stage;
  final List<DataSafetyItem> items;
  final String summary;
  final List<String> warnings;
  final String? nextAction;
  final String? analyzedAt;

  List<DataSafetyItem> byCategory(DataSafetyCategory cat) =>
      items.where((i) => i.category == cat).toList();

  static DataSafetyCategory _cat(String? raw) {
    switch (raw) {
      case 'safe_now':
        return DataSafetyCategory.safeNow;
      case 'never_share':
        return DataSafetyCategory.neverShare;
      default:
        return DataSafetyCategory.shareLater;
    }
  }

  static DataSafetyItem _itemFromJson(Map<String, dynamic> json) {
    return DataSafetyItem(
      label: json['label'] as String? ?? '',
      category: _cat(json['category'] as String?),
      explanation: json['why_risky'] as String? ?? json['explanation'] as String? ?? '',
      whenSafe: json['when_safe'] as String?,
      saferAlternative: json['safer_alternative'] as String?,
    );
  }

  factory DataSafetyResult.fromApi(Map<String, dynamic> data, {required String stage}) {
    final safeNow = (data['safe_now'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => _itemFromJson(Map<String, dynamic>.from(e)))
        .toList();
    final shareLater = (data['share_later'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => _itemFromJson(Map<String, dynamic>.from(e)))
        .toList();
    final neverShare = (data['never_share'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => _itemFromJson(Map<String, dynamic>.from(e)))
        .toList();

    return DataSafetyResult(
      stage: data['stage'] as String? ?? stage,
      items: [...safeNow, ...shareLater, ...neverShare],
      summary: data['recommendation_summary'] as String? ?? '',
      warnings: (data['warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      nextAction: data['next_action'] as String?,
      analyzedAt: data['analyzedAt'] as String? ?? data['analyzed_at_ist'] as String?,
    );
  }

  @override
  List<Object?> get props => [stage, items, summary, warnings, nextAction, analyzedAt];
}
