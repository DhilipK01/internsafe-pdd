import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/scan_providers.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/utils/file_validator.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/widgets/primary_button.dart';
import 'package:internsfe/core/widgets/upload_drop_zone.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mime/mime.dart';

class CheckOfferScreen extends ConsumerStatefulWidget {
  const CheckOfferScreen({super.key});

  @override
  ConsumerState<CheckOfferScreen> createState() => _CheckOfferScreenState();
}

class _CheckOfferScreenState extends ConsumerState<CheckOfferScreen> {
  final _controller = TextEditingController();
  SelectedUploadFile? _selectedFile;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasInput =>
      _controller.text.trim().isNotEmpty || _selectedFile != null;

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    final f = result?.files.single;
    if (f?.bytes == null) {
      if (f != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unable to read the selected file')));
      }
      return;
    }
    final bytes = f!.bytes!;
    final error = FileValidator.validateResumeOrImage(
      fileName: f.name,
      sizeBytes: f.size,
      mimeType: lookupMimeType(f.name, headerBytes: bytes),
      headerBytes: bytes,
    );
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }
    setState(() {
      _selectedFile = SelectedUploadFile(
        name: f.name,
        bytes: bytes,
        mimeType: lookupMimeType(f.name, headerBytes: bytes),
      );
    });
  }

  void _submit() {
    if (!_hasInput) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paste offer text or upload a document first'),
        ),
      );
      return;
    }
    ref.read(offerTextProvider.notifier).state = _controller.text.trim();
    ref.read(selectedOfferFileProvider.notifier).state = _selectedFile;
    context.push(AppRoutes.offerScanning);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Offer Detector',
      showBackToHome: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Provide real offer text or upload a document. No analysis runs without input.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.mutedColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _controller,
              maxLines: 8,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Paste internship offer text here...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            UploadDropZone(
              title: _selectedFile?.name ?? 'Upload offer document',
              subtitle: _selectedFile != null ? 'Document selected' : 'PDF or image',
              icon: LucideIcons.fileUp,
              onTap: _pickDocument,
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: _hasInput ? 'Submit Offer' : 'Input Required',
              icon: LucideIcons.send,
              onPressed: _hasInput ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
