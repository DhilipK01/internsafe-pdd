import 'package:flutter/material.dart';
import 'package:internsfe/core/brand/app_typography.dart';
import 'package:internsfe/core/brand/internsafe_logo.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/widgets/primary_button.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.showBrandLogo = true,
    this.icon = LucideIcons.inbox,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showBrandLogo;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showBrandLogo)
              const InternsafeLogo(size: 56, showGlow: true)
            else
              Icon(icon, size: 56, color: context.mutedColor),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTypography.headline(dark: context.isDark)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.body(dark: context.isDark),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// Official brand mark — same as [InternsafeLogo].
typedef BrandLogo = InternsafeLogo;
