import 'package:internsfe/domain/entities/uploaded_file.dart';

abstract class FileRepository {
  Future<List<UploadedFile>> listMyFiles({String? uploadType});

  Future<List<int>> downloadFileContent(String fileId);
}
