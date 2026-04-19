# Flutter App Architecture — `academic_ally/`

Deep dive into the Flutter project structure, tech stack, routes, assets, and current build state.

## Tech Stack

| Layer | Choice | Why |
|-------|--------|-----|
| State management | Riverpod 3.x (Notifier pattern) | Modern, testable, replaces Redux |
| Navigation | GoRouter (declarative) | Auth guard, deep-link support, ShellRoute for bottom nav |
| Design system | Material Design 3 | Branded: #6360FF primary, #FF8181 tertiary, #F1F1FA secondary |
| Font | Poppins (via google_fonts) | Same as RN original |
| PDF storage | **Google Drive (demo)** — R2 migration deferred | 6 branch-specific Drive accounts already host all existing content; zero migration effort; same as current web app |
| PDF viewing | **`webview_flutter`** embedding Drive's preview URL | Matches web app pattern exactly — `https://drive.google.com/file/d/<id>/preview` |
| Backend | Firebase (Auth, Firestore, Storage, Messaging, Analytics) | Unchanged from RN |
| Cloud functions | Netlify serverless | Unchanged |

## Firebase Configuration

- **Project:** `academic-ally-app`
- **Android app:** `com.academically` (registered)
- **iOS app:** placeholder (requires Mac to build)
- **google-services.json:** `academic_ally/android/app/google-services.json`
- **minSdk:** 23 (required by Firebase)

## Project Structure

