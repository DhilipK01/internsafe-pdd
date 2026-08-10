import 'package:internsfe/data/api/api_client.dart';
import 'package:internsfe/domain/repositories/content_repository.dart';

class ApiContentRepository implements ContentRepository {
  ApiContentRepository(this._api);

  final ApiClient _api;

  @override
  Future<void> deleteContent({
    required String contentType,
    required String contentId,
  }) async {
    await _api.deleteJson('/content/$contentType/$contentId');
  }
}
