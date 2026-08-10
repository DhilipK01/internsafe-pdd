import 'package:internsfe/data/api/api_client.dart';
import 'package:internsfe/domain/entities/activity_item.dart';
import 'package:internsfe/domain/repositories/history_repository.dart';

class ApiHistoryRepository implements HistoryRepository {
  ApiHistoryRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<ActivityItem>> fetchHistory(HistoryFilter filter) async {
    final data = await _api.getJson('/history', query: {
      if (filter.type != null) 'type': filter.type,
      if (filter.query != null && filter.query!.isNotEmpty) 'q': filter.query,
      if (filter.from != null) 'from': filter.from,
      if (filter.to != null) 'to': filter.to,
      if (filter.risk != null) 'risk': filter.risk,
    });
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((a) => ActivityItem.fromApi(a as Map<String, dynamic>))
        .toList();
  }
}