```
academic_ally/lib/
├── main.dart                              # Entry point (Firebase init + Riverpod)
├── firebase_options.dart                  # Firebase config
├── config/
│   └── theme.dart                         # M3 light/dark themes (brand colors, Poppins)
├── core/
│   ├── constants/
│   │   ├── app_constants.dart             # Universities, branches, sems, resource types, R2 config
│   │   └── firestore_paths.dart           # All Firestore path helpers
│   ├── providers/
│   │   ├── theme_provider.dart            # Light/dark mode (persisted to SharedPreferences)
│   │   ├── fcm_provider.dart              # FcmSyncNotifier + foregroundMessageProvider + FCM-tap → deep-link bridge
│   │   ├── deep_link_provider.dart        # DeepLinkNotifier (cold-start + stream + pending-link queue)
│   │   └── ai_provider.dart               # aiServiceProvider — single swap point for MockAIService → GeminiAIService
│   ├── services/
│   │   ├── r2_storage_service.dart        # Cloudflare R2 download/upload/local file helpers
│   │   ├── fcm_service.dart               # FCM token/topic/permission/cleanup lifecycle
│   │   ├── deep_link_service.dart         # URL ↔ GoRouter route mapper + shareable URL builder
│   │   └── ai/
│   │       ├── ai_service.dart            # Abstract AIService interface (Phase 2 foundation)
│   │       ├── mock_ai_service.dart       # Realistic mock impl — used in Phases 2-3
│   │       └── gemini_ai_service.dart     # Phase 4 stub (every method throws UnimplementedError)
│   └── widgets/
│       ├── screen_layout.dart             # Reusable purple header + rounded body layout
│       └── shell_scaffold.dart            # Bottom navigation shell (5 tabs)
├── features/
│   ├── onboarding/
│   │   └── screens/onboarding_screen.dart   # 4-slide intro (RN parity), first launch only
│   ├── misconception_graph/
│   │   ├── providers/misconception_graph_provider.dart  # Nodes + mastery/misconception streams + PracticeNotifier
│   │   ├── screens/knowledge_map_screen.dart            # Subject picker + topic list with mastery bars
│   │   └── widgets/practice_sheet.dart                  # Quiz loop → AI tags misconception + updates mastery
│   ├── allybot/
│   │   ├── providers/allybot_provider.dart     # Chat sessions stream, AllyBotService
│   │   └── screens/
│   │       ├── allybot_screen.dart              # Chat session list
│   │       └── ally_chat_screen.dart            # Individual chat interface
│   ├── auth/
│   │   ├── providers/auth_provider.dart         # Auth state, user profile, AuthService
│   │   └── screens/                             # Login, Signup, ForgotPassword
│   ├── bookmarks/
│   │   ├── providers/bookmarks_provider.dart    # Bookmarks stream, BookmarksService
│   │   └── screens/bookmarks_screen.dart        # Grouped bookmarks with swipe-to-delete
│   ├── downloads/
│   │   ├── providers/downloads_provider.dart    # Local file management, DownloadsNotifier
│   │   └── screens/downloads_screen.dart        # Downloaded PDFs list
│   ├── home/
│   │   └── screens/home_screen.dart             # Welcome, QuickAccess, Recommended subjects
│   ├── pdf_viewer/
│   │   ├── screens/pdf_viewer_screen.dart       # PDF viewing, download, bookmark, rate, share, report
│   │   └── widgets/report_bottom_sheet.dart     # Report abuse bottom sheet (3 reasons + mailto fallback)
│   ├── profile/
│   │   ├── providers/profile_provider.dart      # ProfileService (update profile)
│   │   └── screens/
│   │       ├── profile_screen.dart              # Profile display + settings + support
│   │       └── update_profile_screen.dart       # Edit name, college, branch, sem
│   ├── recents/
│   │   ├── providers/recents_provider.dart      # RecentsNotifier (SharedPreferences)
│   │   └── screens/recents_screen.dart          # Recently viewed PDFs
│   ├── resources/
│   │   ├── providers/resources_provider.dart    # Subjects list, resource fetching, rating
│   │   └── screens/
│   │       ├── subject_resources_screen.dart    # 4 resource type cards per subject
│   │       └── resources_list_screen.dart       # List of resources in a category
│   ├── search/
│   │   ├── providers/search_provider.dart       # Search query, filters, filtered subjects
│   │   └── screens/search_screen.dart           # Search with branch/sem filters
│   ├── seekhub/
│   │   ├── providers/seekhub_provider.dart      # SeekHub requests stream, SeekHubService
│   │   └── screens/
│   │       ├── seekhub_screen.dart              # Request list with subscribe toggle
│   │       └── create_request_screen.dart       # New request form
│   ├── splash/
│   │   └── screens/splash_screen.dart           # Animated splash (logo + brand text + auth routing)
│   └── upload/
│       ├── providers/upload_provider.dart        # UploadNotifier with progress tracking
│       └── screens/upload_screen.dart            # Upload form with file selection
├── models/
│   ├── user_model.dart                    # UserModel (Firestore Users schema)
│   ├── resource_model.dart                # ResourceModel (Firestore resources schema)
│   ├── subject_model.dart                 # SubjectModel (from QueryList)
│   ├── seekhub_request_model.dart         # SeekHubRequestModel
│   ├── chat_session_model.dart            # ChatSessionModel + ChatMessage
│   ├── recent_pdf_model.dart              # RecentPdfModel (local storage)
│   └── ai_models.dart                     # KnowledgeNode, Misconception, MasteryScore, StudyPlan/Day/Task, PyqAnalysis, PredictedQuestion, DoubtSolution, SolutionStep, ProjectGuidance, ProjectPhase
└── routing/
    └── app_router.dart                    # GoRouter: auth guard + ShellRoute + all feature routes
```

## GoRouter Routes (17 total)

