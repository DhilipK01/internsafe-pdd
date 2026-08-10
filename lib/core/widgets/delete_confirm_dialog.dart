import 'package:flutter/material.dart';
import 'package:internsfe/core/dialogs/confirmation_dialog_service.dart';

/// Backward-compatible delete confirmation — uses premium [ConfirmationDialogService].
Future<bool> showDeleteConfirmDialog(
  BuildContext context, {
  String title = 'Delete This Report?',
  String body =
      'This action cannot be undone.\n'
      'The selected report and associated analysis will be permanently removed from your account.',
}) async {
  return ConfirmationDialogService.show(
    context,
    request: ConfirmationRequest(
      title: title,
      message: body,
      severity: ConfirmationSeverity.destructive,
      confirmLabel: 'Delete Permanently',
    ),
  );
}
