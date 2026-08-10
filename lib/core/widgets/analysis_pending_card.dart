import 'package:flutter/material.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/brand/app_typography.dart';
import 'package:internsfe/core/brand/glass_surface.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AnalysisPendingCard extends StatelessWidget {
  const AnalysisPendingCard({
    super.key,
    required this.message,
    this.title = 'Analysis Pending',
  });

  final String message;
  final String title;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      accentColor: AppPalette.amber,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(LucideIcons.brainCircuit, color: AppPalette.amber, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.headline(dark: context.isDark)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.body(dark: context.isDark),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