```
Splash:
  /splash               → SplashScreen (initial — animated logo, routes to /home, /onboarding, or /login)

Onboarding (first launch only):
  /onboarding           → OnboardingScreen (4 slides, sets intro_shown flag, navigates to /login)

Auth (no bottom nav):
  /login                → LoginScreen
  /signup               → SignupScreen
  /forgot-password      → ForgotPasswordScreen

ShellRoute (bottom nav):
  /home                 → HomeScreen
  /search               → SearchScreen
  /upload               → UploadScreen
  /bookmarks            → BookmarksScreen
  /profile              → ProfileScreen

Feature screens (full-screen, no bottom nav):
  /subject-resources    → SubjectResourcesScreen (query params: subject, branch, sem, university, course)
  /resources-list       → ResourcesListScreen (query params: university, course, branch, sem, subject, type)
  /pdf-viewer           → PdfViewerScreen (query params: id, name, subject, category, university, course, branch, sem, storageId, type)
  /allybot              → AllyBotScreen (chat session list)
  /allybot-chat         → AllyChatScreen (query params: sessionId, resourceId, resourceName, subject, storageId)
  /seekhub              → SeekHubScreen (request list)
  /seekhub/create       → CreateRequestScreen
  /recents              → RecentsScreen
  /downloads            → DownloadsScreen
  /update-profile       → UpdateProfileScreen
```

## Assets

```
assets/
├── images/
│   ├── onboarding2.png                # Onboarding slide 2 (book + woman reading)
│   ├── onboarding3.png                # Onboarding slide 1 (man reading on chair)
│   ├── seekhub.png                    # Onboarding slide 3 (SeekHub illustration)
│   ├── allychatbot.png                # Onboarding slide 4 (AllyBot robot illustration)
│   ├── logo.png                       # Main logo (dark navy, transparent bg)
│   ├── logo_black.png                 # Black variant
│   ├── white-logo.png                 # White variant (purple backgrounds, splash, auth)
│   ├── LogInIllustration.png          # Login illustration
│   ├── ic_launcher.png                # App launcher icon source (dark bg)
│   ├── ic_launcher_foreground.png     # Adaptive icon foreground (white logo, transparent bg)
│   ├── ic_launcher_round.png          # Round launcher icon
│   └── bootsplash_logo.png            # Splash logo (light variant)
└── lottie/
    ├── hat.json                       # Graduation hat animation (auth screen)
    └── NoBookMarks.json               # Empty bookmarks animation
```

## Key Dependencies (pubspec.yaml)

```yaml
flutter_riverpod: ^3.3.1       # State management (Notifier pattern)
go_router: ^17.2.0             # Declarative routing
firebase_core/auth/firestore/storage/messaging/analytics
google_fonts: ^8.0.2           # Poppins font
flutter_pdfview: ^1.4.4        # PDF viewing (ready when storage connected)
lottie: ^3.3.2                 # Lottie animations
shimmer: ^3.0.0                # Loading skeletons
share_plus: ^13.0.0            # Share functionality
url_launcher: ^6.3.2           # External links
cached_network_image: ^3.4.1   # Image caching
connectivity_plus: ^7.1.1      # Network status
http: ^1.6.0                   # HTTP requests (cloud function calls)
uuid: ^4.5.3                   # UUID generation (SeekHub requests)
shared_preferences: ^2.5.5     # Local persistence (theme, recents, onboarding flag)
path_provider: ^2.1.5          # File system paths

# Dev
flutter_launcher_icons: ^0.14.3  # Generate launcher icons
flutter_native_splash: ^2.4.6    # Native splash screen
```

## What's Built (functional)

