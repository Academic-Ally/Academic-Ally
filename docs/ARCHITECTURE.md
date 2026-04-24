# Flutter App Architecture — `academic_ally/`

Deep dive into the Flutter project structure, tech stack, routes, assets, and current build state (Phases 1+2+3 complete).

## Tech Stack

| Layer | Choice | Why |
|-------|--------|-----|
| State management | Riverpod 3.x (Notifier pattern) | Modern, testable, replaces Redux |
| Navigation | GoRouter (declarative) | Auth guard, deep-link support, ShellRoute for bottom nav |
| Design system | Material Design 3 | Branded: #6360FF primary, #FF8181 tertiary, #F1F1FA secondary |
| Font | Poppins (via google_fonts) | Same as RN original |
| PDF storage | **Cloudflare R2** (scaffolded, `publicBaseUrl` pending) | Zero egress (Firebase Storage scales badly for public PDFs) |
| PDF viewing | `flutter_pdfview` (scaffolded — placeholder rendering until R2 is filled) | Native PDF rendering |
| Image uploads | Firebase Storage (auth-gated, deployed 2026-04-20) | Used by Marketplace for listing photos |
| Image picker | `image_picker` 1.1.2 | Camera + gallery for Marketplace, Snap-a-Doubt |
| Deep linking | `app_links` 6.4.1 | Custom scheme + universal links |
| AI service | `MockAIService` (Phase 2-3), `GeminiAIService` stub (Phase 4) | Single swap point via `aiServiceProvider` |
| Backend | Firebase (Auth, Firestore, Storage, Messaging, Analytics) | Unchanged from RN |
| Cloud functions | Firebase (billing cap) + Netlify (legacy AllyBot) | Mixed — Phase 4 audits this |

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
    │   │   ├── app_constants.dart        # Universities, branches, sems, resource types, R2 config, cloud function URL
    │   │   └── firestore_paths.dart      # Every Firestore path helper (27 collections)
    │   ├── providers/
    │   │   ├── theme_provider.dart       # Light/dark mode (persisted)
    │   │   ├── fcm_provider.dart         # FcmSyncNotifier + foregroundMessageProvider + FCM-tap → deep-link bridge
    │   │   ├── deep_link_provider.dart   # DeepLinkNotifier (cold-start + stream + pending-link queue)
    │   │   └── ai_provider.dart          # aiServiceProvider — single swap point for Phase 4
    │   ├── services/
    │   │   ├── r2_storage_service.dart   # Cloudflare R2 — publicBaseUrl PENDING
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

## Home screen composition (3 sections)

1. **Quick Access** (icon row) — Recents, Downloads, AllyBot, etc.
2. **AI Tools** (horizontal scroll, 6 cards, Phase 2)
3. **Explore** (horizontal scroll, 3 cards, Phase 3)
4. **Recommended** — subjects pulled from Firestore `QueryList`

Each card uses the `_AiToolCard` widget in `home_screen.dart` regardless of section — single visual pattern.

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

## Build Status (as of 2026-04-20)

All 24 features complete and working:

**Pre-existing migration:**
- [x] Firebase integration (Auth, Firestore, Storage, Messaging, Analytics)
- [x] Auth flow (Login / Signup / Forgot Password / Email verification)
- [x] Bottom navigation (Home, Search, Upload, Bookmarks, Profile)
- [x] Material Design 3 + dark mode
- [x] R2 storage service (scaffolded, `publicBaseUrl` pending Phase 4)
- [x] Subject/Resources browser (university → branch → sem → subject → 4 resource types)
- [x] PDF viewer (placeholder rendering until R2 fills)
- [x] Search with Firestore queries + filters
- [x] Bookmarks, Recents, Downloads
- [x] Upload flow → NewUploads queue
- [x] AllyBot (chat UI, legacy ChatPDF backend — Phase 4 swap to Gemini)
- [x] SeekHub (request board + subscribe toggle)
- [x] Profile + update profile
- [x] Splash + onboarding (4 slides + Skip)

**Phase 1 — Infrastructure:**
- [x] Onboarding with Skip button
- [x] Report abuse bottom sheet
- [x] Deep linking (app_links, custom scheme + universal links, FCM-tap bridge, pending-link queue)
- [x] FCM push notifications with 3-layer idempotency fix

**Phase 2 — AI Features (on mocks):**
- [x] AI service abstraction (`AIService`, `MockAIService`, `GeminiAIService` stub, `aiServiceProvider`, `ai_models.dart`)
- [x] Misconception Graph (Knowledge Map + practice sheet, persists mastery/misconceptions)
- [x] Study Planner (list + create + detail with task toggles)
- [x] Gen UI (prompt + renderer with 6 primitives)
- [x] PYQ Analyzer (subject picker + cached analysis — see Gotcha #3 in CLAUDE.md re: silent write failure)
- [x] Snap-a-Doubt (camera/gallery + mock solver + history)
- [x] Project Copilot (list + create + 4-tab detail with cached guidance)

**Phase 3 — Community Features:**
- [x] Jobs & Internships (list + detail + post, external apply, seeder)
- [x] Communities & Channels (channels list + real-time chat + create, seeder)
- [x] Marketplace (grid + detail + create with Firebase Storage uploads, seeder, WhatsApp contact)

**Security:**
- [x] Storage rules deployed (auth-gate, 2026-04-20)
- [ ] Firestore rules still permissive — Phase 4
- [ ] Strict path-scoped Storage rules — Phase 4

## AllyBot Current State (unchanged since migration)

- Chat UI, Firestore session storage, rate limiting, HTTP plumbing — all done
- ⚠ `cloudFunctionsBaseUrl` in `app_constants.dart:55` is wrong (Netlify vs Firebase)
- Backend is ChatPDF (PDF Q&A only) — insufficient for new AI features
- Plan: Phase 4 swap to `aiServiceProvider.chatAboutPdf()` → Gemini
