import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/core/deeplink/deep_link_handler.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/presentation/features/auth/login_screen.dart';
import 'package:internsfe/presentation/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:internsfe/presentation/features/auth/onboarding_screen.dart';
import 'package:internsfe/presentation/features/auth/splash_screen.dart';
import 'package:internsfe/presentation/features/blacklist/blacklist_result_screen.dart';
import 'package:internsfe/presentation/features/blacklist/blacklist_search_screen.dart';
import 'package:internsfe/presentation/features/blacklist/report_company_screen.dart';
import 'package:internsfe/presentation/features/company_verification/presentation/screens/community_reports_screen.dart';
import 'package:internsfe/presentation/features/company_verifier/company_suspicious_screen.dart';
import 'package:internsfe/presentation/features/company_verifier/company_verified_screen.dart';
import 'package:internsfe/presentation/features/company_verifier/verify_company_screen.dart';
import 'package:internsfe/presentation/features/data_safety/data_safety_advisor_screen.dart';
import 'package:internsfe/presentation/features/data_safety/data_safety_result_screen.dart';
import 'package:internsfe/presentation/features/history/history_screen.dart';
import 'package:internsfe/presentation/features/home/home_dashboard_screen.dart';
import 'package:internsfe/presentation/features/offer_detector/check_offer_screen.dart';
import 'package:internsfe/presentation/features/offer_detector/offer_fake_result_screen.dart';
import 'package:internsfe/presentation/features/offer_detector/offer_genuine_result_screen.dart';
import 'package:internsfe/presentation/features/offer_detector/offer_scanning_screen.dart';
import 'package:internsfe/presentation/features/profile/profile_screen.dart';
import 'package:internsfe/presentation/features/scan_resume/resume_report_screen.dart';
import 'package:internsfe/presentation/features/scan_resume/resume_scanning_screen.dart';
import 'package:internsfe/presentation/features/scan_resume/resume_upload_screen.dart';
import 'package:internsfe/domain/entities/uploaded_file.dart';
import 'package:internsfe/presentation/features/shared_report/presentation/resource_deep_link_screen.dart';
import 'package:internsfe/presentation/features/shared_report/presentation/shared_report_screen.dart';
import 'package:internsfe/presentation/features/shared_report/presentation/shared_report_unavailable_screen.dart';
import 'package:internsfe/presentation/features/history/report_detail_screen.dart';
import 'package:internsfe/presentation/features/uploads/file_preview_screen.dart';
import 'package:internsfe/presentation/features/uploads/my_uploads_screen.dart';
import 'package:internsfe/presentation/features/legal/terms_of_service_screen.dart';
import 'package:internsfe/presentation/features/legal/privacy_policy_screen.dart';

Widget _shareScreen(String token) => SharedReportScreen(token: token);

