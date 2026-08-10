import 'package:internsfe/domain/entities/library_detail.dart';

abstract class LibraryRepository {
  Future<LibraryDetail> fetchDetail({required String kind, required String id});
}
