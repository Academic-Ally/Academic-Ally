import 'dart:async';

import 'package:app_links/app_links.dart';

/// Parses incoming deep-link URIs into GoRouter-compatible route strings.
///
/// Accepted inputs:
///   - `academically://<path>?<query>`                  (custom scheme — cold start safe)
///   - `https://getacademically.co/<path>?<query>`      (Android App Links / iOS Universal Links)
///   - `https://app.getacademically.co/<path>?<query>`  (legacy RN domain)
///
/// All other schemes/hosts are rejected. The `<path>` must be one of the
/// explicitly allow-listed routes to prevent tricks like
/// `academically://admin/reset`.
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  /// Routes we allow deep-linking into. Anything else is silently dropped.
  static const Set<String> _allowedRoutes = {
    '/pdf-viewer',
    '/subject-resources',
    '/resources-list',
    '/allybot',
    '/allybot-chat',
    '/seekhub',
    '/recents',
    '/downloads',
    '/knowledge-map',
    '/study-planner',
    '/gen-ui',
    '/pyq-analyzer',
    '/snap-doubt',
    '/project-copilot',
  };

  /// Route embedded in the URI that launched the app from a cold start.
  /// Returns null if the app wasn't launched from a link, the link is
  /// malformed, or the target route isn't allow-listed.
  Future<String?> getInitialRoute() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri == null) return null;
      return parseRoute(uri);
    } catch (_) {
      return null;
    }
  }

  /// Stream of routes from links that arrive while the app is already running.
  Stream<String> get routeStream => _appLinks.uriLinkStream
      .map(parseRoute)
      .where((route) => route != null)
      .cast<String>();

  /// Normalize a URI into a GoRouter path with preserved query parameters,
  /// or return null if the URI doesn't belong to Academic Ally.
  static String? parseRoute(Uri uri) {
    String path;

    if (uri.scheme == 'academically') {
      // Custom-scheme quirk: `academically://pdf-viewer?...` puts the route
      // name in `uri.host`, not `uri.path`.
      path = '/${uri.host}';
    } else if (uri.scheme == 'https' &&
        (uri.host == 'getacademically.co' ||
            uri.host == 'app.getacademically.co')) {
      path = uri.path.isEmpty ? '/' : uri.path;
    } else {
      return null;
    }

    if (!_allowedRoutes.contains(path)) return null;

    final query = uri.query.isEmpty ? '' : '?${uri.query}';
    return '$path$query';
  }

  /// Build a shareable HTTPS URL for a route. Used by the share-sheet in the
  /// PDF viewer and anywhere else we surface "copy link" affordances.
  static String buildShareUrl({
    required String route,
    required Map<String, String> queryParameters,
  }) {
    final path = route.startsWith('/') ? route : '/$route';
    final uri = Uri(
      scheme: 'https',
      host: 'getacademically.co',
      path: path,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return uri.toString();
  }
}
