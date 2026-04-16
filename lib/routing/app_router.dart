import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/allybot/screens/ally_chat_screen.dart';
import '../features/allybot/screens/allybot_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/bookmarks/screens/bookmarks_screen.dart';
import '../features/downloads/screens/downloads_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/pdf_viewer/screens/pdf_viewer_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/update_profile_screen.dart';
import '../features/recents/screens/recents_screen.dart';
import '../features/resources/screens/resources_list_screen.dart';
import '../features/resources/screens/subject_resources_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/seekhub/screens/create_request_screen.dart';
import '../features/seekhub/screens/seekhub_screen.dart';
import '../features/upload/screens/upload_screen.dart';
import '../core/widgets/shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isSplash = state.matchedLocation == '/splash';
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';

      // Let splash screen show without redirect
      if (isSplash) return null;
      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes (no bottom nav)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/upload',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UploadScreen(),
            ),
          ),
          GoRoute(
            path: '/bookmarks',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BookmarksScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Feature routes (no bottom nav, full-screen)
      GoRoute(
        path: '/subject-resources',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return SubjectResourcesScreen(
            subject: Uri.decodeComponent(q['subject'] ?? ''),
            branch: q['branch'] ?? '',
            sem: q['sem'] ?? '',
            university: q['university'] ?? '',
            course: q['course'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/resources-list',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return ResourcesListScreen(
            university: q['university'] ?? '',
            course: q['course'] ?? '',
            branch: q['branch'] ?? '',
            sem: q['sem'] ?? '',
            subject: Uri.decodeComponent(q['subject'] ?? ''),
            resourceType: q['type'] ?? 'Notes',
          );
        },
      ),
      GoRoute(
        path: '/pdf-viewer',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return PdfViewerScreen(
            id: q['id'] ?? '',
            name: Uri.decodeComponent(q['name'] ?? ''),
            subject: Uri.decodeComponent(q['subject'] ?? ''),
            category: Uri.decodeComponent(q['category'] ?? ''),
            university: q['university'] ?? '',
            course: q['course'] ?? '',
            branch: q['branch'] ?? '',
            sem: q['sem'] ?? '',
            storageId: q['storageId'] != null
                ? Uri.decodeComponent(q['storageId']!)
                : null,
            resourceType: q['type'] ?? 'Notes',
          );
        },
      ),
      GoRoute(
        path: '/allybot',
        builder: (context, state) => const AllyBotScreen(),
      ),
      GoRoute(
        path: '/allybot-chat',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return AllyChatScreen(
            sessionId: q['sessionId'],
            resourceId: q['resourceId'],
            resourceName: q['resourceName'] != null
                ? Uri.decodeComponent(q['resourceName']!)
                : null,
            subject: q['subject'] != null
                ? Uri.decodeComponent(q['subject']!)
                : null,
            storageId: q['storageId'] != null
                ? Uri.decodeComponent(q['storageId']!)
                : null,
          );
        },
      ),
      GoRoute(
        path: '/seekhub',
        builder: (context, state) => const SeekHubScreen(),
      ),
      GoRoute(
        path: '/seekhub/create',
        builder: (context, state) => const CreateRequestScreen(),
      ),
      GoRoute(
        path: '/recents',
        builder: (context, state) => const RecentsScreen(),
      ),
      GoRoute(
        path: '/downloads',
        builder: (context, state) => const DownloadsScreen(),
      ),
      GoRoute(
        path: '/update-profile',
        builder: (context, state) => const UpdateProfileScreen(),
      ),
    ],
  );
});
