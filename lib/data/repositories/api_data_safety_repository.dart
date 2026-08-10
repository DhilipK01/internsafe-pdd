import 'package:internsfe/data/api/api_client.dart';
import 'package:internsfe/domain/entities/data_safety_result.dart';
import 'package:internsfe/domain/repositories/data_safety_repository.dart';

class ApiDataSafetyRepository implements DataSafetyRepository {
  ApiDataSafetyRepository(this._api);

  final ApiClient _api;

  @override
  Future<DataSafetyResult> analyze({
    required List<String> requestedData,
    required String stage,
  }) async {
    final data = await _api.postJson('/data-safety/analyze', body: {
      'stage': stage,
      'requestedData': requestedData,
    });
    return DataSafetyResult.fromApi(data, stage: stage);
  }
}