- [x] Firebase integration (Auth, Firestore connected)
- [x] Auth flow (Login, Signup with university/branch/sem, Forgot Password, Email verification)
- [x] GoRouter with auth guard + 17 routes
- [x] Bottom navigation (Home, Search, Upload, Bookmarks, Profile)
- [x] Material Design 3 theming with brand colors + dark mode toggle
- [x] Data models (UserModel, ResourceModel, SubjectModel, SeekHubRequestModel, ChatSessionModel, RecentPdfModel)
- [x] R2 storage service (ready for config)
- [x] Subject/Resources browser (university → branch → sem → subject → 4 resource types → list)
- [x] PDF viewer screen (download, bookmark, rate, share, AllyBot integration, report abuse)
- [x] Search with Firestore queries + branch/sem filters
- [x] Bookmarks (Firestore-synced, grouped by subject, swipe-to-delete)
- [x] Recents (locally persisted, time-ago display)
- [x] Downloads manager (offline file management)
- [x] Upload flow (form + metadata submission to Firestore NewUploads)
- [x] AllyBot (chat session list + chat interface with message bubbles)
- [x] SeekHub (request list, create request, subscribe to notifications)
- [x] Profile display + update profile screen
- [x] Home screen recommended subjects (from Firestore QueryList)
- [x] All navigation wired (QuickAccess, Profile settings, Subject → Resources → PDF)
- [x] Logo + Lottie animations integrated
- [x] Custom app launcher icon (Academic Ally logo, adaptive icon with #161719 background)
- [x] Native splash (solid #6360FF purple, seamless transition to Dart splash)
- [x] Animated Dart splash screen (logo scales in, tagline slides up, auto-routes)
- [x] Onboarding screens (4 slides matching RN, no skip button, `intro_shown` flag)
- [x] Report abuse (bottom sheet with 3 reasons + mailto fallback → `userReports` Firestore path)
- [x] FCM push notifications — `FcmService` manages token + topic lifecycle, `FcmSyncNotifier` auto-syncs when user profile loads or changes (unsubscribes stale topic, subscribes new `{university}_{course}_{branch}_{sem}`). Runtime permission handled once (tracked via `fcm_permission_asked` SharedPref key). Foreground messages surface as themed SnackBar via root `ScaffoldMessengerKey`. Background handler at top-level in `main.dart`. Android: `POST_NOTIFICATIONS` permission + default channel `academic_ally_default` + `notification_color` resource. Sign-out + account delete go through `performSignOut(ref)` / `performDeleteAccount(ref)` which clear FCM token, unsubscribe topics, and call `deleteToken()` before Auth sign-out.
- [x] Misconception Graph — Knowledge Map screen accessible from home's "AI Tools" section and `/knowledge-map` route. Subject picker (defaults to user's curriculum via `recommendedSubjectsProvider`). Topic nodes currently client-generated in `misconception_graph_provider.dart` mirroring `MockAIService._topicsFor` (in Phase 4, will read from `KnowledgeGraph/{university}/{course}/{subject}/nodes`). Each topic shows a mastery bar (red <40%, amber 40–70%, green >70%) + misconception chip when one exists. Tap → `PracticeSheet` bottom sheet — user writes an answer, self-assesses got-it/missed-it, `AIService.updateMastery` + `tagMisconceptions` run, results persist to `Users/{uid}/MasteryScores/{nodeId}` + `Users/{uid}/Misconceptions/{nodeId}` and stream back into the list live. Firestore rule blocks already in drafted `firestore.rules` (deferred deploy).
- [x] Deep linking — `app_links` package. `DeepLinkService.parseRoute()` maps `academically://<route>?<query>` + `https://getacademically.co/<route>?<query>` + `https://app.getacademically.co/<route>?<query>` to GoRouter paths. Allow-list on routes prevents path-injection. `DeepLinkNotifier` handles cold-start link + in-session `uriLinkStream`, queues as pending if user not authed and replays after login via `authStateProvider` listener. PDF viewer share generates a real `https://getacademically.co/pdf-viewer?...` URL via `DeepLinkService.buildShareUrl`. FCM notification taps bridged through `FcmSyncNotifier._routeFromMessage` — payload `data.route` feeds into `DeepLinkNotifier.push`. Android intent-filters for custom scheme + both HTTPS domains with `autoVerify=true` (requires `/.well-known/assetlinks.json` hosted on domain for chooser-less behavior — tech debt, functional either way).

## AllyBot Current State

- Chat UI, Firestore session storage, rate limiting, HTTP plumbing — all done
- ⚠ `cloudFunctionsBaseUrl` in `app_constants.dart:55` is **wrong** — points to Firebase Functions, backend is Netlify
- Backend is ChatPDF (PDF Q&A only) — insufficient for new AI features; will swap to general LLM in Phase 4
