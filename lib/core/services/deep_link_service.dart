import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/core/deeplink/deep_link_handler.dart';

/// Listens for App Link / custom scheme URIs and navigates via [DeepLinkHandler].
class DeepLinkService {
  DeepLinkService(this._appLinks);

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;

  Future<void> bind(GoRouter router) async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _navigate(router, initial);
      }
    } catch (e, st) {
      debugPrint('DeepLinkService initial: $e\n$st');
    }

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => _navigate(router, uri),
      onError: (Object e, st) => debugPrint('Deep link stream error: $e\n$st'),
    );
  }

  void _navigate(GoRouter router, Uri uri) {
    final path = DeepLinkHandler.toAppPath(uri);
    if (path == null || path.isEmpty) {
      // Avoid printing noisy console logs on the web for standard route navigation URLs
      if (!kIsWeb) {
        debugPrint('DeepLinkService: unhandled URI $uri');
      }
      return;
    }
    debugPrint('DeepLinkService → $path');
    router.go(path);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService(AppLinks());
  ref.onDispose(service.dispose);
  return service;
});
