import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class EnvConfig {
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  static String get apiBaseUrl {
    final url = dotenv.env['API_BASE_URL']?.trim();
    if (url == null || url.isEmpty) {
      throw StateError(
        'API_BASE_URL is not set. Copy .env.example to .env and configure your Cloudflare Worker URL.',
      );
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Host for share deep links (App Links). Defaults to API host.
  static String get shareLinkHost {
    final explicit = dotenv.env['SHARE_LINK_HOST']?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return Uri.parse(apiBaseUrl).host;
  }

  /// OAuth **Web application** client ID — required as `serverClientId` on Android.
  /// Do not use the Android-type OAuth client ID here.
  static String? get googleServerClientId {
    final web = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();
    if (web != null && web.isNotEmpty) return web;
    return dotenv.env['GOOGLE_CLIENT_ID']?.trim();
  }

  /// Same as [googleServerClientId] — used by Cloudflare Worker token verification.
  static String? get googleClientId => googleServerClientId;
}
