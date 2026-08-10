import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/widgets/bottom_nav_bar.dart';
import 'package:internsfe/core/widgets/custom_branded_appbar.dart';

/// Shell for authenticated app screens with premium header and optional bottom nav.
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

  @override
  Widget build(BuildContext context) {
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
