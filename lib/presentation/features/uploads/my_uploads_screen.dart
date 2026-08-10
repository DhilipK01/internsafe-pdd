import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/presentation/features/history/library_navigation.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/widgets/empty_state.dart';
import 'package:internsfe/core/share/shareable_item.dart';
import 'package:internsfe/core/widgets/content_item_menu.dart';
import 'package:internsfe/core/widgets/section_title.dart';
import 'package:internsfe/domain/entities/uploaded_file.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

final myUploadsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(fileRepositoryProvider).listMyFiles();
});

class MyUploadsScreen extends ConsumerWidget {
  const MyUploadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadsAsync = ref.watch(myUploadsProvider);

    return AppScaffold(
      title: 'My Uploads',
      showBackToHome: true,
      body: uploadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: 'Could not load uploads',
          message: e.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(myUploadsProvider),
        ),
        data: (files) {
          if (files.isEmpty) {
            return EmptyState(
              title: 'No uploads yet',
              message:
                  'Resume scans, offer documents, and evidence files you upload will appear here.',
              actionLabel: 'Scan a resume',
              onAction: () => context.go(AppRoutes.scan),
            );
          }

          final grouped = <String, List<UploadedFile>>{};
          for (final f in files) {
            grouped.putIfAbsent(f.uploadType, () => []).add(f);
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myUploadsProvider),
            child: ListView(
              children: [
                Text(
                  'Documents and images saved for AI analysis. Tap to preview.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.mutedColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final entry in grouped.entries) ...[
                  SectionTitle(title: _labelForType(entry.key)),
                  const SizedBox(height: AppSpacing.sm),
                  ...entry.value.map(
                    (f) => _UploadTile(
                      file: f,
                      onTap: () => openUploadReport(context, f.id),
                      onDeleted: () => ref.invalidate(myUploadsProvider),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  static String _labelForType(String type) {
    switch (type) {
      case 'resume':
        return 'Resumes';
      case 'offer':
        return 'Offer documents';
      case 'evidence':
        return 'Report evidence';
      default:
        return 'Other files';
    }
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.file,
    required this.onTap,
    required this.onDeleted,
  });

  final UploadedFile file;
  final VoidCallback onTap;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final icon = file.isImage
        ? LucideIcons.image
        : file.isPdf
            ? LucideIcons.fileText
            : LucideIcons.file;

    final sizeKb = (file.fileSize / 1024).toStringAsFixed(1);
    final date = file.createdAtIst?.isNotEmpty == true
        ? file.createdAtIst!
        : (file.createdAt != null
            ? DateFormat.yMMMd().add_jm().format(file.createdAt!.toUtc())
            : '');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(file.fileName, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            file.mimeType,
            '$sizeKb KB',
            if (date.isNotEmpty) date,
            if (!file.hasContent) 'Preview unavailable',
          ].join(' · '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ContentItemMenu(
              item: ShareableItem.fromUpload(file),
              onDeleted: onDeleted,
            ),
            if (file.hasContent)
              const Icon(LucideIcons.chevronRight)
            else
              Icon(LucideIcons.cloudOff, color: context.mutedColor),
          ],
        ),
        onTap: file.hasContent ? onTap : null,
      ),
    );
  }
}
