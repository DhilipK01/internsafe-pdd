import 'package:flutter/material.dart';
import 'package:internsfe/core/brand/glass_surface.dart';
import 'package:internsfe/core/constants/app_spacing.dart';

/// Branded card — delegates to signature [GlassSurface].
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: padding,
      onTap: onTap,
      accentColor: borderColor,
      child: child,
    );
  }
}
