import 'package:equatable/equatable.dart';

class BlacklistEntry extends Equatable {
  const BlacklistEntry({
    required this.companyName,
    required this.dangerScore,
    required this.reportCount,
    required this.fraudTypes,
    required this.recentReport,
    required this.collegeClusters,
    required this.reports,
  });

  final String companyName;
  final int dangerScore;
  final int reportCount;
  final List<String> fraudTypes;
  final String recentReport;
  final List<String> collegeClusters;
  final List<CommunityReport> reports;

  @override
  List<Object?> get props =>
      [companyName, dangerScore, reportCount, fraudTypes];
}

class CommunityReport extends Equatable {
  const CommunityReport({
    required this.id,
    required this.reportType,
    required this.college,
    required this.date,
    required this.description,
    this.title,
    this.companyName,
    this.severity = 3,
    this.evidenceCount = 0,
    this.status,
    this.fraudType,
  });

  final String id;
  final String reportType;
  final String college;
  final String date;
  final String description;
  final String? title;
  final String? companyName;
  final int severity;
  final int evidenceCount;
  final String? status;
  final String? fraudType;

  String get displayTitle =>
      (title?.trim().isNotEmpty == true) ? title!.trim() : reportType;

  String get riskLevelLabel {
    if (severity >= 5) return 'Critical';
    if (severity >= 4) return 'High';
    if (severity >= 3) return 'Medium';
    return 'Low';
  }

  int get trustImpact => (severity * 8).clamp(8, 40);

  @override
  List<Object?> get props =>
      [id, reportType, college, date, description, title, severity];
}
