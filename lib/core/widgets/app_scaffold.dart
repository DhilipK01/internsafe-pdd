import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/layout/responsive_layout.dart';
import 'package:internsfe/core/layout/web_scaffold.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/widgets/bottom_nav_bar.dart';
import 'package:internsfe/core/widgets/custom_branded_appbar.dart';

/// Shell for authenticated app screens.
///
/// On **desktop web** (kIsWeb + width ≥ 1024): renders inside [WebScaffold]
/// (sidebar + top nav) — no bottom nav, no mobile app bar.
///
/// On **mobile / narrow web**: uses the original Scaffold with
/// [CustomBrandedAppBar] and optional [AppBottomNavBar] (unchanged).
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBackToHome = false,
    this.actions,
    this.showBottomNav = false,
    this.bottomNavIndex = 0,
    this.floatingActionButton,
    this.padding = true,
    this.showBrandHeader,
    this.showLogoInBrand = true,
    this.transparentAppBar = false,
  });

  final String title;
  final Widget body;
  final bool showBackToHome;
  final List<Widget>? actions;
  final bool showBottomNav;
  final int bottomNavIndex;
  final Widget? floatingActionButton;
  final bool padding;

  /// When null, brand shows on main tabs ([showBottomNav]); screen title otherwise.
  final bool? showBrandHeader;
  final bool showLogoInBrand;
  final bool transparentAppBar;

  bool get _useBrand => showBrandHeader ?? showBottomNav;

  // Derive the current route string from the bottom nav index for the sidebar.
  String get _currentRoute => switch (bottomNavIndex) {
        1 => AppRoutes.scan,
        2 => AppRoutes.verify,
        3 => AppRoutes.blacklist,
        4 => AppRoutes.profile,
        _ => AppRoutes.home,
      };

  @override
  Widget build(BuildContext context) {
    // ── Desktop Web Layout ──────────────────────────────────────────────────
    if (ResponsiveLayout.isDesktopWeb(context)) {
      final content = padding
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: body,
            )
          : body;

      return WebScaffold(
        currentRoute: _currentRoute,
        actions: actions,
        screenTitle: _useBrand ? null : title,
        child: content,
      );
    }

    // ── Mobile / Narrow Web Layout (unchanged) ──────────────────────────────
    final content = padding
        ? Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: body,
          )
        : body;

    final bottomPad = showBottomNav ? 88.0 : 0.0;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      extendBody: showBottomNav,
      appBar: CustomBrandedAppBar(
        showBrand: _useBrand,
        screenTitle: _useBrand ? null : title,
        showLogoInBrand: showLogoInBrand,
        showBackToHome: showBackToHome,
        actions: actions,
        transparent: transparentAppBar,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar:
          showBottomNav ? AppBottomNavBar(currentIndex: bottomNavIndex) : null,
      body: showBackToHome
          ? PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) context.go(AppRoutes.home);
              },
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPad),
                child: content,
              ),
            )
          : Padding(
              padding: EdgeInsets.only(bottom: bottomPad),
              child: content,
            ),
    );
  }
}
