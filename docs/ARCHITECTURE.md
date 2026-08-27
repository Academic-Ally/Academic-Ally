# Flutter App Architecture — `academic_ally/`

Deep dive into the Flutter project structure, tech stack, routes, assets, and current build state (Phases 1+2+3 complete).

## Tech Stack

| Layer | Choice | Why |
|-------|--------|-----|
| State management | Riverpod 3.x (Notifier pattern) | Modern, testable, replaces Redux |
| Navigation | GoRouter (declarative) | Auth guard, deep-link support, ShellRoute for bottom nav |
| Design system | Material Design 3 | Branded: #6360FF primary, #FF8181 tertiary, #F1F1FA secondary |
| Font | Poppins (via google_fonts) | Same as RN original |
| PDF storage | **Firebase Storage** (`getDownloadURL()` streamed into the viewer) | R2 was evaluated, abandoned 2026-04-26, and its dead code deleted 2026-08-27 |
| PDF viewing | `flutter_pdfview` (live, supports `initialPage` for AI citations) | Native PDF rendering |
| Image uploads | Firebase Storage (auth-gated, deployed 2026-04-20) | Used by Marketplace for listing photos |
| Image picker | `image_picker` 1.1.2 | Camera + gallery for Marketplace, Snap-a-Doubt |
| Deep linking | `app_links` 6.4.1 | Custom scheme + universal links |
| AI service | `AgentAIService` → FastAPI backend (live for 5 features); `MockAIService` still backs the 3 hidden ones | Single swap point via `aiServiceProvider` |
| Backend | Firebase (Auth, Firestore, Storage, Messaging, Analytics) | Unchanged from RN |
| Cloud functions | Firebase `stopBilling` (billing cap) only | The Netlify AllyBot backend is retired; AllyBot now calls `/chat_about_pdf` on the Python backend |
| AI backend | **FastAPI + CrewAI + Gemini** in `backend/` | See `docs/AGENTIC_FEATURES.md`; deployment currently DOWN (see CLAUDE.md status banner) |

## Firebase Configuration

- **Project:** `academic-ally-app`
- **Plan:** Blaze (₹200/month cap via `stopBilling` Cloud Function)
- **Android app:** `com.academically` (registered)
- **iOS app:** placeholder (requires Mac to build)
- **google-services.json:** `academic_ally/android/app/google-services.json`
- **minSdk:** 23 (required by Firebase)
- **Storage rules:** DEPLOYED 2026-04-20 (auth-gated)
- **Firestore rules:** Console-edited, permissive. Strict rules pending Phase 4.

## Project Structure

