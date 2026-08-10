import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/core/share/shareable_item.dart';
import 'package:internsfe/core/widgets/content_item_menu.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/widgets/primary_button.dart';
import 'package:internsfe/domain/entities/uploaded_file.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FilePreviewScreen extends ConsumerStatefulWidget {
  const FilePreviewScreen({super.key, required this.file});

  final UploadedFile file;

  @override
  ConsumerState<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends ConsumerState<FilePreviewScreen> {
  Uint8List? _bytes;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data =
          await ref.read(fileRepositoryProvider).downloadFileContent(widget.file.id);
      if (mounted) {
        setState(() {
          _bytes = Uint8List.fromList(data);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.file;

    return AppScaffold(
      title: f.fileName,
      showBackToHome: true,
      actions: [
        ContentItemMenu(
          item: ShareableItem.fromUpload(f),
          onDeleted: () => context.pop(),
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 48),
                        const SizedBox(height: AppSpacing.md),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.lg),
                        PrimaryButton(label: 'Retry', onPressed: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          _load();
                        }),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${f.mimeType} · ${(f.fileSize / 1024).toStringAsFixed(1)} KB',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.mutedColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (f.isImage && _bytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _bytes!,
                            fit: BoxFit.contain,
                          ),
                        )
                      else
                        _DocumentPlaceholder(file: f),
                    ],
                  ),
                ),
    );
  }
}

class _DocumentPlaceholder extends StatelessWidget {
  const _DocumentPlaceholder({required this.file});

  final UploadedFile file;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            file.isPdf ? LucideIcons.fileText : LucideIcons.file,
            size: 64,
            color: context.mutedColor,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            file.isPdf ? 'PDF document' : 'Document',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Preview is available for images. This file was uploaded for AI analysis.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(color: context.mutedColor),
          ),
        ],
      ),
    );
  }
}
