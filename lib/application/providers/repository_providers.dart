import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internsfe/application/providers/app_providers.dart';

export 'auth_providers.dart';
import 'package:internsfe/data/repositories/api_blacklist_repository.dart';
import 'package:internsfe/data/repositories/api_company_repository.dart';
import 'package:internsfe/data/repositories/api_dashboard_repository.dart';
import 'package:internsfe/data/repositories/api_data_safety_repository.dart';
import 'package:internsfe/data/repositories/api_history_repository.dart';
import 'package:internsfe/data/repositories/api_offer_repository.dart';
import 'package:internsfe/data/repositories/api_file_repository.dart';
import 'package:internsfe/data/repositories/api_resume_repository.dart';
import 'package:internsfe/domain/repositories/blacklist_repository.dart';
import 'package:internsfe/domain/repositories/company_repository.dart';
import 'package:internsfe/domain/repositories/dashboard_repository.dart';
import 'package:internsfe/domain/repositories/data_safety_repository.dart';
import 'package:internsfe/domain/repositories/history_repository.dart';
import 'package:internsfe/domain/repositories/offer_repository.dart';
import 'package:internsfe/domain/repositories/file_repository.dart';
import 'package:internsfe/domain/repositories/resume_repository.dart';
import 'package:internsfe/domain/repositories/share_repository.dart';
import 'package:internsfe/data/repositories/api_share_repository.dart';
import 'package:internsfe/data/repositories/api_content_repository.dart';
import 'package:internsfe/data/repositories/api_library_repository.dart';
import 'package:internsfe/domain/repositories/content_repository.dart';
import 'package:internsfe/domain/repositories/library_repository.dart';

final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return ApiOfferRepository(ref.watch(apiClientProvider));
});

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return ApiCompanyRepository(ref.watch(apiClientProvider));
});

final resumeRepositoryProvider = Provider<ResumeRepository>((ref) {
  return ApiResumeRepository(ref.watch(apiClientProvider));
});

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  return ApiFileRepository(ref.watch(apiClientProvider));
});

final blacklistRepositoryProvider = Provider<BlacklistRepository>((ref) {
  return ApiBlacklistRepository(ref.watch(apiClientProvider));
});

final dataSafetyRepositoryProvider = Provider<DataSafetyRepository>((ref) {
  return ApiDataSafetyRepository(ref.watch(apiClientProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return ApiDashboardRepository(ref.watch(apiClientProvider));
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return ApiHistoryRepository(ref.watch(apiClientProvider));
});

final shareRepositoryProvider = Provider<ShareRepository>((ref) {
  return ApiShareRepository(ref.watch(apiClientProvider));
});

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ApiContentRepository(ref.watch(apiClientProvider));
});

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return ApiLibraryRepository(ref.watch(apiClientProvider));
});