```
academic_ally/
├── firebase.json                         # Firebase CLI config (Functions + Storage)
├── storage.rules                         # Deployed — auth-gate
├── functions/                            # Firebase Cloud Functions (billing cap only)
├── docs/                                 # Context docs (this + CLAUDE, etc.)
└── lib/
    ├── main.dart                         # Entry: Firebase init + Riverpod + FCM bg handler + global SnackBar messenger
    ├── firebase_options.dart             # Firebase config
    ├── config/
    │   └── theme.dart                    # M3 light/dark themes
    ├── core/
    │   ├── constants/
    │   │   ├── app_constants.dart        # Universities, branches, sems, resource types, backend + cloud function URLs
    │   │   └── firestore_paths.dart      # Every Firestore path helper (27 collections)
    │   ├── providers/
    │   │   ├── theme_provider.dart       # Light/dark mode (persisted)
    │   │   ├── fcm_provider.dart         # FcmSyncNotifier + foregroundMessageProvider + FCM-tap → deep-link bridge
    │   │   ├── deep_link_provider.dart   # DeepLinkNotifier (cold-start + stream + pending-link queue)
    │   │   └── ai_provider.dart          # aiServiceProvider — single swap point (Mock ↔ Agent backend)
    │   ├── services/
    │   │   ├── fcm_service.dart          # FCM token/topic/permission/cleanup — has 3-layer idempotency fix
    │   │   ├── deep_link_service.dart    # URL ↔ GoRouter route mapper with allow-list
    │   │   └── ai/
    │   │       ├── ai_service.dart       # Abstract AIService (8 methods)
    │   │       ├── mock_ai_service.dart  # Realistic mock — persists to real Firestore
    │   │       └── gemini_ai_service.dart # Phase 4 stub (throws UnimplementedError)
    │   └── widgets/
    │       ├── screen_layout.dart        # Reusable purple header + rounded body
    │       └── shell_scaffold.dart       # Bottom navigation shell (5 tabs)
    ├── features/
    │   ├── allybot/                      # PDF chat (session list + chat UI)
    │   ├── auth/                         # Login / Signup / ForgotPassword + auth_provider
    │   ├── bookmarks/                    # Firestore-synced, grouped, swipe-to-delete
    │   ├── communities/                  # ⭐ Phase 3 — channels list + chat detail + create
    │   ├── downloads/                    # Local file management
    │   ├── gen_ui/                       # ⭐ Phase 2 — prompt input + JSON tree renderer
    │   ├── home/                         # Welcome + QuickAccess + AI Tools + Explore + Recommended
    │   ├── jobs/                         # ⭐ Phase 3 — list + detail + post + external apply
    │   ├── marketplace/                  # ⭐ Phase 3 — grid + detail + create with Storage uploads
    │   ├── misconception_graph/          # ⭐ Phase 2 — Knowledge Map + practice sheet
    │   ├── onboarding/                   # 4-slide intro with Skip button
    │   ├── pdf_viewer/                   # PDF view + report bottom sheet
    │   ├── profile/                      # Profile display + update
    │   ├── project_copilot/              # ⭐ Phase 2 — list + create + 4-tab detail
    │   ├── pyq_analyzer/                 # ⭐ Phase 2 — subject picker + cached analysis
    │   ├── recents/                      # SharedPreferences, time-ago
    │   ├── resources/                    # Subject / resources browser
    │   ├── search/                       # Firestore search with branch/sem filters
    │   ├── seekhub/                      # Resource request board
    │   ├── snap_doubt/                   # ⭐ Phase 2 — camera/gallery + mock solver
    │   ├── splash/                       # Animated splash with routing
    │   ├── study_planner/                # ⭐ Phase 2 — list + create + detail
    │   └── upload/                       # Community contribution queue
    ├── models/
    │   ├── user_model.dart               # UserModel (Firestore Users)
    │   ├── resource_model.dart           # ResourceModel
    │   ├── subject_model.dart            # SubjectModel (reads subjectName with subject fallback)
    │   ├── seekhub_request_model.dart
    │   ├── chat_session_model.dart       # ChatSessionModel + ChatMessage (AllyBot)
    │   ├── recent_pdf_model.dart         # RecentPdfModel (local)
    │   ├── ai_models.dart                # ⭐ All Phase 2 AI types
    │   ├── channel_model.dart            # ⭐ Phase 3 — ChannelModel + ChannelMessage
    │   ├── job_model.dart                # ⭐ Phase 3 — JobModel + JobType enum
    │   ├── marketplace_model.dart        # ⭐ Phase 3 — MarketplaceListing + ListingCondition
    │   └── project_model.dart            # ⭐ Phase 2 — ProjectModel (Project Copilot)
    └── routing/
        └── app_router.dart               # GoRouter — 30+ routes
```

## GoRouter Routes (31 total)

```
Splash + onboarding:
  /splash               → SplashScreen (routes to /home, /onboarding, or /login)
  /onboarding           → OnboardingScreen (4 slides + Skip, sets intro_shown)

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

Pre-existing feature screens:
  /subject-resources    → SubjectResourcesScreen
  /resources-list       → ResourcesListScreen
  /pdf-viewer           → PdfViewerScreen
  /allybot              → AllyBotScreen
  /allybot-chat         → AllyChatScreen
  /seekhub              → SeekHubScreen
  /seekhub/create       → CreateRequestScreen
  /recents              → RecentsScreen
  /downloads            → DownloadsScreen
  /update-profile       → UpdateProfileScreen

Phase 2 — AI features:
  /knowledge-map        → KnowledgeMapScreen
  /study-planner        → StudyPlannerScreen
  /study-planner/create → CreateStudyPlanScreen
  /study-planner/:id    → StudyPlanDetailScreen
  /gen-ui               → GenUiScreen
  /pyq-analyzer         → PyqAnalyzerScreen
  /snap-doubt           → SnapDoubtScreen
  /project-copilot      → ProjectCopilotScreen
  /project-copilot/create → CreateProjectScreen
  /project-copilot/:id  → ProjectDetailScreen

Phase 3 — Community features:
  /jobs                 → JobsScreen
  /jobs/post            → PostJobScreen
  /jobs/:id             → JobDetailScreen
  /communities          → CommunitiesScreen
  /communities/create   → CreateChannelScreen
  /communities/:id      → ChannelDetailScreen
  /marketplace          → MarketplaceScreen
  /marketplace/create   → CreateListingScreen
  /marketplace/:id      → MarketplaceDetailScreen
```

