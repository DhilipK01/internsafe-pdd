import 'package:internsfe/data/api/api_client.dart';
import 'package:internsfe/domain/entities/activity_item.dart';
import 'package:internsfe/domain/entities/user_profile.dart';
import 'package:internsfe/domain/repositories/dashboard_repository.dart';

class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository(this._api);

  final ApiClient _api;

  @override
  Future<DashboardData> fetchDashboard() async {
    final data = await _api.getJson('/dashboard');
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    final activities = data['recentActivity'] as List<dynamic>? ?? [];
    return DashboardData(
      user: UserProfile.fromJson(data['user'] as Map<String, dynamic>),
      scansThisWeek: (stats['scansThisWeek'] as num?)?.toInt() ?? 0,
      threatsBlocked: (stats['threatsBlocked'] as num?)?.toInt() ?? 0,
      recentActivity: activities
          .map((a) => ActivityItem.fromApi(a as Map<String, dynamic>))
          .toList(),
    );
  }
}
