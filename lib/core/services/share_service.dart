import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/core/dialogs/confirmation_dialog_service.dart';
import 'package:internsfe/core/share/shareable_item.dart';
import 'package:internsfe/data/api/api_exception.dart';
import 'package:internsfe/domain/repositories/share_repository.dart';
import 'package:share_plus/share_plus.dart';

/// Creates share links, copies to clipboard, and opens the native share sheet.
class ShareService {
  ShareService(this._ref);

  final WidgetRef _ref;

  Future<ShareLinkResult> createLink(
    ShareableItem item, {
    ShareVisibility visibility = ShareVisibility.public,
    ShareExpiryOption expiry = ShareExpiryOption.days14,
    bool confirmSensitive = true,
  }) async {
    if (item.shareType == null) {
      throw ApiException('This item cannot be shared.');
    }
    if (item.resourceId == null || item.resourceId!.isEmpty) {
      if (item.shareType != ShareResourceType.companyVerify &&
          item.shareType != ShareResourceType.blacklist) {
        throw ApiException(
          'Missing content reference. Run a new scan or open the full result first.',
        );
      }
    }

    developer.log(
      'Share create: ${item.shareType!.apiValue} id=${item.resourceId}',
      name: 'ShareService',
    );

    final link = await _ref.read(shareRepositoryProvider).createShare(
          resourceType: item.shareType!,
          resourceId: item.resourceId,
          companyName: item.companyName,
          query: item.query,
          visibility: visibility,
          expiry: expiry,
          confirmSensitive: confirmSensitive,
        );

    if (link.url.isEmpty || link.token.isEmpty) {
      throw ApiException('Server did not return a valid share URL.');
    }

    developer.log('Share URL: ${link.url}', name: 'ShareService');
    return link;
  }

  Future<ShareLinkResult> copyLink(
    BuildContext context,
    ShareableItem item, {
    ShareVisibility visibility = ShareVisibility.public,
    ShareExpiryOption expiry = ShareExpiryOption.days14,
  }) async {
    final link = await _withLoading(
      context,
      'Generating secure link…',
      () => createLink(
        item,
        visibility: visibility,
        expiry: expiry,
        confirmSensitive: true,
      ),
    );

    await Clipboard.setData(ClipboardData(text: link.url));
    if (context.mounted) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied successfully')),
      );
    }
    return link;
  }

  Future<void> shareNative(
    BuildContext context,
    ShareableItem item, {
    required ShareVisibility visibility,
    required ShareExpiryOption expiry,
    required bool confirmSensitive,
  }) async {
    if (item.requiresSensitiveConfirm && !confirmSensitive) {
      throw ApiException(
        'Please confirm this item does not include Aadhaar, PAN, or bank details.',
      );
    }

    final link = await _withLoading(
      context,
      'Generating secure link…',
      () => createLink(
        item,
        visibility: visibility,
        expiry: expiry,
        confirmSensitive: confirmSensitive,
      ),
    );

    final text =
        'Check this INTERNSAFE analysis:\n${link.url}\n\nOpen directly in the INTERNSAFE app.';
    await Share.share(text, subject: 'INTERNSAFE share');
  }

  Future<T> _withLoading<T>(
    BuildContext context,
    String message,
    Future<T> Function() action,
  ) async {
    if (!context.mounted) return action();
    return ConfirmationDialogService.showBlockingProgress(
      context,
      message: message,
      action: action,
    );
  }

  Future<bool> revokeShareLink(
    BuildContext context,
    String token,
  ) =>
      ConfirmationDialogService.confirmAndRun(
        context: context,
        request: ConfirmationPresets.revokeShare,
        loadingMessage: 'Revoking link…',
        successMessage: 'Shared link revoked.',
        action: () => _ref.read(shareRepositoryProvider).revokeShare(token),
      );
}

ShareService shareService(WidgetRef ref) => ShareService(ref);
