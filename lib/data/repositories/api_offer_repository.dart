import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:internsfe/data/api/api_client.dart';
import 'package:internsfe/domain/entities/uploaded_file.dart';
import 'package:internsfe/domain/repositories/offer_repository.dart';

class ApiOfferRepository implements OfferRepository {
  ApiOfferRepository(this._api);

  final ApiClient _api;

  @override
  Future<UploadedFile?> uploadOfferDocument({
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    final data = await _api.uploadFile(
      path: '/files/upload',
      fileBytes: fileBytes,
      fileName: fileName,
      mimeType: mimeType,
      uploadType: 'offer',
    );
    return UploadedFile.fromJson(data['file'] as Map<String, dynamic>);
  }

  @override
  Future<OfferCheckJob> submitOfferCheck({
    String? text,
    String? fileId,
    String? fileBase64,
  }) async {
    final res = await _api.dio.post<Map<String, dynamic>>(
      '/offers/check',
      data: {
        if (text != null && text.isNotEmpty) 'text': text,
        if (fileId != null) 'fileId': fileId,
        if (fileBase64 != null) 'fileBase64': fileBase64,
      },
      options: Options(receiveTimeout: const Duration(seconds: 120)),
    );
    final data = res.data ?? {};
    return OfferCheckJob(
      id: data['offerCheckId'] as String,
      status: data['status'] as String? ?? 'pending_analysis',
      message: data['message'] as String? ?? '',
    );
  }

  @override
  Future<Map<String, dynamic>> getOfferCheck(String id) async {
    final data = await _api.getJson('/offers/$id');
    return data['offer'] as Map<String, dynamic>;
  }
}
