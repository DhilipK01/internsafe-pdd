import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/domain/entities/blacklist_entry.dart';
import 'package:internsfe/domain/entities/company_verification.dart';
import 'package:internsfe/domain/entities/data_safety_result.dart';
import 'package:internsfe/domain/entities/scan_job.dart';
import 'package:internsfe/domain/repositories/offer_repository.dart';

class SelectedUploadFile {
  const SelectedUploadFile({
    required this.name,
    required this.bytes,
    this.mimeType,
  });

  final String name;
  final Uint8List bytes;
  final String? mimeType;
}

final resumeScanJobProvider = StateProvider<ScanJob?>((ref) => null);
final offerCheckJobProvider = StateProvider<OfferCheckJob?>((ref) => null);
final offerTextProvider = StateProvider<String>((ref) => '');
final companyResultProvider = StateProvider<CompanyVerification?>((ref) => null);
final blacklistResultProvider = StateProvider<BlacklistEntry?>((ref) => null);
final dataSafetyResultProvider = StateProvider<DataSafetyResult?>((ref) => null);

final selectedResumeFileProvider =
    StateProvider<SelectedUploadFile?>((ref) => null);
final selectedOfferFileProvider =
    StateProvider<SelectedUploadFile?>((ref) => null);

final dashboardProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(dashboardRepositoryProvider).fetchDashboard();
});

final blacklistSearchProvider =
    FutureProvider.family<BlacklistEntry?, String>((ref, query) async {
  if (query.trim().length < 2) return null;
  return ref.read(blacklistRepositoryProvider).searchCompany(query.trim());
});

final companySearchProvider =
    FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.trim().length < 2) return [];
  return ref.read(companyRepositoryProvider).searchCompanies(query.trim());
});
