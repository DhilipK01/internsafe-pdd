import 'package:internsfe/core/deeplink/deep_link_handler.dart';

/// @deprecated Prefer [DeepLinkHandler].
abstract final class ShareLinkParser {
  static String? tokenFromUri(Uri uri) => DeepLinkHandler.extractShareToken(uri);

  static bool isShareUri(Uri uri) => DeepLinkHandler.isDeepLink(uri);
}
