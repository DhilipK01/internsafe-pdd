import 'package:internsfe/core/enums/risk_level.dart';
import 'package:internsfe/data/api/api_client.dart';
import 'package:internsfe/domain/entities/blacklist_entry.dart';
import 'package:internsfe/domain/entities/company_verification.dart';
import 'package:internsfe/domain/repositories/company_repository.dart';

class ApiCompanyRepository implements CompanyRepository {
  ApiCompanyRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<String>> searchCompanies(String query) async {
    final data = await _api.getJson('/companies/search', query: {'q': query});
    final results = data['results'] as List<dynamic>? ?? [];
    return results
        .map((r) => (r as Map)['company_name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  Future<CompanyCommunityReports> fetchCommunityReports(String query) async {
    final data =
        await _api.getJson('/companies/reports', query: {'q': query});
    final reports = (data['reports'] as List<dynamic>? ?? [])
        .map((r) => _mapReport(r as Map))
        .toList();
    return CompanyCommunityReports(
      query: data['query'] as String? ?? query,
      companyName: reports.isNotEmpty
          ? (reports.first.companyName ?? query)
          : query,
      reportCount: (data['reportCount'] as num?)?.toInt() ?? reports.length,
      dangerScore: (data['dangerScore'] as num?)?.toInt() ?? 0,
      trustScore: (data['trustScore'] as num?)?.toInt() ?? 0,
      reports: reports,
      fraudTypes: (data['fraudTypes'] as List<dynamic>?)
              ?.map((e) {
                if (e is Map) return e['fraud_type'] as String? ?? '';
                return e.toString();
              })
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
    );
  }

  @override
  Future<CompanyVerification> verifyCompany(String companyName) async {
    final data = await _api.postJson(
      '/companies/verify',
      body: {'companyName': companyName},
      receiveTimeout: const Duration(seconds: 90),
      connectTimeout: const Duration(seconds: 30),
    );
    final status = data['status'] as String? ?? 'no_data';
    final reportCount = (data['reportCount'] as num?)?.toInt() ?? 0;
    final trustScore = (data['trustScore'] as num?)?.toInt() ?? 0;
    final dangerScore = (data['dangerScore'] as num?)?.toInt() ?? 0;
    final confidence = (data['confidence'] as num?)?.toInt() ?? 0;
    final webComplaints = (data['complaintCount'] as num?)?.toInt() ?? 0;
    final intel = data['internetIntelligence'] as Map<String, dynamic>?;

    RiskLevel risk;
    if (status == 'suspicious' || dangerScore >= 70 || webComplaints >= 3) {
      risk = RiskLevel.suspicious;
    } else if (status == 'verified' && trustScore >= 60) {
      risk = RiskLevel.genuine;
    } else if (reportCount > 0 || webComplaints > 0) {
      risk = RiskLevel.suspicious;
    } else if (trustScore >= 70) {
      risk = RiskLevel.genuine;
    } else {
      risk = RiskLevel.safe;
    }

    final badgesRaw = data['badges'] as List<dynamic>? ?? [];
    final badges = <VerificationBadgeItem>[
      ...badgesRaw.whereType<Map>().map((b) {
        return VerificationBadgeItem(
          label: b['label'] as String? ?? '',
          verified: b['verified'] as bool? ?? false,
          detail: b['detail'] as String? ?? '',
        );
      }),
    ];

    if (badges.isEmpty) {
      badges.addAll([
        VerificationBadgeItem(
          label: 'Community reports',
          verified: reportCount == 0,
          detail: '$reportCount report(s) in INTERNSAFE',
        ),
        if (intel != null)
          VerificationBadgeItem(
            label: 'Internet intelligence',
            verified:
                intel['internet_status'] == 'completed' && webComplaints == 0,
            detail: intel['internet_reputation_summary'] as String? ??
                'Web analysis',
          ),
      ]);
    }

    return CompanyVerification(
      companyName: data['companyName'] as String? ?? companyName,
      trustScore: trustScore,
      dangerScore: dangerScore,
      confidence: confidence,
      reportCount: reportCount,
      status: risk,
      recommendation: data['message'] as String? ?? 'No data available.',
      badges: badges,
      analyzedAt: data['analyzedAt'] as String?,
      internetSummary: intel?['internet_reputation_summary'] as String?,
      activityStatus: intel?['activity_status'] as String? ??
          data['activityStatus'] as String?,
      suspiciousIndicators:
          (intel?['suspicious_indicators'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
      positiveIndicators: (data['positiveIndicators'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      warningIndicators: (data['warningIndicators'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      dangerIndicators: (data['dangerIndicators'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      internetIntelligence:
          intel != null ? _mapInternetIntel(intel) : null,
      communityIntelligence: _mapCommunityIntel(
        data['communityIntelligence'] as Map<String, dynamic>?,
        reportCount,
      ),
      evidenceCount: (intel?['snippet_count'] as num?)?.toInt() ??
          reportCount,
    );
  }

  CompanyCommunityIntel? _mapCommunityIntel(
    Map<String, dynamic>? raw,
    int reportCount,
  ) {
    if (raw == null && reportCount == 0) return null;
    final breakdown = (raw?['fraudTypeBreakdown'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map(
          (m) => FraudTypeCount(
            type: m['type'] as String? ?? '',
            count: (m['count'] as num?)?.toInt() ?? 0,
          ),
        )
        .where((f) => f.type.isNotEmpty)
        .toList();
    return CompanyCommunityIntel(
      totalReports: (raw?['totalReports'] as num?)?.toInt() ?? reportCount,
      aiSummary: raw?['aiSummary'] as String?,
      summaries: (raw?['summaries'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      riskIndicators: (raw?['riskIndicators'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      fraudTypeBreakdown: breakdown,
    );
  }

  CompanyInternetIntel _mapInternetIntel(Map<String, dynamic> intel) {
    return CompanyInternetIntel(
      internetStatus: intel['internet_status'] as String?,
      reputationSummary: intel['internet_reputation_summary'] as String?,
      complaintCount: (intel['complaint_count'] as num?)?.toInt() ?? 0,
      snippetCount: (intel['snippet_count'] as num?)?.toInt() ?? 0,
      positiveMentions: (intel['positive_mentions'] as num?)?.toInt() ?? 0,
      hiringMentions: (intel['hiring_mentions'] as num?)?.toInt() ?? 0,
      webTrustScore: (intel['web_trust_score'] as num?)?.toInt(),
      activityStatus: intel['activity_status'] as String?,
      activitySummary: intel['recent_activity_summary'] as String?,
      evidenceSnippets: (intel['evidence_snippets'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      sourcesChecked: (intel['sources_checked'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  CommunityReport _mapReport(Map r) {
    return CommunityReport(
      id: r['id'] as String,
      reportType: r['report_type'] as String? ?? r['fraud_type'] as String? ?? 'Report',
      fraudType: r['fraud_type'] as String?,
      college: r['college'] as String? ?? 'Unknown',
      date: r['created_at'] as String? ?? '',
      description: r['description'] as String? ?? '',
      title: r['title'] as String?,
      companyName: r['company_name'] as String?,
      severity: (r['severity'] as num?)?.toInt() ?? 3,
      evidenceCount: (r['evidence_count'] as num?)?.toInt() ?? 0,
      status: r['status'] as String?,
    );
  }
}
