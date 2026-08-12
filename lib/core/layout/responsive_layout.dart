import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Breakpoint thresholds for responsive layout decisions.
abstract final class Breakpoints {
  static const double mobileMax = 767;
  static const double tabletMin = 768;
  static const double desktopMin = 1024;
  static const double wideDesktopMin = 1280;
}

/// Responsive layout helper for InternSafe.
///
/// - [isDesktopWeb]: true only on `kIsWeb` at ≥ 1024 px width — shows full
///   sidebar + top-nav shell.
/// - [isMobileApp]: true on non-web or narrow viewports — keeps existing
///   bottom-nav mobile layout unchanged.
abstract final class ResponsiveLayout {
  /// Returns `true` when running in a web browser with a wide viewport (≥ 1024 px).
  /// This is the only condition under which the desktop web shell is rendered.
  static bool isDesktopWeb(BuildContext context) {
    if (!kIsWeb) return false;
    return MediaQuery.sizeOf(context).width >= Breakpoints.desktopMin;
  }

  /// Complement of [isDesktopWeb] — covers mobile app + narrow web viewports.
  static bool isMobileApp(BuildContext context) => !isDesktopWeb(context);

  /// Width of the sidebar navigation on desktop web.
  static const double sidebarWidth = 220;

  /// Maximum width for the main content area on desktop web.
  static const double contentMaxWidth = 1200;

  /// Width of a centred card/form column (login, result screens).
  static const double formMaxWidth = 560;

  /// Width of a medium content panel (result screens, reports).
  static const double panelMaxWidth = 800;
}