bool _isPublicSharePath(String path) {
  if (path.startsWith('/history/') ||
      path.startsWith('/upload/') ||
      path.startsWith('/analysis/') ||
      path.startsWith('/library/')) {
    return false;
  }
  if (path.startsWith('/report/')) {
    final segment = path.split('/').last;
    if (segment.contains('-') && segment.length >= 32) return false;
  }
  return path.startsWith('/s/') ||
      path.startsWith('/view/') ||
      path.startsWith('/share/') ||
      path.startsWith('/report/');
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) async {
      final deep = DeepLinkHandler.redirectForState(state);
      if (deep != null) return deep;

      final auth = ref.read(authRepositoryProvider);
      final path = state.matchedLocation;
      final isAuthRoute = path == AppRoutes.splash ||
          path == AppRoutes.onboarding ||
          path == AppRoutes.login ||
          path == AppRoutes.forgotPassword ||
          path == AppRoutes.terms ||
          path == AppRoutes.privacy;

      if (path == AppRoutes.splash) return null;
      if (path == AppRoutes.terms || path == AppRoutes.privacy) return null;
      if (_isPublicSharePath(path)) return null;

      final loggedIn = await auth.isLoggedIn();
      if (!loggedIn && !isAuthRoute) return AppRoutes.login;
      if (loggedIn && (path == AppRoutes.login || path == AppRoutes.onboarding)) {
        return AppRoutes.home;
      }
      return null;
    },
    onException: (context, state, router) {
      final deep = DeepLinkHandler.redirectForState(state) ??
          DeepLinkHandler.fromLocationString(state.uri.toString());
      if (deep != null) {
        router.go(deep);
        return;
      }
      router.go(AppRoutes.shareUnavailable);
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.scan,
        builder: (_, __) => const ResumeUploadScreen(),
      ),
      GoRoute(
        path: AppRoutes.verify,
        builder: (_, __) => const VerifyCompanyScreen(showBottomNav: true),
      ),
      GoRoute(
        path: AppRoutes.blacklist,
        builder: (_, __) => const BlacklistSearchScreen(showBottomNav: true),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.resumeScanning,
        builder: (_, __) => const ResumeScanningScreen(),
      ),
      GoRoute(
        path: AppRoutes.resumeReport,
        builder: (_, __) => const ResumeReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.offerCheck,
        builder: (_, __) => const CheckOfferScreen(),
      ),
      GoRoute(
        path: AppRoutes.offerScanning,
        builder: (_, __) => const OfferScanningScreen(),
      ),
      GoRoute(
        path: AppRoutes.offerGenuine,
        builder: (_, __) => const OfferGenuineResultScreen(),
      ),
      GoRoute(
        path: AppRoutes.offerFake,
        builder: (_, __) => const OfferFakeResultScreen(),
      ),
      GoRoute(
        path: AppRoutes.companyVerify,
        builder: (_, __) => const VerifyCompanyScreen(),
      ),
      GoRoute(
        path: AppRoutes.companyVerified,
        builder: (_, __) => const CompanyVerifiedScreen(),
      ),
      GoRoute(
        path: AppRoutes.companySuspicious,
        builder: (_, __) => const CompanySuspiciousScreen(),
      ),
      GoRoute(
        path: AppRoutes.companyCommunityReports,
        builder: (context, state) {
          final q = state.uri.queryParameters['q']?.trim() ?? '';
          return CommunityReportsScreen(companyQuery: q);
        },
      ),
      GoRoute(
        path: AppRoutes.dataSafety,
        builder: (_, __) => const DataSafetyAdvisorScreen(),
      ),
      GoRoute(
        path: AppRoutes.dataSafetyResult,
        builder: (_, __) => const DataSafetyResultScreen(),
      ),
      GoRoute(
        path: AppRoutes.blacklistResult,
        builder: (_, __) => const BlacklistResultScreen(),
      ),
      GoRoute(
        path: AppRoutes.reportCompany,
        builder: (_, __) => const ReportCompanyScreen(),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (_, __) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/history/:id',
        builder: (_, s) => ReportDetailScreen(
          kind: 'activity',
          id: s.pathParameters['id']!,
          activityId: s.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/upload/:id',
        builder: (_, s) => ReportDetailScreen(
          kind: 'upload',
          id: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/analysis/:id',
        builder: (_, s) => ReportDetailScreen(
          kind: 'analysis',
          id: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/library/:kind/:id',
        builder: (_, s) => ReportDetailScreen(
          kind: s.pathParameters['kind']!,
          id: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.myUploads,
        builder: (_, __) => const MyUploadsScreen(),
      ),
      GoRoute(
        path: AppRoutes.filePreview,
        builder: (_, state) => FilePreviewScreen(
          file: state.extra! as UploadedFile,
        ),
      ),
      GoRoute(
        path: AppRoutes.shareUnavailable,
        builder: (_, __) => const SharedReportUnavailableScreen(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (_, __) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (_, __) => const PrivacyPolicyScreen(),
      ),
      GoRoute(path: '/s/:token', builder: (_, s) => _shareScreen(s.pathParameters['token']!)),
      GoRoute(path: '/view/:token', builder: (_, s) => _shareScreen(s.pathParameters['token']!)),
      GoRoute(path: '/share/:token', builder: (_, s) => _shareScreen(s.pathParameters['token']!)),
      GoRoute(path: '/report/:token', builder: (_, s) => _shareScreen(s.pathParameters['token']!)),
      GoRoute(
        path: '/resume/:id',
        builder: (_, s) => ResourceDeepLinkScreen(
          resourceType: 'resume',
          resourceId: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/offer/:id',
        builder: (_, s) => ResourceDeepLinkScreen(
          resourceType: 'offer',
          resourceId: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/company/:id',
        builder: (_, s) => ResourceDeepLinkScreen(
          resourceType: 'company',
          resourceId: s.pathParameters['id']!,
        ),
      ),
    ],
  );
});
