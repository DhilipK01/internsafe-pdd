import 'package:internsfe/data/api/api_client.dart';
import 'package:internsfe/domain/entities/library_detail.dart';
import 'package:internsfe/domain/repositories/library_repository.dart';

class ApiLibraryRepository implements LibraryRepository {
  ApiLibraryRepository(this._api);

  final ApiClient _api;

  @override
  Future<LibraryDetail> fetchDetail({
    required String kind,
    required String id,
  }) async {
    final path = _pathFor(kind, id);
    final data = await _api.getJson(path);
    return LibraryDetail.fromJson(Map<String, dynamic>.from(data));
  }

  String _pathFor(String kind, String id) {
    switch (kind) {
      case 'history':
      case 'activity':
        return '/history/$id';
      case 'upload':
        return '/upload/$id';
      case 'analysis':
        return '/analysis/$id';
      default:
        return '/library/$kind/$id';
    }
  }
}
