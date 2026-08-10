import 'dart:typed_data';

import 'package:internsfe/domain/entities/scan_job.dart';
import 'package:internsfe/domain/entities/uploaded_file.dart';

abstract class ResumeRepository {
  Future<UploadedFile> uploadResumeFile({
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
  });

  Future<ScanJob> createResumeScan({
    required String fileId,
    String? fileBase64,
  });

  Future<ScanJob> getScan(String scanId);
}
