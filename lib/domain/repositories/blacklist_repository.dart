import 'package:internsfe/domain/entities/blacklist_entry.dart';

abstract class BlacklistRepository {
  Future<BlacklistEntry?> searchCompany(String query);
  Future<void> reportCompany({
    required String companyName,
    required String fraudType,
    required String description,
    required String college,
    String? evidenceFileId,
  });
}
