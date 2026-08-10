/// Single source of truth for INTERNSAFE AI brand imagery.
///
/// Every screen, widget, and launcher config must reference [logo] only —
/// never hardcode asset paths elsewhere.
abstract final class BrandAssets {
  /// Official transparent INTERNSAFE AI logo (PNG).
  static const String logo = 'assets/branding/internsafe_ai_logo.png';

  /// Public URL path segment served by the API worker (`/brand/...`).
  static const String webLogoPath = '/brand/internsafe_ai_logo.png';

  static String webLogoUrl(String host) => 'https://$host$webLogoPath';
}
