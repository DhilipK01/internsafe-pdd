import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/brand/internsafe_brand_title.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/theme/app_typography.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Premium centered header — brand or screen title stays visually centered
/// when leading/actions are present.
class CustomBrandedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomBrandedAppBar({
    super.key,
    this.screenTitle,
    this.showBrand = true,
    this.showLogoInBrand = true,
    this.showBackToHome = false,
    this.leading,
    this.actions,
    this.transparent = false,
  });

  static const double toolbarHeight = 56;
  static const double _sideSlotWidth = 112;

  /// When set, shows this title centered (e.g. report screens).
  final String? screenTitle;

  /// When true, center shows [InternsafeBrandTitle] ("Internsafe AI").
  final bool showBrand;

  final bool showLogoInBrand;
  final bool showBackToHome;
  final Widget? leading;
  final List<Widget>? actions;
  final bool transparent;

  @override
  Size get preferredSize => const Size.fromHeight(toolbarHeight);

  void _onBackToHome(BuildContext context) {
    HapticFeedback.lightImpact();
    context.go(AppRoutes.home);
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;
    if (showBackToHome) {
      return IconButton(
        icon: Icon(
          LucideIcons.arrowLeft,
          size: 22,
          color: context.isDark
              ? AppPalette.textPrimaryDark
              : AppPalette.ink,
        ),
        tooltip: 'Back to Home',
        onPressed: () => _onBackToHome(context),
      );
    }
    return null;
  }

  Widget _buildCenter(BuildContext context) {
    if (showBrand && screenTitle == null) {
      return InternsafeBrandTitle(
        logoSize: showLogoInBrand ? 26 : 0,
        showLogo: showLogoInBrand,
        compact: true,
      );
    }
    final title = screenTitle ?? 'Internsafe AI';
    return Text(
      title,
      style: AppTypography.titleMedium(dark: context.isDark).copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final leadingWidget = _buildLeading(context);
    final actionWidgets = actions ?? [];
    final barFill = transparent
        ? Colors.transparent
        : (isDark
            ? AppPalette.navyDeep.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.94));

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: transparent ? 0 : 14,
          sigmaY: transparent ? 0 : 14,
        ),
        child: Material(
          color: barFill,
          elevation: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppPalette.slateBorder.withValues(alpha: 0.45)
                      : AppPalette.mist.withValues(alpha: 0.9),
                ),
              ),
              boxShadow: transparent
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.18 : 0.04,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: toolbarHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: _sideSlotWidth,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: leadingWidget ?? const SizedBox(width: 8),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: _sideSlotWidth,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: actionWidgets.isNotEmpty
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: actionWidgets,
                              )
                            : const SizedBox(width: 8),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildCenter(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
