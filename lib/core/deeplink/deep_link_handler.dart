import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/core/config/env_config.dart';
import 'package:internsfe/core/routing/app_routes.dart';

/// Normalizes HTTPS + `internsafe://` URIs into GoRouter paths (`/share/:token`, etc.).
abstract final class DeepLinkHandler {
  static const _shareHosts = {'s', 'share', 'view', 'report'};
  static const _resourceHosts = {'resume', 'offer', 'company'};

  /// Resolves a platform URI to an in-app path, or null if not a deep link.
  static String? toAppPath(Uri uri) {
    try {
      if (uri.scheme == 'internsafe') {
        return _fromCustomScheme(uri);
      }
      if (uri.scheme == 'https' || uri.scheme == 'http') {
        if (!_isAllowedHost(uri.host)) return null;
        return _fromHttpsPath(uri);
      }
    } catch (e, st) {
      debugPrint('DeepLinkHandler.toAppPath: $e\n$st');
    }
    return null;
  }

  /// Parses raw location strings (e.g. `internsafe://share/abc`) when [Uri] is incomplete.
  static String? fromLocationString(String location) {
    final trimmed = location.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('/')) return trimmed.split('?').first;
    if (!trimmed.contains('://')) return null;
    return toAppPath(Uri.parse(trimmed));
  }

  /// GoRouter [redirect] — rewrites custom-scheme locations before route matching.
  static String? redirectForState(GoRouterState state) {
    final matched = state.matchedLocation;
    if (matched.contains('://')) {
      final path = fromLocationString(matched);
      if (path != null && path != matched) return path;
    }

    if (state.uri.scheme == 'internsafe') {
      final path = toAppPath(state.uri);
      if (path != null && path != matched) return path;
    }

    final full = state.uri.toString();
    if (full.contains('internsafe://')) {
      final path = fromLocationString(full);
      if (path != null && path != matched) return path;
    }

    return null;
  }

  static String? extractShareToken(Uri uri) {
    final path = toAppPath(uri);
    if (path == null) return null;
    if (path.startsWith('/share/')) {
      return path.substring('/share/'.length).split('/').first;
    }
    if (path.startsWith('/s/')) {
      return path.substring('/s/'.length).split('/').first;
    }
    if (path.startsWith('/view/')) {
      return path.substring('/view/'.length).split('/').first;
    }
    if (path.startsWith('/report/')) {
      return path.substring('/report/'.length).split('/').first;
    }
    return null;
  }

  static bool isDeepLink(Uri uri) => toAppPath(uri) != null;

  static String? _fromCustomScheme(Uri uri) {
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final tail = segments.isNotEmpty
        ? segments.first
        : uri.path.replaceFirst('/', '').split('/').where((s) => s.isNotEmpty).firstOrNull ?? '';

    if (_shareHosts.contains(host) && tail.isNotEmpty) {
      return AppRoutes.sharedContent(tail);
    }

    if (_resourceHosts.contains(host) && tail.isNotEmpty) {
      return '/$host/$tail';
    }

    if (host.isEmpty && segments.length >= 2 && _shareHosts.contains(segments[0])) {
      return AppRoutes.sharedContent(segments[1]);
    }

    return null;
  }

  static String? _fromHttpsPath(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;

    final kind = segments[0].toLowerCase();
    final id = segments[1];

    if (_shareHosts.contains(kind)) {
      return AppRoutes.sharedContent(id);
    }
    if (_resourceHosts.contains(kind)) {
      return '/$kind/$id';
    }
    return null;
  }

  static bool _isAllowedHost(String host) {
    final h = host.toLowerCase();
    if (h == EnvConfig.shareLinkHost.toLowerCase()) return true;
    if (h == 'internsafe.app' || h == 'www.internsafe.app') return true;
    if (h == 'internsafe.pages.dev' || h.endsWith('.pages.dev')) return true;
    return false;
  }
}
