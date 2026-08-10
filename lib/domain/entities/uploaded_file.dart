import 'package:equatable/equatable.dart';

class UploadedFile extends Equatable {
  const UploadedFile({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.uploadType,
    this.publicUrl,
    this.hasContent = false,
    this.createdAt,
    this.createdAtIst,
  });

  final String id;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String uploadType;
  final String? publicUrl;
  final bool hasContent;
  final DateTime? createdAt;
  final String? createdAtIst;

  bool get isImage =>
      mimeType.startsWith('image/') ||
      fileName.toLowerCase().endsWith('.png') ||
      fileName.toLowerCase().endsWith('.jpg') ||
      fileName.toLowerCase().endsWith('.jpeg') ||
      fileName.toLowerCase().endsWith('.webp');

  bool get isPdf =>
      mimeType == 'application/pdf' || fileName.toLowerCase().endsWith('.pdf');

  factory UploadedFile.fromJson(Map<String, dynamic> json) {
    return UploadedFile(
      id: json['id'] as String,
      fileName: json['fileName'] as String? ?? json['file_name'] as String,
      mimeType: json['mimeType'] as String? ?? json['mime_type'] as String,
      fileSize: (json['fileSize'] ?? json['file_size']) as int,
      uploadType: json['uploadType'] as String? ?? json['upload_type'] as String,
      publicUrl: json['publicUrl'] as String? ?? json['public_url'] as String?,
      hasContent: (json['has_content'] == 1) ||
          (json['has_content'] == true) ||
          json['has_content'] == '1',
      createdAtIst: json['created_at_ist'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, fileName, mimeType, fileSize];
}
