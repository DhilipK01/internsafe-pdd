import 'package:mime/mime.dart';

abstract final class FileValidator {
  static const maxBytes = 10 * 1024 * 1024;
  static const allowedMimes = {
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  static String? validateResumeOrImage({
    required String fileName,
    required int sizeBytes,
    String? mimeType,
    List<int>? headerBytes,
  }) {
    if (sizeBytes <= 0) return 'Please select a valid file';
    if (sizeBytes > maxBytes) return 'File must be 10MB or smaller';
    final mime = mimeType ?? lookupMimeType(fileName, headerBytes: headerBytes);
    if (mime == null || !allowedMimes.contains(mime)) {
      return 'Only PDF, JPG, PNG, or WEBP files are allowed';
    }
    return null;
  }
}
