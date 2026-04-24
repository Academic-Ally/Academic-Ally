# Academic Ally

## What Is This?

Academic Ally is a resources platform (notes, question papers, question banks, syllabi) for B.E/B.Tech engineering students at **Osmania University (OU)** and **JNTUH** in Hyderabad, Telangana. The app was published on Google Play Store, went dormant, and has been **fully migrated from React Native to Flutter** — and **expanded into an AI-native education platform** for a major project submission (two cofounders).

---

## Repository Structure

```
Academic Ally/                            # Workspace root (container — NOT a project root)
├── academic_ally/                        # 🟢 ACTIVE PROJECT — Flutter mobile app + Python AI backend
│   ├── android/app/google-services.json  # Firebase Android config
│   ├── lib/                              # Dart source
│   ├── assets/                           # Images, lottie
│   ├── docs/                             # Context docs (this + ARCHITECTURE, FIRESTORE_SCHEMA, etc.)
│   ├── firebase.json                     # Firebase CLI config (multi-codebase)
│   ├── firestore.rules                   # Deployed Firestore rules
│   ├── storage.rules                     # Deployed Storage rules (auth-gated)
│   ├── functions/                        # Firebase Cloud Functions — Node.js (billing cap)
│   ├── functions_py/                     # Firebase Cloud Functions — Python (AI backend)
│   │   ├── main.py                       # Entry point — exports HTTPS + scheduled funcs
│   │   ├── shared/                       # Cross-feature helpers (LLM, auth, cache, progress, Tavily)
│   │   ├── features/pyq_analyzer/        # PYQ Analyzer multi-agent crew (schema, agents, tasks, crew, handler)
│   │   ├── features/maintenance/         # Scheduled cleanup jobs
│   │   ├── tests/                        # pytest suite (21 tests, all green)
│   │   └── requirements.txt              # crewai[litellm,google-genai]==1.14.3 + firebase-admin + tavily
│   └── pubspec.yaml
├── Academic-Ally-master/                 # React Native app (DORMANT — reference only)
├── academic-ally-web-main/               # React web app (DORMANT — reference only, live at academic-ally.netlify.app)
└── academic-ally-cloud-functions-main/   # Netlify serverless functions (Chat + Notifications)
```

**CRITICAL:** Workspace root is a container holding 4 sibling folders. The **only active project** is `academic_ally/`. Never place new project files at workspace root.

---

## 🟢 Current Git State (as of 2026-04-25)

```
* master                           = latest Phase 4b work (PYQ Analyzer multi-agent backend LIVE)
  session-2026-04-19-backup        = historical work backup (superseded)
  remotes/origin/flutter           = user's designated push target
  remotes/origin/master            = hands-off per user rule (never push here)
```

### Commit log (most recent last)

