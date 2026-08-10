import 'package:equatable/equatable.dart';
import 'package:internsfe/core/enums/risk_level.dart';
import 'package:internsfe/domain/entities/blacklist_entry.dart';

class CompanyVerification extends Equatable {
  const CompanyVerification({
    required this.companyName,
    required this.trustScore,
    required this.status,
    required this.badges,
    required this.recommendation,
    this.reportCount = 0,
    this.dangerScore = 0,
    this.confidence = 0,
    this.analyzedAt,
    this.internetSummary,
    this.activityStatus,
    this.suspiciousIndicators = const [],
    this.positiveIndicators = const [],
    this.warningIndicators = const [],
    this.dangerIndicators = const [],
    this.internetIntelligence,
    this.communityIntelligence,
    this.evidenceCount = 0,
  });

  final String companyName;
  final int trustScore;
  final int dangerScore;
  final int confidence;
  final RiskLevel status;
  final List<VerificationBadgeItem> badges;
  final String recommendation;
  final int reportCount;
  final String? analyzedAt;
  final String? internetSummary;
  final String? activityStatus;
  final List<String> suspiciousIndicators;
  final List<String> positiveIndicators;
  final List<String> warningIndicators;
  final List<String> dangerIndicators;
  final CompanyInternetIntel? internetIntelligence;
  final CompanyCommunityIntel? communityIntelligence;
  final int evidenceCount;

  bool get isVerified => status == RiskLevel.genuine || status == RiskLevel.safe;

  bool get hasCommunityReports => reportCount > 0;

  @override
  List<Object?> get props => [
        companyName,
        trustScore,
        dangerScore,
        confidence,
        status,
        badges,
        recommendation,
        reportCount,
        analyzedAt,
        internetSummary,
        activityStatus,
        suspiciousIndicators,
        positiveIndicators,
        warningIndicators,
        dangerIndicators,
        internetIntelligence,
        communityIntelligence,
        evidenceCount,
      ];
}

class CompanyCommunityIntel extends Equatable {
  const CompanyCommunityIntel({
    this.totalReports = 0,
    this.aiSummary,
    this.summaries = const [],
    this.riskIndicators = const [],
    this.fraudTypeBreakdown = const [],
  });

  final int totalReports;
  final String? aiSummary;
  final List<String> summaries;
  final List<String> riskIndicators;
  final List<FraudTypeCount> fraudTypeBreakdown;

  @override
  List<Object?> get props =>
      [totalReports, aiSummary, summaries, riskIndicators, fraudTypeBreakdown];
}

class FraudTypeCount extends Equatable {
  const FraudTypeCount({required this.type, required this.count});

  final String type;
  final int count;

  @override
  List<Object?> get props => [type, count];
}

class CompanyInternetIntel extends Equatable {
  const CompanyInternetIntel({
    this.internetStatus,
    this.reputationSummary,
    this.complaintCount = 0,
    this.snippetCount = 0,
    this.positiveMentions = 0,
    this.hiringMentions = 0,
    this.webTrustScore,
    this.activityStatus,
    this.activitySummary,
    this.evidenceSnippets = const [],
    this.sourcesChecked = const [],
  });

  final String? internetStatus;
  final String? reputationSummary;
  final int complaintCount;
  final int snippetCount;
  final int positiveMentions;
  final int hiringMentions;
  final int? webTrustScore;
  final String? activityStatus;
  final String? activitySummary;
  final List<String> evidenceSnippets;
  final List<String> sourcesChecked;

  @override
  List<Object?> get props => [
        internetStatus,
        reputationSummary,
        complaintCount,
        snippetCount,
        webTrustScore,
        activityStatus,
      ];
}

class CompanyCommunityReports extends Equatable {
  const CompanyCommunityReports({
    required this.query,
    required this.companyName,
    required this.reportCount,
    required this.dangerScore,
    required this.trustScore,
    required this.reports,
    this.fraudTypes = const [],
  });

  final String query;
  final String companyName;
  final int reportCount;
  final int dangerScore;
  final int trustScore;
  final List<CommunityReport> reports;
  final List<String> fraudTypes;

  @override
  List<Object?> get props =>
      [query, companyName, reportCount, dangerScore, trustScore, reports];
}

class VerificationBadgeItem extends Equatable {
  const VerificationBadgeItem({
    required this.label,
    required this.verified,
    required this.detail,
  });

  final String label;
  final bool verified;
  final String detail;

  @override
  List<Object?> get props => [label, verified, detail];
}
