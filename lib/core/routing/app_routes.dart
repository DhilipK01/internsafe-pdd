abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const terms = '/terms';
  static const privacy = '/privacy';


  static const home = '/home';
  static const scan = '/scan';
  static const verify = '/verify';
  static const blacklist = '/blacklist';
  static const profile = '/profile';

  static const resumeScanning = '/scan/scanning';
  static const resumeReport = '/scan/report';

  static const offerCheck = '/offer/check';
  static const offerScanning = '/offer/scanning';
  static const offerGenuine = '/offer/genuine';
  static const offerFake = '/offer/fake';

  static const companyVerify = '/company/verify';
  static const companyVerified = '/company/verified';
  static const companySuspicious = '/company/suspicious';
  static const companyCommunityReports = '/company/reports';

  static String companyCommunityReportsFor(String company) =>
      '$companyCommunityReports?q=${Uri.encodeComponent(company)}';

  static const dataSafety = '/data-safety';
  static const dataSafetyResult = '/data-safety/result';

  static const blacklistResult = '/blacklist/result';
  static const reportCompany = '/blacklist/report';

  static const history = '/history';
  static const myUploads = '/uploads';
  static const filePreview = '/uploads/preview';

  static String historyDetail(String activityId) => '/history/$activityId';
  static String uploadDetail(String fileId) => '/upload/$fileId';
  static String analysisDetail(String id) => '/analysis/$id';
  static String libraryDetail(String kind, String id) => '/library/$kind/$id';

  /// Deep link: https://{SHARE_HOST}/share/{token} or internsafe://share/{token}
  static String sharedContent(String token) => '/share/$token';
  static String viewContent(String token) => '/view/$token';
  static String reportContent(String token) => '/report/$token';

  static const shareUnavailable = '/share-unavailable';
}
