import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:internsfe/core/brand/app_elevation.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/brand/app_typography.dart';
import 'package:internsfe/core/constants/app_spacing.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && onPressed != null;

    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        child: Ink(
          decoration: BoxDecoration(
            gradient: enabled
                ? AppPalette.buttonPrimary
                : LinearGradient(
                    colors: [
                      AppPalette.graphite,
                      AppPalette.graphite.withValues(alpha: 0.8),
                    ],
                  ),
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            border: Border.all(
              color: AppPalette.neonMint.withValues(alpha: enabled ? 0.35 : 0.1),
            ),
            boxShadow: enabled
                ? AppElevation.glowAccent(AppPalette.emeraldBright, intensity: 0.28)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: 15,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppPalette.textPrimaryDark,
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, color: AppPalette.textPrimaryDark, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    label,
                    style: AppTypography.label(color: AppPalette.textPrimaryDark),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return expand
        ? SizedBox(width: double.infinity, child: child)
            .animate()
            .fadeIn(duration: 200.ms)
        : child;
  }
}
