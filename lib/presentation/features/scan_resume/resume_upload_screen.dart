import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:internsfe/application/providers/scan_providers.dart';
import 'package:internsfe/core/constants/app_colors.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/utils/file_validator.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/widgets/primary_button.dart';
import 'package:internsfe/core/widgets/section_title.dart';
import 'package:internsfe/core/widgets/upload_drop_zone.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mime/mime.dart';

class ResumeUploadScreen extends ConsumerStatefulWidget {
  const ResumeUploadScreen({super.key});

  @override
  ConsumerState<ResumeUploadScreen> createState() => _ResumeUploadScreenState();
}

class _ResumeUploadScreenState extends ConsumerState<ResumeUploadScreen> {
  SelectedUploadFile? _selectedFile;

  Future<void> _setFile({
    required String name,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    final error = FileValidator.validateResumeOrImage(
      fileName: name,
      sizeBytes: bytes.lengthInBytes,
      mimeType: mimeType,
      headerBytes: bytes,
    );
    if (error != null) {
      _showError(error);
      return;
    }
    setState(() {
      _selectedFile = SelectedUploadFile(name: name, bytes: bytes, mimeType: mimeType);
    });
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) {
      if (file != null) _showError('Unable to read the selected file');
      return;
    }
    final bytes = file!.bytes!;
    await _setFile(
      name: file.name,
      bytes: bytes,
      mimeType: lookupMimeType(file.name, headerBytes: bytes),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    await _setFile(
      name: picked.name,
      bytes: bytes,
      mimeType: lookupMimeType(picked.name, headerBytes: bytes),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _uploadAndScan() {
    if (_selectedFile == null) {
      _showError('Please upload a file first');
      return;
    }
    ref.read(selectedResumeFileProvider.notifier).state = _selectedFile;
    context.push(AppRoutes.resumeScanning);
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _selectedFile != null;

    return AppScaffold(
      title: 'Resume Scanner',
      showBackToHome: false,
      showBottomNav: true,
      bottomNavIndex: 1,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select a real resume file. Analysis only runs after a successful upload.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.mutedColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            UploadDropZone(
              title: hasFile ? _selectedFile!.name : 'Tap to select resume',
              subtitle: hasFile
                  ? 'File ready for upload'
                  : 'PDF, PNG, or JPG up to 10MB',
              onTap: _pickPdf,
            ),
            if (!hasFile) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Please upload a file first',
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.warningAmber,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            const SectionTitle(title: 'Or choose a source'),
            _SourceButton(
              icon: LucideIcons.fileText,
              label: 'Upload PDF',
              onTap: _pickPdf,
            ),
            const SizedBox(height: AppSpacing.md),
            _SourceButton(
              icon: LucideIcons.image,
              label: 'Upload Image',
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: AppSpacing.md),
            _SourceButton(
              icon: LucideIcons.camera,
              label: 'Scan from Camera',
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: hasFile ? 'Upload & Submit' : 'Upload Required',
              icon: LucideIcons.upload,
              onPressed: hasFile ? _uploadAndScan : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(AppSpacing.lg),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
