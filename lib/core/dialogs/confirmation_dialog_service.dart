import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:internsfe/core/brand/app_elevation.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/brand/app_typography.dart';
import 'package:internsfe/core/constants/app_colors.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Visual weight for confirmation actions.
enum ConfirmationSeverity {
  neutral,
  warning,
  destructive,
}

class ConfirmationRequest {
  const ConfirmationRequest({
    required this.title,
    required this.message,
    this.severity = ConfirmationSeverity.destructive,
    this.icon = LucideIcons.alertTriangle,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.confirmHaptic = true,
  });

  final String title;
  final String message;
  final ConfirmationSeverity severity;
  final IconData icon;
  final String confirmLabel;
  final String cancelLabel;
  final bool confirmHaptic;
}

/// Preset copy for common destructive flows.
abstract final class ConfirmationPresets {
  static const signOut = ConfirmationRequest(
    title: 'Sign Out?',
    message:
        'You will need to log in again to access your INTERNSAFE AI account.',
    severity: ConfirmationSeverity.warning,
    icon: LucideIcons.logOut,
    confirmLabel: 'Sign Out',
  );

  static ConfirmationRequest deleteReport({String? itemLabel}) =>
      ConfirmationRequest(
        title: 'Delete This Report?',
        message:
            'This action cannot be undone.\n'
            'The selected ${itemLabel ?? 'report'} and associated analysis will be permanently removed from your account.',
        severity: ConfirmationSeverity.destructive,
        icon: LucideIcons.trash2,
        confirmLabel: 'Delete Permanently',
      );

  static ConfirmationRequest deleteUpload({String? fileName}) =>
      ConfirmationRequest(
        title: 'Delete This Upload?',
        message:
            'This action cannot be undone.\n'
            '${fileName != null ? '"$fileName" ' : ''}will be permanently removed from your account.',
        severity: ConfirmationSeverity.destructive,
        icon: LucideIcons.trash2,
        confirmLabel: 'Delete Permanently',
      );

  static const reanalyze = ConfirmationRequest(
    title: 'Reanalyze This Report?',
    message:
        'A new analysis run may replace or supplement existing results. '
        'You can upload or scan again from the next screen.',
    severity: ConfirmationSeverity.warning,
    icon: LucideIcons.refreshCw,
    confirmLabel: 'Continue',
  );

  static const revokeShare = ConfirmationRequest(
    title: 'Revoke Shared Link?',
    message:
        'Anyone with this link will no longer be able to view the shared analysis. '
        'This cannot be undone.',
    severity: ConfirmationSeverity.warning,
    icon: LucideIcons.link2Off,
    confirmLabel: 'Revoke Link',
  );

  static const disablePublicSharing = ConfirmationRequest(
    title: 'Disable Public Sharing?',
    message:
        'The public link will stop working immediately. '
        'You can create a new share link later if needed.',
    severity: ConfirmationSeverity.warning,
    icon: LucideIcons.eyeOff,
    confirmLabel: 'Disable Sharing',
  );
}

/// Global confirmation, loading, and feedback for destructive / irreversible actions.
class ConfirmationDialogService {
  ConfirmationDialogService._();

  static bool _actionInFlight = false;

  static Future<bool> show(
    BuildContext context, {
    required ConfirmationRequest request,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: request.title,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return _PremiumConfirmDialog(
          request: request,
          animation: animation,
        );
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
    return result == true;
  }

  static Future<bool> confirmSignOut(BuildContext context) =>
      show(context, request: ConfirmationPresets.signOut);

  static Future<bool> confirmDeleteReport(
    BuildContext context, {
    String? itemLabel,
  }) =>
      show(context, request: ConfirmationPresets.deleteReport(itemLabel: itemLabel));

  static Future<bool> confirmDeleteUpload(
    BuildContext context, {
    String? fileName,
  }) =>
      show(context, request: ConfirmationPresets.deleteUpload(fileName: fileName));

  static Future<bool> confirmReanalyze(BuildContext context) =>
      show(context, request: ConfirmationPresets.reanalyze);

  static Future<bool> confirmRevokeShare(BuildContext context) =>
      show(context, request: ConfirmationPresets.revokeShare);

  /// Two-step delete account: warning → type DELETE.
  static Future<bool> confirmDeleteAccount(BuildContext context) async {
    final step1 = await show(
      context,
      request: const ConfirmationRequest(
        title: 'Delete Account?',
        message:
            'This will permanently remove:\n'
            '• your account\n'
            '• uploads\n'
            '• reports\n'
            '• AI analyses\n'
            '• shared links\n'
            '• saved history\n\n'
            'This action cannot be reversed.',
        severity: ConfirmationSeverity.destructive,
        icon: LucideIcons.userX,
        confirmLabel: 'Continue',
      ),
    );
    if (!step1 || !context.mounted) return false;
    return showDeleteAccountTyping(context);
  }

  static Future<bool> showDeleteAccountTyping(BuildContext context) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Confirm account deletion',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, animation, _) => _DeleteAccountTypingDialog(
        animation: animation,
      ),
      transitionBuilder: (ctx, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
    return result == true;
  }

