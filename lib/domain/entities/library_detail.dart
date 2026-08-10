import 'package:equatable/equatable.dart';

class LibraryDetail extends Equatable {
  const LibraryDetail({
    required this.snapshot,
    required this.owner,
    required this.meta,
  });

  final Map<String, dynamic> snapshot;
  final Map<String, dynamic> owner;
  final LibraryMeta meta;

  String get type => snapshot['type'] as String? ?? meta.reportType ?? 'unknown';
  String get title => snapshot['title'] as String? ?? 'Report';
  String? get subtitle => snapshot['subtitle'] as String?;
  String? get summary =>
      snapshot['summary'] as String? ?? snapshot['message'] as String?;
  bool get hasAnalysis => meta.hasAnalysis;
  String? get fileId =>
      (snapshot['document'] as Map?)?['fileId'] as String?;

  factory LibraryDetail.fromJson(Map<String, dynamic> json) {
    return LibraryDetail(
      snapshot: Map<String, dynamic>.from(
        json['snapshot'] as Map? ?? {},
      ),
      owner: Map<String, dynamic>.from(json['owner'] as Map? ?? {}),
      meta: LibraryMeta.fromJson(
        Map<String, dynamic>.from(json['meta'] as Map? ?? {}),
      ),
    );
  }

  @override
  List<Object?> get props => [type, meta.resourceId];
}

class LibraryMeta extends Equatable {
  const LibraryMeta({
    this.activityId,
    this.resourceType,
    this.resourceId,
    this.reportType,
    this.status,
    this.riskLevel,
    this.fileType,
    this.fileName,
    this.createdAtIst,
    this.analyzedAtIst,
    this.hasAnalysis = false,
    this.hasDocument = false,
  });

  final String? activityId;
  final String? resourceType;
  final String? resourceId;
  final String? reportType;
  final String? status;
  final String? riskLevel;
  final String? fileType;
  final String? fileName;
  final String? createdAtIst;
  final String? analyzedAtIst;
  final bool hasAnalysis;
  final bool hasDocument;

  factory LibraryMeta.fromJson(Map<String, dynamic> json) {
    return LibraryMeta(
      activityId: json['activityId'] as String?,
      resourceType: json['resourceType'] as String?,
      resourceId: json['resourceId'] as String?,
      reportType: json['reportType'] as String?,
      status: json['status'] as String?,
      riskLevel: json['riskLevel'] as String?,
      fileType: json['fileType'] as String?,
      fileName: json['fileName'] as String?,
      createdAtIst: json['createdAtIst'] as String?,
      analyzedAtIst: json['analyzedAtIst'] as String?,
      hasAnalysis: json['hasAnalysis'] == true,
      hasDocument: json['hasDocument'] == true,
    );
  }

  @override
  List<Object?> get props => [resourceType, resourceId];
}
