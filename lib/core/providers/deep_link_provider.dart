import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../routing/app_router.dart';
import '../services/deep_link_service.dart';

final deepLinkServiceProvider =
    Provider<DeepLinkService>((ref) => DeepLinkService());

/// Lifecycle-managing notifier for deep-link handling.
///
/// Behaviour:
///  - On first build, consume the initial (cold-start) link and navigate to
///    the target route if the user is already authenticated.
///  - Subscribe to the `uriLinkStream` for links that arrive while the app
///    is running.
///  - If a link arrives while the user is NOT authenticated, stash it as a
///    pending route and replay it after `authStateProvider` reports a user
///    (so a shared PDF link still lands on the PDF after the user signs in).
///  - Navigation goes through the `routerProvider` so auth guards still run.
class DeepLinkNotifier extends Notifier<String?> {
  StreamSubscription<String>? _sub;

  @override
  String? build() {
    ref.keepAlive();
    ref.onDispose(() {
      _sub?.cancel();
    });

    _bootstrap();
    return null;
  }

  Future<void> _bootstrap() async {
    final service = ref.read(deepLinkServiceProvider);

    // Cold-start link.
    final initial = await service.getInitialRoute();
    if (initial != null) {
      _handleRoute(initial);
    }

    // In-session links.
    _sub?.cancel();
    _sub = service.routeStream.listen(_handleRoute);

    // If the user authenticates later, replay any pending route.
    ref.listen(authStateProvider, (previous, next) {
      final user = next.value;
      final pending = state;
      if (user != null && pending != null) {
        _navigate(pending);
        state = null;
      }
    });
  }

  void _handleRoute(String route) {
    final isLoggedIn = ref.read(authStateProvider).value != null;
    if (!isLoggedIn) {
      state = route;
      return;
    }
    _navigate(route);
  }

  void _navigate(String route) {
    final router = ref.read(routerProvider);
    router.go(route);
  }

  /// Allow other subsystems (e.g. FCM notification taps) to feed a route
  /// through the same pending-link machinery.
  void push(String route) => _handleRoute(route);
}

final deepLinkProvider = NotifierProvider<DeepLinkNotifier, String?>(
  DeepLinkNotifier.new,
);
