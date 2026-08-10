import 'package:dio/dio.dart';
import 'package:internsfe/data/api/api_client.dart';
import 'package:internsfe/domain/entities/uploaded_file.dart';
import 'package:internsfe/domain/repositories/file_repository.dart';

class ApiFileRepository implements FileRepository {
  ApiFileRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<UploadedFile>> listMyFiles({String? uploadType}) async {
    final data = await _api.getJson(
      '/files',
      query: uploadType != null ? {'uploadType': uploadType} : null,
    );
    final list = data['files'] as List<dynamic>? ?? [];
    return list
        .whereType<Map>()
        .map((e) => UploadedFile.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<int>> downloadFileContent(String fileId) async {
    final res = await _api.dio.get<List<int>>(
      '/files/$fileId/content',
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? [];
  }
}
