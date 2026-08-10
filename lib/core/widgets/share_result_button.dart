import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/share/shareable_item.dart';
import 'package:internsfe/core/widgets/share_options_sheet.dart';
import 'package:internsfe/domain/repositories/share_repository.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ShareResultButton extends ConsumerStatefulWidget {
  const ShareResultButton({
    super.key,
    required this.resourceType,
    this.resourceId,
    this.companyName,
    this.query,
  });

  final ShareResourceType resourceType;
  final String? resourceId;
  final String? companyName;
  final String? query;

  @override
  ConsumerState<ShareResultButton> createState() => _ShareResultButtonState();
}

class _ShareResultButtonState extends ConsumerState<ShareResultButton> {
  bool _loading = false;

  Future<void> _share() async {
    setState(() => _loading = true);
    try {
      final item = ShareableItem(
        deleteType: 'scan',
        shareType: widget.resourceType,
        resourceId: widget.resourceId,
        companyName: widget.companyName,
        query: widget.query,
        requiresSensitiveConfirm:
            widget.resourceType == ShareResourceType.scan ||
            widget.resourceType == ShareResourceType.offerCheck ||
            widget.resourceType == ShareResourceType.upload,
      );
      if (!mounted) return;
      await showShareOptionsSheet(context, ref, item);
      HapticFeedback.lightImpact();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _share,
      icon: _loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.mutedColor,
              ),
            )
          : const Icon(LucideIcons.share2, size: 18),
      label: Text(_loading ? 'Creating link…' : 'Share'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}