```
--- Phase 0 baseline ---
deab485  initial Flutter migration (15 screens, working baseline)
6b59da8  Firebase billing hard-cap Cloud Function
1e57b22  docs: restore context docs from backup branch
--- Phase 1 ---
21ef538  onboarding (4 slides + Skip button)
6e8e9ef  report abuse bottom sheet
aabb793  deep linking (app_links + custom scheme + universal links)
a132cd8  FCM push notifications (with 3-layer idempotency fix)
--- Phase 2 ---
6e5d2f6  AI service abstraction (foundation)
0edc0bb  Misconception Graph / Knowledge Map
bdc7f1e  Study Planner
2dbde35  Gen UI
ec61dba  PYQ Analyzer (UI on mocks)
0d693f4  Snap-a-Doubt
42d5f77  Project Copilot
--- Security + Phase 3 ---
097c10e  auth-gated Storage rules (DEPLOYED)
f150e81  Jobs & Internships
08d877c  Communities & Channels
1dfb98c  Marketplace
--- Phase 4b — PYQ Analyzer real AI backend ---
199238e  docs(spec): Python+CrewAI multi-agent architecture
9c1b545  docs(plan): Phase 4 PYQ Analyzer implementation plan
32beae5  scaffold Python Firebase Functions codebase
01b96e8  ignore .env to prevent secret leaks
72815a3  bump crewai 0.98 → 1.14.3 (httpx conflict resolution)
f857102  bump langchain-openai to 1.x, loosen pins
f7c91fe  register functions_py as 'ai' codebase
6e5f260  typed error hierarchy + user-facing mapping
8674d31  Firebase ID token verifier
ebfa10c  Minimax LLM config (later replaced by Gemini)
3b878fd  Tavily web search as a CrewAI tool
6e8aa84  Firestore cache helpers (24h)
6f4605b  AnalysisRuns progress tracker + step callback
3b9ee37  reusable hierarchical Crew factory
75706d8  pytest conftest for import path
b8085e0  Pydantic schemas for PYQ request/response
5b15aab  5 PYQ specialist agents (Syllabus, Web, Pattern, Predictor, Formatter)
ddc068d  5 chained PYQ tasks (context pipeline)
13e9465  run_pyq_analysis crew entry point
66ccaec  HTTP handler for POST /pyq_analyze
f81d2f9  hourly cleanup for AnalysisRuns
3630973  main.py entry point
f1a9315  aiBackendBaseUrl constant (Flutter)
dd6a200  AgentAIService implementing AIService (Flutter)
75bd01e  swap aiServiceProvider to AgentAIService
e293da1  AnalysisRun stream provider (Flutter)
1663bb6  expose runId during analysis (PyqRunState)
cb0dffc  progressive agent-checkmark UI
9ffe7e6  local smoke test script
188baa8  litellm extra for non-native LLM providers
2a1c46e  swap LLM provider Minimax → Google Gemini
aca889a  declare LLM_MODEL as function secret
11a3b96  rewrite imports (drop functions_py. prefix for Firebase runtime)
f150e8f  deploy fixes (LOCALAPPDATA shim, .env ignore, crewai telemetry)
64aa027  Firestore rules covering all 4 phases' collections (DEPLOYED)
8ae6eb6  AgentAIService delegates non-PYQ methods to MockAIService
d0a29d3  surface run errors in UI instead of silent reset
81deec5  OOM fix + lazy imports (memory=False, GB_1, lazy import)
+[debug]  temporary debug fields in error response (to be reverted post-demo)
```

**Status:** All 24 features ship. **PYQ Analyzer now runs on a real multi-agent Gemini backend.** Other 5 AI features + AllyBot still use `MockAIService` canned responses (via `AgentAIService` → `MockAIService` delegation). Phase 3 community features (Jobs, Channels, Marketplace) have live Firestore rules for the first time (previously silently blocked).

---

## Feature Inventory (24 total)

### Phase 0 — Core Platform (15 features, pre-existing migration)
1. Splash screen
2. Login / Signup / Forgot Password
3. Home screen (with AI Tools + Explore sections)
4. Search with filters
5. Subject resources browser
6. Resources list (Notes / QuestionPapers / Syllabus / Other)
7. PDF viewer (download / bookmark / rate / share / AllyBot / report)
8. Bookmarks
9. Recents
10. Downloads
11. Upload (community contribution queue)
12. SeekHub (resource request board)
13. AllyBot (PDF chat — still on mocks via AgentAIService → MockAIService)
14. Profile + update profile

### Phase 1 — Infrastructure (4 features)
15. Onboarding (4-slide intro, first-launch only)
16. Report abuse (bottom sheet → `userReports`)
17. Deep linking (`app_links` custom scheme + universal links)
18. FCM push notifications (token + topic lifecycle, 3-layer idempotency fix)

### Phase 2 — AI Features (6 features + foundation)
- **AI Foundation:** `AIService` interface + `MockAIService` + `AgentAIService` (Phase 4b) + `aiServiceProvider` single swap point + typed models in `ai_models.dart`
19. Knowledge Map / Misconception Graph (mocks)
20. Study Planner (mocks)
21. Gen UI (mocks)
22. **PYQ Analyzer — LIVE on real Gemini multi-agent backend** ✨
23. Snap-a-Doubt (mocks)
24. Project Copilot (mocks)

