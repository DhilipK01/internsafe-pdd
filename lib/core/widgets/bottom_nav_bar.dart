import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/theme/app_typography.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  static const _items = [
    (icon: LucideIcons.home, label: 'Home', route: AppRoutes.home),
    (icon: LucideIcons.scanLine, label: 'Scan', route: AppRoutes.scan),
    (icon: LucideIcons.badgeCheck, label: 'Verify', route: AppRoutes.verify),
    (icon: LucideIcons.ban, label: 'Blacklist', route: AppRoutes.blacklist),
    (icon: LucideIcons.user, label: 'Profile', route: AppRoutes.profile),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final glassFill = isDark
        ? AppPalette.navyElevated.withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.88);
    final borderColor = isDark
        ? AppPalette.neonMint.withValues(alpha: 0.14)
        : AppPalette.mist;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: glassFill,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.emeraldCore.withValues(
                    alpha: isDark ? 0.12 : 0.08,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: List.generate(_items.length, (i) {
                    final item = _items[i];
                    return Expanded(
                      child: _NavItem(
                        icon: item.icon,
                        label: item.label,
                        selected: i == currentIndex,
                        onTap: () {
                          if (i != currentIndex) {
                            HapticFeedback.selectionClick();
                            context.go(item.route);
                          }
                        },
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final selectedColor =
        isDark ? AppPalette.neonMint : AppPalette.emeraldCore;
    final unselectedColor = isDark
        ? AppPalette.textSecondaryDark.withValues(alpha: 0.75)
        : AppPalette.textSecondaryLight.withValues(alpha: 0.85);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? AppPalette.emeraldCore.withValues(alpha: isDark ? 0.28 : 0.14)
                : Colors.transparent,
            border: selected
                ? Border.all(
                    color: selectedColor.withValues(alpha: 0.35),
                  )
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppPalette.emeraldBright.withValues(
                        alpha: isDark ? 0.22 : 0.16,
                      ),
                      blurRadius: 14,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: selected ? 1.12 : 1.0),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Icon(
                  icon,
                  size: selected ? 24 : 22,
                  color: selected ? selectedColor : unselectedColor,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: AppTypography.labelSmall(
                  dark: isDark,
                  color: selected ? selectedColor : unselectedColor,
                ).copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: selected ? 11.5 : 10.5,
                ),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
