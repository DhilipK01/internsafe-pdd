import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:internsfe/data/api/api_client.dart';
import 'package:internsfe/domain/entities/scan_job.dart';
import 'package:internsfe/domain/entities/uploaded_file.dart';
import 'package:internsfe/domain/repositories/resume_repository.dart';

class ApiResumeRepository implements ResumeRepository {
  ApiResumeRepository(this._api);

  final ApiClient _api;

  @override
  Future<UploadedFile> uploadResumeFile({
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    final data = await _api.uploadFile(
      path: '/files/upload',
      fileBytes: fileBytes,
      fileName: fileName,
      mimeType: mimeType,
      uploadType: 'resume',
    );
    return UploadedFile.fromJson(data['file'] as Map<String, dynamic>);
  }

  @override
  Future<ScanJob> createResumeScan({
    required String fileId,
    String? fileBase64,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/resumes',
      data: {
        'fileId': fileId,
        if (fileBase64 != null) 'fileBase64': fileBase64,
      },
      options: Options(receiveTimeout: const Duration(seconds: 120)),
    );
    final data = res.data ?? {};
    return ScanJob.fromJson(data);
  }

  @override
  Future<ScanJob> getScan(String scanId) async {
    final data = await _api.getJson('/scans/$scanId');
    final scan = data['scan'] as Map<String, dynamic>;
    return ScanJob.fromScanRow(scan);
  }
}
