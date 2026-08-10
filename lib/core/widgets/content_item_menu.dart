import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/core/services/share_service.dart';
import 'package:internsfe/core/share/shareable_item.dart';
import 'package:internsfe/core/dialogs/confirmation_dialog_service.dart';
import 'package:internsfe/core/widgets/share_options_sheet.dart';
import 'package:internsfe/data/api/api_exception.dart';
import 'package:lucide_icons/lucide_icons.dart';

typedef OnContentDeleted = void Function();

class ContentItemMenu extends ConsumerWidget {
  const ContentItemMenu({
    super.key,
    required this.item,
    required this.onDeleted,
    this.activityId,
  });

  final ShareableItem item;
  final OnContentDeleted onDeleted;
  final String? activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.moreVertical),
      onSelected: (value) => _handle(context, ref, value),
      itemBuilder: (context) => [
        if (item.shareType != null)
          const PopupMenuItem(value: 'share', child: Text('Share')),
        if (item.shareType != null)
          const PopupMenuItem(value: 'copy', child: Text('Copy link')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  Future<void> _handle(BuildContext context, WidgetRef ref, String action) async {
    if (action == 'share') {
      await showShareOptionsSheet(context, ref, item);
      return;
    }
    if (action == 'copy') {
      await _copyLink(context, ref);
      return;
    }
    if (action == 'delete') {
      await _delete(context, ref);
    }
  }

  Future<void> _copyLink(BuildContext context, WidgetRef ref) async {
    if (item.shareType == null) return;
    try {
      await shareService(ref).copyLink(context, item);
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is ApiException
          ? e.message
          : 'Unable to generate share link. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final label = item.label;
    final request = item.deleteType == 'file'
        ? ConfirmationPresets.deleteUpload(fileName: label)
        : ConfirmationPresets.deleteReport(itemLabel: label ?? 'report');

    final ok = await ConfirmationDialogService.confirmAndRun(
      context: context,
      request: request,
      loadingMessage: 'Deleting…',
      successMessage: 'Report deleted successfully.',
      action: () async {
        final deleteId = activityId ?? item.resourceId ?? '';
        if (deleteId.isEmpty) {
          throw ApiException('Cannot delete: missing item id');
        }
        await ref.read(contentRepositoryProvider).deleteContent(
              contentType: item.deleteType,
              contentId: deleteId,
            );
      },
    );
    if (ok && context.mounted) onDeleted();
  }
}
