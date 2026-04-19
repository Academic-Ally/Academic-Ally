import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/allybot/screens/ally_chat_screen.dart';
import '../features/allybot/screens/allybot_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/communities/screens/channel_detail_screen.dart';
import '../features/communities/screens/communities_screen.dart';
import '../features/communities/screens/create_channel_screen.dart';
import '../features/gen_ui/screens/gen_ui_screen.dart';
import '../features/jobs/screens/job_detail_screen.dart';
import '../features/jobs/screens/jobs_screen.dart';
import '../features/jobs/screens/post_job_screen.dart';
import '../features/marketplace/screens/create_listing_screen.dart';
import '../features/marketplace/screens/marketplace_detail_screen.dart';
import '../features/marketplace/screens/marketplace_screen.dart';
import '../features/misconception_graph/screens/knowledge_map_screen.dart';
import '../features/project_copilot/screens/create_project_screen.dart';
import '../features/project_copilot/screens/project_copilot_screen.dart';
import '../features/project_copilot/screens/project_detail_screen.dart';
import '../features/pyq_analyzer/screens/pyq_analyzer_screen.dart';
import '../features/snap_doubt/screens/snap_doubt_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/study_planner/screens/create_study_plan_screen.dart';
import '../features/study_planner/screens/study_plan_detail_screen.dart';
import '../features/study_planner/screens/study_planner_screen.dart';
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
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';

      // Let splash + onboarding show without redirect
      if (isSplash || isOnboarding) return null;
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

      // Onboarding (first-launch only)
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
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
      GoRoute(
        path: '/knowledge-map',
        builder: (context, state) => const KnowledgeMapScreen(),
      ),
      GoRoute(
        path: '/study-planner',
        builder: (context, state) => const StudyPlannerScreen(),
      ),
      GoRoute(
        path: '/study-planner/create',
        builder: (context, state) => const CreateStudyPlanScreen(),
      ),
      GoRoute(
        path: '/study-planner/:planId',
        builder: (context, state) => StudyPlanDetailScreen(
          planId: state.pathParameters['planId']!,
        ),
      ),
      GoRoute(
        path: '/gen-ui',
        builder: (context, state) => const GenUiScreen(),
      ),
      GoRoute(
        path: '/pyq-analyzer',
        builder: (context, state) => const PyqAnalyzerScreen(),
      ),
      GoRoute(
        path: '/snap-doubt',
        builder: (context, state) => const SnapDoubtScreen(),
      ),
      GoRoute(
        path: '/project-copilot',
        builder: (context, state) => const ProjectCopilotScreen(),
      ),
      GoRoute(
        path: '/project-copilot/create',
        builder: (context, state) => const CreateProjectScreen(),
      ),
      GoRoute(
        path: '/project-copilot/:projectId',
        builder: (context, state) => ProjectDetailScreen(
          projectId: state.pathParameters['projectId']!,
        ),
      ),
      GoRoute(
        path: '/jobs',
        builder: (context, state) => const JobsScreen(),
      ),
      GoRoute(
        path: '/jobs/post',
        builder: (context, state) => const PostJobScreen(),
      ),
      GoRoute(
        path: '/jobs/:jobId',
        builder: (context, state) =>
            JobDetailScreen(jobId: state.pathParameters['jobId']!),
      ),
      GoRoute(
        path: '/communities',
        builder: (context, state) => const CommunitiesScreen(),
      ),
      GoRoute(
        path: '/communities/create',
        builder: (context, state) => const CreateChannelScreen(),
      ),
      GoRoute(
        path: '/communities/:channelId',
        builder: (context, state) => ChannelDetailScreen(
          channelId: state.pathParameters['channelId']!,
        ),
      ),
      GoRoute(
        path: '/marketplace',
        builder: (context, state) => const MarketplaceScreen(),
      ),
      GoRoute(
        path: '/marketplace/create',
        builder: (context, state) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '/marketplace/:listingId',
        builder: (context, state) => MarketplaceDetailScreen(
          listingId: state.pathParameters['listingId']!,
        ),
      ),
    ],
  );
});
