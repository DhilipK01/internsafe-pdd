import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/theme_provider.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/brand/internsafe_brand_title.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/layout/responsive_layout.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/theme/app_typography.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ---------------------------------------------------------------------------
// Nav item definition
// ---------------------------------------------------------------------------
class _WebNavItem {
  const _WebNavItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
}

const _navItems = [
  _WebNavItem(icon: LucideIcons.home, label: 'Home', route: AppRoutes.home),
  _WebNavItem(
      icon: LucideIcons.scanLine, label: 'Scan Resume', route: AppRoutes.scan),
  _WebNavItem(
      icon: LucideIcons.badgeCheck,
      label: 'Verify Company',
      route: AppRoutes.verify),
  _WebNavItem(
      icon: LucideIcons.ban, label: 'Blacklist', route: AppRoutes.blacklist),
  _WebNavItem(
      icon: LucideIcons.history, label: 'History', route: AppRoutes.history),
  _WebNavItem(
      icon: LucideIcons.user, label: 'Profile', route: AppRoutes.profile),
];

// ---------------------------------------------------------------------------
// WebScaffold
// ---------------------------------------------------------------------------

/// Desktop web shell — left sidebar + glass top header + scrollable content.
/// Rendered only when [ResponsiveLayout.isDesktopWeb] is true.
class WebScaffold extends ConsumerWidget {
  const WebScaffold({
    super.key,
    required this.child,
    required this.currentRoute,
    this.actions,
    this.screenTitle,
    this.contentMaxWidth = ResponsiveLayout.contentMaxWidth,
  });

  final Widget child;
  final String currentRoute;
  final List<Widget>? actions;
  final String? screenTitle;
  final double contentMaxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;

    final sidebarBg = isDark
        ? AppPalette.navyDeep.withValues(alpha: 0.97)
        : Colors.white.withValues(alpha: 0.97);

    final mainBg = isDark ? AppPalette.navyVoid : AppPalette.frost;