### Phase 3 — Community Features (3 features)
25. Jobs & Internships
26. Communities & Channels (real-time chat)
27. Marketplace (Firebase Storage image uploads + WhatsApp contact)

---

## Phase 4b — Multi-Agent AI Backend (PYQ Analyzer, LIVE)

### Architecture

```
Flutter app
  ↓ POST {aiBackendBaseUrl}/pyq_analyze   + Firebase ID token
  ↓ { run_id, university, course, branch, sem, subject, pyq_resource_ids, force_refresh }
  │
Firebase Cloud Function (Python 3.12, Gen 2, us-central1, 1GB RAM, 540s timeout)
  ↓
CrewAI Hierarchical Process (Manager + 5 workers)
  ├─ Syllabus Researcher  [Tavily + Gemini knowledge]
  ├─ Web Researcher       [Tavily]
  ├─ Pattern Analyst      [reasoning only, context from 1+2]
  ├─ Question Predictor   [reasoning only, context from 1+2+3]
  └─ Output Formatter     [Pydantic-validated JSON, context from 3+4]
  ↓
writes AnalysisRuns/{runId}  ← streamed live to Flutter for progress UI
writes PyqAnalysis/{uni}/{course}/{branch}/{sem}/{subject}  ← 24h cache
  ↓
returns JSON to Flutter → rendered as topic weights + predicted questions
```

### Key facts

- **LLM:** Google Gemini 2.5 Flash Lite (via litellm routing; configurable via `LLM_MODEL` Firebase Secret without redeploy)
- **Web search:** Tavily (free tier 1000 searches/month)
- **API keys:** stored in Firebase Secret Manager — `GEMINI_API_KEY`, `TAVILY_API_KEY`, `LLM_MODEL`
- **Endpoint:** `https://us-central1-academic-ally-app.cloudfunctions.net/pyq_analyze`
- **Auth:** Firebase ID token required (401 if missing/invalid)
- **Cache:** 24h freshness at `PyqAnalysis/{path}` — instant replay for repeat requests
- **Progress tracker:** `AnalysisRuns/{runId}` Firestore doc streams live to Flutter UI; deleted hourly by scheduled cleanup function
- **Cost:** ~$0.01–0.02 per analysis on paid tier; 200/day free-tier quota on 2.5-flash-lite

### Multi-agent narrative (for presentation)

The 5-agent hierarchical crew is the submission's "multi-agent AI" headline. Each agent has a distinct role, goal, and backstory grounding it in Indian engineering exam culture. The manager agent (auto-provisioned by `Process.hierarchical`) orchestrates delegation. Output Formatter's final task uses `output_pydantic=PyqAnalysisOutput` so CrewAI validates the JSON shape automatically. This is real agentic AI, not a single-prompt LLM call dressed up.

---

## Storage Architecture

### PDF Storage — Cloudflare R2 (planned, still not wired)

- PDFs will be stored at R2 path: `Universities/{university}/{course}/{branch}/{sem}/{subject}/{category}/{filename}.pdf`
- `R2StorageService` scaffolded at `lib/core/services/r2_storage_service.dart`. `publicBaseUrl` still empty.
- `PdfViewerScreen` reads through `R2StorageService` — filling `publicBaseUrl` lights it up.

### Firebase Storage — Active (Marketplace images only)

- Deployed rules: `allow read, write: if request.auth != null`
- Path: `Marketplace/{listingId}/{i}.jpg`

---

## Tech Stack (current, accurate)

