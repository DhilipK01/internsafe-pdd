import 'package:internsfe/domain/entities/activity_item.dart';
import 'package:internsfe/domain/entities/user_profile.dart';

class DashboardData {
  const DashboardData({
    required this.user,
    required this.scansThisWeek,
    required this.threatsBlocked,
    required this.recentActivity,
  });

  final UserProfile user;
  final int scansThisWeek;
  final int threatsBlocked;
  final List<ActivityItem> recentActivity;
}

abstract class DashboardRepository {
  Future<DashboardData> fetchDashboard();
}