    return Scaffold(
      backgroundColor: mainBg,
      body: Column(
        children: [
          // ── Top Header Bar ────────────────────────────────────────────────
          _WebTopBar(
            screenTitle: screenTitle,
            actions: actions,
          ),
          // ── Body Row ──────────────────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar
                SizedBox(
                  width: ResponsiveLayout.sidebarWidth,
                  child: _WebSidebar(
                    currentRoute: currentRoute,
                    bg: sidebarBg,
                    isDark: isDark,
                  ),
                ),
                // Vertical divider
                Container(
                  width: 1,
                  color: isDark
                      ? AppPalette.slateBorder.withValues(alpha: 0.45)
                      : AppPalette.mist.withValues(alpha: 0.9),
                ),
                // Main content
                Expanded(
                  child: _WebContentArea(
                    maxWidth: contentMaxWidth,
                    isDark: isDark,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top Header Bar
// ---------------------------------------------------------------------------
class _WebTopBar extends ConsumerWidget {
  const _WebTopBar({this.screenTitle, this.actions});

  final String? screenTitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final themeMode = ref.watch(themeModeProvider);
    final barFill = isDark
        ? AppPalette.navyDeep.withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.96);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: barFill,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AppPalette.slateBorder.withValues(alpha: 0.5)
                    : AppPalette.mist.withValues(alpha: 0.9),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                // Brand
                const InternsafeBrandTitle(
                  logoSize: 28,
                  compact: true,
                ),
                const Spacer(),
                // Screen title (optional center piece)
                if (screenTitle != null) ...[
                  Text(
                    screenTitle!,
                    style: AppTypography.titleMedium(dark: isDark).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                ],
                // Extra actions
                if (actions != null) ...actions!,
                const SizedBox(width: AppSpacing.sm),
                // Theme toggle
                _ThemeToggleButton(isDark: isDark, themeMode: themeMode),
                const SizedBox(width: AppSpacing.sm),
                // Profile avatar shortcut
                _ProfileAvatarButton(isDark: isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends ConsumerWidget {
  const _ThemeToggleButton({required this.isDark, required this.themeMode});
  final bool isDark;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      child: InkWell(
        onTap: () {
          final next = isDark ? ThemeMode.light : ThemeMode.dark;
          ref.read(themeModeProvider.notifier).setTheme(next);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? AppPalette.navyElevated.withValues(alpha: 0.8)
                : AppPalette.frost,
            border: Border.all(
              color: isDark ? AppPalette.slateBorder : AppPalette.mist,
            ),
          ),
          child: Icon(
            isDark ? LucideIcons.sun : LucideIcons.moon,
            size: 16,
            color: isDark
                ? AppPalette.neonMint
                : AppPalette.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Profile',
      child: InkWell(
        onTap: () => context.go(AppRoutes.profile),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppPalette.buttonPrimary,
            border: Border.all(
              color: AppPalette.neonMint.withValues(alpha: 0.3),
            ),
          ),
          child: const Icon(
            LucideIcons.user,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar
// ---------------------------------------------------------------------------
class _WebSidebar extends StatelessWidget {
  const _WebSidebar({
    required this.currentRoute,
    required this.bg,
    required this.isDark,
  });

  final String currentRoute;
  final Color bg;
  final bool isDark;

  bool _isActive(String route) {
    if (route == AppRoutes.home) return currentRoute == AppRoutes.home;
    return currentRoute.startsWith(route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          // Navigation section label
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              'NAVIGATION',
              style: AppTypography.overline(
                dark: isDark,
                color: isDark
                    ? AppPalette.textSecondaryDark.withValues(alpha: 0.6)
                    : AppPalette.textSecondaryLight.withValues(alpha: 0.6),
              ),
            ),
          ),
          // Nav items
          ...List.generate(_navItems.length, (i) {
            final item = _navItems[i];
            final active = _isActive(item.route);
            return _SidebarItem(
              icon: item.icon,
              label: item.label,
              route: item.route,
              active: active,
              isDark: isDark,
            );
          }),
          const Spacer(),
          // Footer separator
          Divider(
            color: isDark
                ? AppPalette.slateBorder.withValues(alpha: 0.4)
                : AppPalette.mist,
            height: 1,
          ),
          // Version/branding footer
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: AppPalette.buttonPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.shieldCheck,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Internsafe AI',
                        style: AppTypography.labelSmall(dark: isDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Internship Protection',
                        style: AppTypography.caption(
                          dark: isDark,
                          color: isDark
                              ? AppPalette.textSecondaryDark.withValues(
                                  alpha: 0.6)
                              : AppPalette.textSecondaryLight.withValues(
                                  alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.active,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool active;
  final bool isDark;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final selectedColor =
        widget.isDark ? AppPalette.neonMint : AppPalette.emeraldCore;
    final unselectedColor = widget.isDark
        ? AppPalette.textSecondaryDark
        : AppPalette.textSecondaryLight;

    final bgColor = widget.active
        ? AppPalette.emeraldCore.withValues(
            alpha: widget.isDark ? 0.18 : 0.1,
          )
        : _hovering
            ? (widget.isDark
                ? AppPalette.navyElevated.withValues(alpha: 0.6)
                : AppPalette.frost.withValues(alpha: 0.9))
            : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: () => context.go(widget.route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: widget.active
                  ? Border.all(
                      color: selectedColor.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.active ? selectedColor : unselectedColor,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    widget.label,
                    style: AppTypography.labelMedium(
                      dark: widget.isDark,
                      color: widget.active ? selectedColor : unselectedColor,
                    ).copyWith(
                      fontWeight: widget.active
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.active)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selectedColor,
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

// ---------------------------------------------------------------------------
// Content area
// ---------------------------------------------------------------------------
class _WebContentArea extends StatelessWidget {
  const _WebContentArea({
    required this.child,
    required this.maxWidth,
    required this.isDark,
  });

  final Widget child;
  final double maxWidth;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppPalette.navyVoid : AppPalette.frost,
      child: child,
    );
  }
}
