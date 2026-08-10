import 'package:equatable/equatable.dart';

enum FindingSeverity { critical, high, medium }

class ResumeFinding extends Equatable {
  const ResumeFinding({
    required this.title,
    required this.description,
    required this.severity,
    required this.recommendation,
  });

  final String title;
  final String description;
  final FindingSeverity severity;
  final String recommendation;

  @override
  List<Object?> get props => [title, description, severity];
}

class ResumeReport extends Equatable {
  const ResumeReport({
    required this.safetyScore,
    required this.findings,
    required this.summary,
  });

  final int safetyScore;
  final List<ResumeFinding> findings;
  final String summary;

  int get criticalCount =>
      findings.where((f) => f.severity == FindingSeverity.critical).length;

  @override
  List<Object?> get props => [safetyScore, findings, summary];
}
