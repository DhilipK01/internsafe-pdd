import 'dart:convert';

import 'package:equatable/equatable.dart';

class ScanJob extends Equatable {
  const ScanJob({
    required this.id,
    required this.status,
    required this.message,
    this.resumeId,
    this.resultJson,
  });

  final String id;
  final String status;
  final String message;
  final String? resumeId;
  final dynamic resultJson;

  bool get isPending =>
      status == 'pending_analysis' || status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get hasResults => status == 'completed' || status == 'invalid_document_type';
  bool get isFailed => status == 'failed';

  static dynamic _parseResult(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        return jsonDecode(raw);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  factory ScanJob.fromJson(Map<String, dynamic> json) {
    final scanId = json['scanId'] as String? ?? json['id'] as String;
    dynamic result = _parseResult(json['resultJson'] ?? json['result_json']);
    final status = json['status'] as String? ?? 'pending_analysis';
    return ScanJob(
      id: scanId,
      status: status,
      message: json['message'] as String? ?? '',
      resumeId: json['resumeId'] as String?,
      resultJson: result,
    );
  }

  factory ScanJob.fromScanRow(Map<String, dynamic> scan) {
    return ScanJob(
      id: scan['id'] as String,
      status: scan['status'] as String? ?? 'pending_analysis',
      message: scan['error_message'] as String? ?? '',
      resumeId: scan['resume_id'] as String?,
      resultJson: _parseResult(scan['result_json']),
    );
  }

  @override
  List<Object?> get props => [id, status, message];
}
