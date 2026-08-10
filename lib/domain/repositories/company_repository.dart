import 'package:internsfe/domain/entities/company_verification.dart';

abstract class CompanyRepository {
  Future<List<String>> searchCompanies(String query);
  Future<CompanyVerification> verifyCompany(String companyName);
  Future<CompanyCommunityReports> fetchCommunityReports(String query);
}
