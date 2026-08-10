import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/services/share_service.dart';
import 'package:internsfe/core/share/shareable_item.dart';
import 'package:internsfe/data/api/api_exception.dart';
import 'package:internsfe/domain/repositories/share_repository.dart';

Future<void> showShareOptionsSheet(
  BuildContext context,
  WidgetRef ref,
  ShareableItem item,
) async {
  if (item.shareType == null) return;

  var visibility = ShareVisibility.public;
  var expiry = ShareExpiryOption.days7;
  var confirmSensitive = false;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Share ${item.label ?? "item"}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<ShareVisibility>(
                  initialValue: visibility,
                  decoration: const InputDecoration(labelText: 'Visibility'),
                  items: const [
                    DropdownMenuItem(
                      value: ShareVisibility.public,
                      child: Text('Public (anyone with link)'),
                    ),
                    DropdownMenuItem(
                      value: ShareVisibility.private,
                      child: Text('Private (view-only snapshot)'),
                    ),
                  ],
                  onChanged: (v) => setState(() => visibility = v ?? visibility),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<ShareExpiryOption>(
                  initialValue: expiry,
                  decoration: const InputDecoration(labelText: 'Link expires'),
                  items: const [
                    DropdownMenuItem(
                      value: ShareExpiryOption.hours24,
                      child: Text('24 hours'),
                    ),
                    DropdownMenuItem(
                      value: ShareExpiryOption.days7,
                      child: Text('7 days'),
                    ),
                    DropdownMenuItem(
                      value: ShareExpiryOption.days14,
                      child: Text('14 days'),
                    ),
                    DropdownMenuItem(
                      value: ShareExpiryOption.never,
                      child: Text('Never'),
                    ),
                  ],
                  onChanged: (v) => setState(() => expiry = v ?? expiry),
                ),
                if (item.requiresSensitiveConfirm) ...[
                  const SizedBox(height: AppSpacing.sm),
                  CheckboxListTile(
                    value: confirmSensitive,
                    onChanged: (v) =>
                        setState(() => confirmSensitive = v ?? false),
                    title: const Text(
                      'I confirm this does not include Aadhaar, PAN, or bank details',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () async {
                    final rootContext = sheetContext;
                    Navigator.pop(sheetContext);
                    try {
                      await shareService(ref).shareNative(
                        rootContext,
                        item,
                        visibility: visibility,
                        expiry: expiry,
                        confirmSensitive: item.requiresSensitiveConfirm
                            ? confirmSensitive
                            : true,
                      );
                    } catch (e) {
                      if (!rootContext.mounted) return;
                      final msg = e is ApiException
                          ? e.message
                          : 'Unable to generate share link. Please try again.';
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(content: Text(msg)),
                      );
                    }
                  },
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Create link & share'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