## Deep-link allow-list

Defined in `DeepLinkService._allowedRoutes`. Covers all routes reachable from outside the app (FCM taps, URL shares):

```
/pdf-viewer, /subject-resources, /resources-list, /allybot, /allybot-chat,
/seekhub, /recents, /downloads,
/knowledge-map, /study-planner, /gen-ui, /pyq-analyzer, /snap-doubt, /project-copilot,
/jobs, /communities, /marketplace
```

## Home screen composition (redesigned 2026-04-27)

1. **Quick Access** (icon row) — Recents, Downloads, AllyBot, etc.
2. **AI Tools** — 4 horizontal pill tiles: Study Planner, PYQ Analyzer, Adversarial Examiner, Snap a Doubt
3. **Coming Soon...** — 3 pill tiles: Jobs, Communities, Marketplace
4. **Recommended** — subjects pulled from Firestore `QueryList`

Knowledge Map, Gen UI and Project Copilot tiles were REMOVED from the home screen
(their routes still exist in `app_router.dart`). Dark mode support was overhauled
in the same pass — use `context.mutedText` / `context.faintText`, never raw
`Colors.grey[XXX]`.

## Assets

```
assets/
├── images/
│   ├── onboarding2.png, onboarding3.png, seekhub.png, allychatbot.png    # Onboarding
│   ├── logo.png, logo_black.png, white-logo.png                          # Logos
│   ├── LogInIllustration.png
│   ├── ic_launcher*.png, bootsplash_logo.png                             # Icons + splash
└── lottie/
    ├── hat.json, NoBookMarks.json
```

## Key Dependencies (pubspec.yaml)

```yaml
flutter_riverpod: ^3.3.1
go_router: ^17.2.0
firebase_core/auth/firestore/storage/messaging/analytics
google_fonts: ^8.0.2
flutter_pdfview: ^1.4.4
lottie: ^3.3.2
shimmer: ^3.0.0                # not yet used — loading skeleton opportunity
share_plus: ^13.0.0
url_launcher: ^6.3.2            # used by: Jobs apply, Marketplace WhatsApp contact, Report mailto
cached_network_image: ^3.4.1
connectivity_plus: ^7.1.1
http: ^1.6.0
uuid: ^4.5.3
shared_preferences: ^2.5.5
path_provider: ^2.1.5
app_links: ^6.4.1               # Phase 1 — deep linking
image_picker: ^1.1.2            # Phase 2-3 — Snap-a-Doubt, Marketplace

# Dev
flutter_launcher_icons: ^0.14.3
flutter_native_splash: ^2.4.6
```

## Build Status

**Do not maintain a feature list here** — it drifts. The authoritative, current
inventory of all 28 features (and which AI features are live vs hidden vs mocked)
lives in the **Feature Inventory** section of `academic_ally/CLAUDE.md`.

Known outstanding work is tracked in CLAUDE.md's "What's Still Left" section.

## AllyBot current state

Rewritten in commit `4f7ed09`. It is no longer the legacy Netlify ChatPDF
integration: AllyBot now posts to `/chat_about_pdf` on the Python backend, which
answers with a single Gemini call grounded in RAG chunks filtered by
`resource_id_filter`, so the conversation stays scoped to the PDF the user has
open. Chat UI, Firestore session storage and rate limiting are unchanged.
