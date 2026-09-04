import 'dart:async';

import 'package:academically/features/auth/providers/auth_provider.dart';
import 'package:academically/routing/app_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _User extends Fake implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'auth events preserve router identity and the active doubt location',
    () async {
      final auth = StreamController<User?>();
      final container = ProviderContainer(
        overrides: [authStateProvider.overrideWith((ref) => auth.stream)],
      );
      final subscription = container.listen(routerProvider, (_, _) {});
      final router = container.read(routerProvider);
      router.go('/snap-doubt');
      auth.add(_User());
      await Future<void>.delayed(Duration.zero);
      expect(container.read(routerProvider), same(router));
      expect(router.routeInformationProvider.value.uri.path, '/snap-doubt');
      auth.add(_User());
      await Future<void>.delayed(Duration.zero);
      expect(container.read(routerProvider), same(router));
      expect(router.routeInformationProvider.value.uri.path, '/snap-doubt');
      subscription.close();
      container.dispose();
      await auth.close();
    },
  );
}
