enum ShareResourceType {
  offerCheck('offer_check'),
  companyVerify('company_verify'),
  scan('scan'),
  blacklist('blacklist'),
  upload('upload'),
  dataSafety('data_safety');

  const ShareResourceType(this.apiValue);
  final String apiValue;
}

enum ShareVisibility {
  public('public'),
  private('private');

  const ShareVisibility(this.apiValue);
  final String apiValue;
}

enum ShareExpiryOption {
  hours24('24h'),
  days7('7d'),
  days14('14d'),
  never('never');

  const ShareExpiryOption(this.apiValue);
  final String apiValue;
}

class ShareLinkResult {
  const ShareLinkResult({
    required this.url,
    required this.token,
    required this.expiresAt,
    this.viewUrl,
    this.appUrl,
  });

  final String url;
  final String token;
  final String expiresAt;
  final String? viewUrl;
  final String? appUrl;
}

class SharedSnapshot {
  const SharedSnapshot({
    required this.resourceType,
    required this.snapshot,
    required this.expiresAt,
    this.documentPreviewUrl,
    this.webUrl,
    this.appUrl,
  });

  final String resourceType;
  final Map<String, dynamic> snapshot;
  final String expiresAt;
  final String? documentPreviewUrl;
  final String? webUrl;
  final String? appUrl;

  String get type => snapshot['type'] as String? ?? resourceType;
  String get title => snapshot['title'] as String? ?? 'Shared result';
  String? get subtitle => snapshot['subtitle'] as String?;
  String? get summary =>
      snapshot['summary'] as String? ?? snapshot['message'] as String?;

  bool get hasAnalysis {
    if (type == 'scan') {
      return snapshot['safetyScore'] != null ||
          snapshot['dangerScore'] != null ||
          (snapshot['findings'] as List?)?.isNotEmpty == true ||
          snapshot['aiRecommendation'] != null;
    }
    if (type == 'offer_check') {
      final a = snapshot['analysis'] as Map?;
      return a != null &&
          ((a['reasons'] as List?)?.isNotEmpty == true ||
              a['fraudScore'] != null ||
              a['scamProbability'] != null);
    }
    if (type == 'data_safety') return snapshot['summary'] != null;
    if (type == 'company_verify' || type == 'blacklist') {
      return snapshot['trustScore'] != null || snapshot['reportCount'] != null;
    }
    return false;
  }

  Map<String, dynamic>? get document =>
      snapshot['document'] as Map<String, dynamic>?;
}

abstract class ShareRepository {
  Future<ShareLinkResult> createShare({
    required ShareResourceType resourceType,
    String? resourceId,
    String? companyName,
    String? query,
    ShareVisibility visibility = ShareVisibility.public,
    ShareExpiryOption expiry = ShareExpiryOption.days14,
    bool confirmSensitive = false,
  });

  Future<SharedSnapshot> getShare(String token);

  Future<void> revokeShare(String token);
}
