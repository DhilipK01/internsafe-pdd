import 'dart:typed_data';

import 'package:internsfe/domain/entities/uploaded_file.dart';

class OfferCheckJob {
  const OfferCheckJob({
    required this.id,
    required this.status,
    required this.message,
  });

  final String id;
  final String status;
  final String message;

  bool get isPending =>
      status == 'pending_analysis' || status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}

abstract class OfferRepository {
  Future<UploadedFile?> uploadOfferDocument({
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
  });

  Future<OfferCheckJob> submitOfferCheck({
    String? text,
    String? fileId,
    String? fileBase64,
  });

  Future<Map<String, dynamic>> getOfferCheck(String id);
}