  /// Runs [action] only after confirmation; shows loading + success/error feedback.
  static Future<bool> confirmAndRun({
    required BuildContext context,
    required ConfirmationRequest request,
    required Future<void> Function() action,
    String? loadingMessage,
    String? successMessage,
    String errorMessage = 'Unable to complete action. Please try again.',
  }) async {
    if (_actionInFlight) return false;

    final confirmed = await show(context, request: request);
    if (!confirmed || !context.mounted) return false;

    _actionInFlight = true;
    try {
      await showBlockingProgress(
        context,
        message: loadingMessage ?? 'Please wait…',
        action: action,
      );
      if (context.mounted && successMessage != null) {
        showSuccessSnackBar(context, successMessage);
        HapticFeedback.mediumImpact();
      }
      return true;
    } catch (_) {
      if (context.mounted) {
        showErrorSnackBar(context, errorMessage);
        HapticFeedback.heavyImpact();
      }
      return false;
    } finally {
      _actionInFlight = false;
    }
  }

  static Future<T> showBlockingProgress<T>(
    BuildContext context, {
    required String message,
    required Future<T> Function() action,
  }) async {
    if (!context.mounted) return action();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => PopScope(
        canPop: false,
        child: _BlockingProgressDialog(message: message),
      ),
    );
    try {
      return await action();
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppPalette.emeraldDeep,
        content: Row(
          children: [
            const Icon(LucideIcons.checkCircle2, color: AppPalette.trust, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message, style: AppTypography.bodySmall(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppPalette.crimsonDeep,
        content: Row(
          children: [
            const Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message, style: AppTypography.bodySmall(color: Colors.white))),
          ],
        ),
      ),
    );
  }
}

class _PremiumConfirmDialog extends StatefulWidget {
  const _PremiumConfirmDialog({
    required this.request,
    required this.animation,
  });

  final ConfirmationRequest request;
  final Animation<double> animation;

  @override
  State<_PremiumConfirmDialog> createState() => _PremiumConfirmDialogState();
}

class _PremiumConfirmDialogState extends State<_PremiumConfirmDialog> {
  bool _confirming = false;

  Color _accentFor(ConfirmationSeverity s, bool isDark) {
    switch (s) {
      case ConfirmationSeverity.destructive:
        return AppColors.dangerRed;
      case ConfirmationSeverity.warning:
        return AppColors.warningAmber;
      case ConfirmationSeverity.neutral:
        return isDark ? AppPalette.neonMint : AppPalette.emeraldCore;
    }
  }

  Future<void> _onConfirm() async {
    if (_confirming) return;
    setState(() => _confirming = true);
    if (widget.request.confirmHaptic) {
      HapticFeedback.mediumImpact();
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accentFor(widget.request.severity, isDark);
    final req = widget.request;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.heroRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.heroRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              AppPalette.navyElevated.withValues(alpha: 0.97),
                              AppPalette.navySurface.withValues(alpha: 0.92),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.98),
                              AppPalette.frost.withValues(alpha: 0.95),
                            ],
                    ),
                    border: AppElevation.signatureBorder(isDark, accent: accent),
                    boxShadow: AppElevation.card(isDark),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.15 : 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(req.icon, color: accent, size: 28),
                      )
                          .animate()
                          .fadeIn(duration: 220.ms)
                          .scale(begin: const Offset(0.85, 0.85)),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        req.title,
                        textAlign: TextAlign.center,
                        style: AppTypography.titleLarge(dark: isDark),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        req.message,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium(
                          color: context.mutedColor,
                          dark: isDark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _confirming ? null : _onConfirm,
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.buttonRadius),
                            ),
                          ),
                          child: _confirming
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(req.confirmLabel),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _confirming
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: Text(
                            req.cancelLabel,
                            style: AppTypography.label(
                              color: context.mutedColor,
                              dark: isDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountTypingDialog extends StatefulWidget {
  const _DeleteAccountTypingDialog({required this.animation});

  final Animation<double> animation;

  @override
  State<_DeleteAccountTypingDialog> createState() =>
      _DeleteAccountTypingDialogState();
}

class _DeleteAccountTypingDialogState extends State<_DeleteAccountTypingDialog> {
  final _controller = TextEditingController();
  bool _busy = false;

  bool get _matches => _controller.text.trim() == 'DELETE';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = AppColors.dangerRed;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.heroRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.heroRadius),
                    color: isDark
                        ? AppPalette.navyElevated.withValues(alpha: 0.97)
                        : Colors.white.withValues(alpha: 0.98),
                    border: AppElevation.signatureBorder(isDark, accent: accent),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Type DELETE to confirm',
                        style: AppTypography.titleMedium(dark: isDark),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'This permanently deletes your account and all associated data.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall(
                          color: context.mutedColor,
                          dark: isDark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: _controller,
                        enabled: !_busy,
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        decoration: InputDecoration(
                          hintText: 'DELETE',
                          labelText: 'Confirmation',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.buttonRadius),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: !_matches || _busy
                              ? null
                              : () {
                                  HapticFeedback.heavyImpact();
                                  setState(() => _busy = true);
                                  Navigator.of(context).pop(true);
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Delete Account Forever'),
                        ),
                      ),
                      TextButton(
                        onPressed: _busy ? null : () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockingProgressDialog extends StatelessWidget {
  const _BlockingProgressDialog({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.xl),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppPalette.navyElevated.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: AppElevation.signatureBorder(isDark),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: AppSpacing.lg),
                Flexible(
                  child: Text(
                    message,
                    style: AppTypography.bodyMedium(dark: isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
