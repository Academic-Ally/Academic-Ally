import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/theme.dart';
import 'core/providers/deep_link_provider.dart';
import 'core/providers/fcm_provider.dart';
import 'core/providers/theme_provider.dart';
import 'firebase_options.dart';
import 'routing/app_router.dart';

/// Background / terminated-state FCM handler.
///
/// Must be a top-level function (FCM contract) — runs in an isolated Dart
/// isolate with no Riverpod state. The system already displays the
/// notification for `notification` payloads; keep this minimal.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Global scaffold messenger so foreground FCM messages can surface an
/// in-app SnackBar from anywhere in the widget tree.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const ProviderScope(child: AcademicAllyApp()));
}

class AcademicAllyApp extends ConsumerWidget {
  const AcademicAllyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Activate deep-link handling (cold-start + in-session URIs).
    ref.watch(deepLinkProvider);

    // Activate FCM sync lifecycle (token, topic subscriptions, tap bridge).
    ref.watch(fcmSyncProvider);

    // Show an in-app SnackBar when a push arrives while the app is in the
    // foreground. System notifications only appear when the app is in the
    // background; foreground delivery is silent unless handled here.
    ref.listen(foregroundMessageProvider, (_, next) {
      final message = next.value;
      if (message == null) return;
      final notification = message.notification;
      final title = notification?.title;
      final body = notification?.body;
      if (title == null && body == null) return;

      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              if (body != null)
                Padding(
                  padding: EdgeInsets.only(top: title != null ? 4 : 0),
                  child: Text(body),
                ),
            ],
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    });

    return MaterialApp.router(
      title: 'Academic Ally',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
