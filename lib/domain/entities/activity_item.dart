import 'package:equatable/equatable.dart';

class ActivityItem extends Equatable {
  const ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timestamp,
    required this.resultLabel,
    this.targetId,
    this.targetType,
    this.createdAtIst,
  });

  final String id;
  final String title;
  final String subtitle;
  final String type;
  final DateTime timestamp;
  final String resultLabel;
  final String? targetId;
  final String? targetType;
  final String? createdAtIst;

  factory ActivityItem.fromApi(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      type: json['activity_type'] as String? ??
          json['action_type'] as String? ??
          json['type'] as String? ??
          '',
      timestamp: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      resultLabel: json['result_label'] as String? ?? '',
      targetId: json['target_id'] as String?,
      targetType: json['target_type'] as String?,
      createdAtIst: json['created_at_ist'] as String?,
    );
  }

  String get displayTime =>
      createdAtIst?.isNotEmpty == true ? createdAtIst! : timestamp.toIso8601String();

  @override
  List<Object?> get props =>
      [id, title, subtitle, type, timestamp, targetId, targetType];
}