| Layer | Choice |
|-------|--------|
| State management | Riverpod 3.x (Notifier pattern) |
| Navigation | GoRouter (declarative, deep-link ready) |
| Design system | Material Design 3 (brand: #6360FF primary, #FF8181 tertiary, #F1F1FA secondary) |
| Font | Poppins (via google_fonts) |
| PDF storage | Cloudflare R2 (planned — scaffolding in place, not filled) |
| PDF viewing | `flutter_pdfview` (placeholder until R2 wired) |
| Image uploads | Firebase Storage (auth-gated, Marketplace) |
| Image picker | `image_picker` |
| Deep linking | `app_links` (custom scheme + universal links) |
| **AI (PYQ Analyzer)** | **CrewAI 1.14.3 hierarchical crew, 5 agents, Gemini 2.5 Flash Lite via litellm** |
| **AI (other 5 features + AllyBot)** | `MockAIService` canned responses via `AgentAIService` fallback delegation |
| Web search (agents) | Tavily API |
| Backend (Node.js) | Firebase Functions — `stopBilling` (billing cap) |
| Backend (Python) | Firebase Functions Gen 2 — `pyq_analyze`, `cleanup_old_trackers` |

**Firebase project:** `academic-ally-app` · **Plan:** Blaze (pay-as-you-go) · **Billing cap:** ₹200/month auto-disable via `stopBilling` function (Firebase only; Gemini costs separate, uncapped)

---

## Firestore Schema — 29 Collections

### Pre-existing (from migration, rules already in place)
- `Users/{uid}` + subcollections (NotesBookmarked, RatedList, UserUploads, InitializedPdf, SeekHub/Requests)
- `Universities/{university}/{course}/{branch}/{sem}/{resourceType}/{subject}/{docId}`
- `QueryList/{university}/{course}/SubjectsListDetail`
- `SeekHub/{university}/{course}/{requestId}`
- `NewUploads/{university}/{course}/{branch}/uploads/{docId}`
- `userReports/{university}/{course}/{branch}/{sem}/{uid}`
- `ImmutableUserData/{uid}`
- `Premium_Users/{userId}` (rule added 2026-04-25, previously silently broken)
- `utils/meta-data`, `UtilsProtected/meta-data`

### Phase 2 AI (per-user state)
- `Users/{uid}/Misconceptions/{nodeId}` — covered by Users/** wildcard
- `Users/{uid}/MasteryScores/{nodeId}`
- `Users/{uid}/StudyPlans/{planId}`
- `Users/{uid}/DoubtHistory/{doubtId}`
- `Users/{uid}/Projects/{projectId}`
- `PyqAnalysis/{uni}/{course}/{branch}/{sem}/{subject}` — rule added 2026-04-25
- `KnowledgeGraph/{uni}/{course}/{subject}/nodes/{nodeId}` — rule added 2026-04-25

### Phase 3 community
- `Jobs/{jobId}` — rule added 2026-04-25
- `Channels/{channelId}` + `Channels/{channelId}/Messages/{msgId}` — rule added 2026-04-25
- `Marketplace/{listingId}` — rule added 2026-04-25

### Phase 4b multi-agent
- `AnalysisRuns/{runId}` — ephemeral per-run progress tracker, deleted hourly by `cleanup_old_trackers`

All paths defined in `lib/core/constants/firestore_paths.dart`. Full schema in `docs/FIRESTORE_SCHEMA.md`.

---

## Critical Gotchas (memorize these)

1. **Workspace ≠ project root.** All new files go inside `academic_ally/`. Never pollute workspace root.

2. **Firestore rules deployed (2026-04-25).** No catch-all; every collection with a write block has an explicit `auth != null` rule. Phase 4 strict rules (per-user ownership, admin checks) still pending — fine for close-circle demo.

3. **`ImmutableUserData` helper functions in live rules are BROKEN** — `{document}` in function body is literal text, not a variable binding, so admin writes always evaluate false. Low priority; no admin writes happen from client anyway.

4. **Admin system uses Firestore-doc claims**, not Firebase Auth token claims. `ImmutableUserData/{uid}.customClaims.admin` is the source of truth. Phase 4 needs a Custom Claims Cloud Function to repair this.

5. **Known admin UID:** `8056itcLayZY8yDbNdi7KbqXnsw2` (cofounder).

6. **Cloud Functions URL is partially wrong.** `lib/core/constants/app_constants.dart` `cloudFunctionsBaseUrl` points at the Firebase Functions URL (correct for stopBilling and future AI functions) but the actual **AllyBot backend is Netlify** at `academic-ally.netlify.app`. Fix when Phase 4b ports AllyBot.

7. **AllyBot uses ChatPDF** (PDF Q&A only), not a general LLM. Currently still routed through `AgentAIService.chatAboutPdf` → delegates to `MockAIService`. When we port AllyBot's backend, update `AgentAIService` to call the real endpoint.

8. **QueryList `list` items use `subjectName`** (capital N), not `subject`. `SubjectModel.fromMap` reads `subjectName` as primary with `subject` fallback. Never regress this.

9. **Legacy `sem` can be int or string.** Always `.toString()` when parsing from Firestore.

10. **FCM topic names don't allow spaces.** Branches like "CSE AIML" need sanitization. `FcmService.buildTopic()` regex-replaces non-allowed chars with hyphen.

11. **FCM infinite-loop bug pattern** — 3-layer idempotency fix landed (listener guard + service-level token check + fast-path in `syncTopicsForProfile()`). See `lib/core/services/fcm_service.dart` + `lib/core/providers/fcm_provider.dart`.

12. **Custom domain `getacademically.co` EXPIRED.** Live web app is at `https://academic-ally.netlify.app/`. Don't hardcode the expired domain. Firebase Auth email templates were silently broken because of this — fixed 2026-04-25 by reverting to default `noreply@academic-ally-app.firebaseapp.com` sender for all 3 email templates.

13. **User handles APK builds manually.** Do NOT run `flutter build apk` commands — tell them the command + output path.

14. **User push-to-remote rule:** Never push to `origin/master` on GitHub. All remote pushes must target the `flutter` branch.

15. **User prefers commit messages WITHOUT a `Co-Authored-By: Claude` trailer.** All new commits should be clean subject + body only.

16. **Release-grade quality bar.** User is vibe-coding; Claude owns security, error handling, UX polish, proactive risk flagging.

17. **Always add timeouts + error surfacing** on Firestore reads. Infinite spinners = untestable app. Use `.timeout(Duration(seconds: 10))` pattern, surface the error message to the UI. PYQ screen `_runFailed` widget is the canonical pattern.

18. **Home screen has 3 sections:** Quick Access (icons row) → AI Tools (6 cards, horizontal scroll) → Explore (3 cards, horizontal scroll) → Recommended.

19. **Blaze billing cap is active.** `stopBilling` function auto-disables billing if monthly Firebase spend exceeds ₹200. **Gemini costs are billed separately via Google Cloud and are NOT capped by this function.** Monitor manually or enable a separate budget alert on the Google Cloud project.

20. **Storage + Firestore rules deployed (2026-04-25).** `firestore.rules` + `storage.rules` files committed. Deploy via `firebase deploy --only firestore:rules` / `--only storage` from inside `academic_ally/`.

21. **Firebase CLI loads `functions_py/.env` automatically and passes its keys as non-secret env vars, conflicting with the `secrets=[...]` declaration.** Workaround on every Python deploy: `mv functions_py/.env functions_py/.env.local` before deploying, restore after. A pre-deploy script would be cleaner.

22. **CrewAI 1.x eagerly instantiates EventListener at import time.** Its TokenManager tries to read a secure file at a path derived from `LOCALAPPDATA` (Win) / `HOME` (Linux); in Firebase's deploy analyzer these may be missing → `Path(None)` crash. Shim at the top of `functions_py/main.py` sets both to `tempfile.gettempdir()` + `CREWAI_TRACING_ENABLED=false`. Keep the shim — it's also defense-in-depth for cold starts.

23. **Firebase analyzer has a 10s timeout loading main.py.** Importing `crewai` + deps takes longer → analyzer times out. Workaround: lazy-import the handler inside the function body (already done in `main.py`). Do not hoist back to module-level.

24. **Cloud Run default 512MB is too small for CrewAI + ChromaDB.** Function memory bumped to 1GB. Also `memory=False` in crew factory (ChromaDB was default; we don't need agent long-term memory for one-shot analysis). Keep both.

25. **Gemini free-tier 200 requests/day per model per project.** One PYQ run = ~15–25 Gemini calls → can hit the cap in 8–15 test runs. If hit: wait for midnight Pacific reset, swap `LLM_MODEL` Firebase Secret to another model (gemini-2.5-flash / gemini-2.0-flash-lite each have separate buckets), or enable billing on the Google Cloud project (~$0.01–0.02/run, no cap).

26. **`functions_py/` uses bare imports (no `functions_py.` prefix).** Firebase's Python runtime puts `functions_py/` itself on `sys.path`, so `from shared.X` resolves but `from functions_py.shared.X` fails. Tests have `conftest.py` that puts `functions_py/` on `sys.path` the same way. Don't reintroduce the `functions_py.` prefix.

---

## Quick Reference

- **Firebase project:** `academic-ally-app` (Blaze plan, ₹200/month Firebase cap — Gemini separate)
- **Primary brand color:** `#6360FF` · Tertiary: `#FF8181` · Secondary: `#F1F1FA`
- **Font:** Poppins
- **Support email:** `support@getacademically.co` (domain EXPIRED — update when renewed)
- **Web app (live):** `https://academic-ally.netlify.app/`
- **Play Store listing:** `https://play.google.com/store/apps/details?id=com.academically`
- **Legacy deep link schemes:** `academically://` (works), `https://getacademically.co/` (domain expired), `https://app.getacademically.co/` (domain expired)
- **FCM topic format:** `{university}_{course}_{branch}_{sem}` — sanitize to `[a-zA-Z0-9-_.~%]`
- **APK output path (after `flutter build apk --release`):** `academic_ally/build/app/outputs/flutter-apk/app-release.apk`
- **AI backend endpoint:** `https://us-central1-academic-ally-app.cloudfunctions.net/pyq_analyze` (POST, auth required)
- **AKRAM.md:** non-technical cofounder's presentation reference at `academic_ally/AKRAM.md`

---

## Phase 4 — What's Still Left

Phase 4b landed the PYQ Analyzer backend. The remaining endgame:

1. **Cloudflare R2** for PDFs (`publicBaseUrl`, bucket setup, PDF upload, resource `storageId` update)
2. **Port remaining 5 AI features' backends** — Knowledge Map, Study Planner, Gen UI, Snap-a-Doubt, Project Copilot — each gets its own CrewAI crew in `functions_py/features/*/`. Reuse the pattern from `pyq_analyzer/`.
3. **Port AllyBot** (PDF chat) through the same backend; remove Netlify legacy path; fix `cloudFunctionsBaseUrl`.
4. **Strict Firestore rules** — per-user ownership on `Users/{uid}/*`, admin writes gated, no catch-all reads on other users' private data. Depends on Custom Claims Cloud Function.
5. **Set up Firebase Custom Claims Cloud Function** for admin role.
6. **Deploy composite indexes** (Channels messages, Marketplace, Jobs, all Users subcollections ordered by createdAt).
7. **Storage rules hardening** (path-scoped, MIME validation, size limits).
8. **LaTeX rendering** for Snap-a-Doubt (nice-to-have).
9. **Automated tests** — Python side has 21 (green); Dart side still zero. Start with FCM idempotency, deep-link parsing, topic sanitization, mastery EMA.
10. **Revert the `debug_error` / `debug_traceback` fields** in `features/pyq_analyzer/handler.py` before a public release — currently temporarily leaked for debugging.
11. **Pre-deploy script** for Python codebase to auto-handle the `.env` rename dance.

---

## Session Context Pointer

Historical session journal (what was tried + what was learned on 2026-04-19 before the current revival) lives in memory at:
`C:\Users\moham\.claude\projects\C--Devspace-flutterprojects-Academic-Ally\memory\project_session_2026-04-19.md`

User preferences and hard-won lessons in the `feedback_*` memory files (see `MEMORY.md` index).
