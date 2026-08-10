import 'package:internsfe/domain/entities/activity_item.dart';

class HistoryFilter {
  const HistoryFilter({
    this.type,
    this.query,
    this.from,
    this.to,
    this.risk,
  });

  final String? type;
  final String? query;
  final String? from;
  final String? to;
  final String? risk;
}

abstract class HistoryRepository {
  Future<List<ActivityItem>> fetchHistory(HistoryFilter filter);
}
