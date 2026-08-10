import 'package:internsfe/data/api/api_client.dart';
import 'package:internsfe/domain/entities/blacklist_entry.dart';
import 'package:internsfe/domain/repositories/blacklist_repository.dart';

class ApiBlacklistRepository implements BlacklistRepository {
  ApiBlacklistRepository(this._api);

  final ApiClient _api;

  @override
  Future<BlacklistEntry?> searchCompany(String query) async {
    final data = await _api.getJson('/blacklist/search', query: {'q': query});
    if (data['found'] != true) return null;

    final reports = (data['reports'] as List<dynamic>? ?? [])
        .map((r) {
          final m = r as Map;
          return CommunityReport(
            id: m['id'] as String,
            reportType: m['report_type'] as String? ?? m['fraud_type'] as String? ?? 'Report',
            fraudType: m['fraud_type'] as String?,
            college: m['college'] as String? ?? 'Unknown',
            date: m['created_at'] as String? ?? '',
            description: m['description'] as String? ?? '',
            title: m['title'] as String?,
            companyName: m['company_name'] as String?,
            severity: (m['severity'] as num?)?.toInt() ?? 3,
            evidenceCount: (m['evidence_count'] as num?)?.toInt() ?? 0,
            status: m['status'] as String?,
          );
        })
        .toList();

    return BlacklistEntry(
      companyName: data['companyName'] as String? ?? query,
      dangerScore: (data['dangerScore'] as num?)?.toInt() ?? 0,
      reportCount: (data['reportCount'] as num?)?.toInt() ?? 0,
      fraudTypes: (data['fraudTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      recentReport: data['recentReport'] as String? ?? '',
      collegeClusters: (data['collegeClusters'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      reports: reports,
    );
  }

  @override
  Future<void> reportCompany({
    required String companyName,
    required String fraudType,
    required String description,
    required String college,
    String? evidenceFileId,
  }) async {
    await _api.postJson('/blacklist/reports', body: {
      'companyName': companyName,
      'fraudType': fraudType,
      'description': description,
      'college': college,
      if (evidenceFileId != null) 'evidenceFileId': evidenceFileId,
    });
  }
}
