# Academic Ally

## What Is This?

Academic Ally is a resources platform (notes, question papers, question banks, syllabi) for B.E/B.Tech engineering students at **Osmania University (OU)** and **JNTUH** in Hyderabad, Telangana. The app was published on Google Play Store, went dormant, and has been **fully migrated from React Native to Flutter** — and **expanded into an AI-native education platform** with 5 multi-agent AI features (4 multi-agent crews + AllyBot RAG chat) for a major project submission (two cofounders).

---

## Repository Structure

```
Academic Ally/                            # Workspace root (container — NOT a project root)
├── academic_ally/                        # 🟢 ACTIVE PROJECT — Flutter app + local Python AI backend
│   ├── android/app/google-services.json  # Firebase Android config
│   ├── ios/                              # iOS config (Podfile, GoogleService-Info.plist) — added 2026-04-26
│   ├── lib/                              # Dart source
│   ├── assets/                           # Images, lottie
│   ├── docs/                             # Context docs (ARCHITECTURE, FIRESTORE_SCHEMA, etc.)
│   ├── AA DEMO/                          # Major-project presentation prep (5 member scripts + PPTPROMPT)
│   ├── backend/                          # 🟢 ACTIVE — FastAPI local Python service (uv-managed)
│   │   ├── app/main.py                   # FastAPI entry — /health + 5 feature routers
│   │   ├── app/shared/llm.py             # CrewAI LLM wrapper (Gemini via litellm)
│   │   ├── app/shared/rag/               # PDF chunker, embedder (gemini-embedding-001), Firestore Vector Search wrapper
│   │   ├── app/features/pyq_analyzer/    # 5-agent PYQ crew (RAG-grounded)
│   │   ├── app/features/study_planner/   # 4-agent personalized plan generator
│   │   ├── app/features/adversarial_examiner/  # 4-agent trap-question crew (generator-critic pattern)
│   │   ├── app/features/snap_doubt/      # Gemini Vision pre-step + 4-agent solver crew with ID-based citations
│   │   ├── app/features/chat_about_pdf/  # AllyBot rewrite — single Gemini call + RAG with resource_id_filter
│   │   ├── scripts/upload_pdfs.py        # Idempotent local PDF tree → Firebase Storage + Firestore ingestion
│   │   ├── pyproject.toml                # crewai 1.14.3 + fastapi + firebase-admin + tavily
│   │   └── run.sh                        # ./run.sh launches uv-synced uvicorn on :8000
│   ├── firebase.json                     # Firebase CLI config (multi-codebase)
│   ├── firestore.rules                   # Deployed Firestore rules
│   ├── storage.rules                     # Deployed Storage rules (auth-gated)
│   ├── functions/                        # Firebase Cloud Functions — Node.js (billing cap only)
│   ├── functions_py/                     # ⚠️ LEGACY — Python Cloud Function (only PYQ deployed; Flutter no longer points here)
│   └── pubspec.yaml
├── Academic-Ally-master/                 # React Native app (DORMANT — reference only)
├── academic-ally-web-main/               # React web app (DORMANT — reference, live at academic-ally.netlify.app)
└── academic-ally-cloud-functions-main/   # Old Netlify functions (DORMANT — AllyBot legacy, replaced by backend/chat_about_pdf)
```

**CRITICAL:** Workspace root is a container holding 4 sibling folders. The **only active project** is `academic_ally/`. Never place new project files at workspace root.

---

## 🟢 Current Git State (as of 2026-04-26)

```
* flutter                          = ACTIVE branch — all current work pushed here, matches origin/flutter
  master                           = local-only, behind flutter (do not push to GitHub master)
  session-2026-04-19-backup        = historical work backup (superseded)
  remotes/origin/flutter           = user's designated push target (matches local exactly)
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

--- Phase 2 (mocks) ---
6e5d2f6  AI service abstraction (foundation)
0edc0bb  Misconception Graph / Knowledge Map (mock UI)
bdc7f1e  Study Planner (mock UI)
2dbde35  Gen UI (mock UI)
ec61dba  PYQ Analyzer (mock UI)
0d693f4  Snap-a-Doubt (mock UI)
42d5f77  Project Copilot (mock UI)

--- Security + Phase 3 ---
097c10e  auth-gated Storage rules (DEPLOYED)
f150e81  Jobs & Internships
08d877c  Communities & Channels
1dfb98c  Marketplace

--- Phase 4b — PYQ Analyzer real backend (functions_py/) ---
... [many commits scaffolding functions_py/, agents, tasks, deploy fixes] ...
4170c65  docs: Phase 4b complete — multi-agent PYQ backend shipped

--- Phase 4c — Local FastAPI agentic RAG platform (backend/) ---
4f7ed09  feat: agentic RAG platform — 5 multi-agent features grounded in real PDFs
         (added backend/, RAG infra, 5 feature crews, Snap a Doubt + Vision,
          AllyBot rewrite via /chat_about_pdf, PDF viewer using Firebase Storage
          downloadURL, R2 dropped, iOS support, Adversarial Examiner as new feature)
016a3d7  Merge PR #3 — agentic-rag-platform → flutter

--- Today (2026-04-26) ---
9c89f61  chore: deps update + AI backend URL switched to 10.0.2.2 (Android emulator)
         + UI cleanup (hide Knowledge Map / Gen UI / Project Copilot from home,
         rename Explore → Coming Soon...) + AA DEMO presentation prep folder
```

**Status:** All 28 features ship in code. **5 AI backends live on local FastAPI:** PYQ Analyzer (5 agents), Study Planner (4 agents), Adversarial Examiner (4 agents, generator-critic), Snap a Doubt (Gemini Vision + 4 agents), AllyBot (single LLM call + RAG with resource_id_filter). 3 AI features still on mocks but **hidden from the home screen UI**: Knowledge Map, Gen UI, Project Copilot. Phase 3 community features (Jobs, Channels, Marketplace) shown as "Coming Soon" — code wired, Firestore rules deployed.

---

## Feature Inventory (28 total)

### Phase 0 — Core Platform (14 features)
1. Splash screen
2. Login / Signup / Forgot Password
3. Home screen (Quick Access + AI Tools + Coming Soon + Recommended)
4. Search with filters
5. Subject resources browser
6. Resources list (Notes / QuestionPapers / QuestionBanks / Syllabus)
7. PDF viewer (Firebase Storage downloadURL + flutter_pdfview, supports initialPage from Snap a Doubt citations)
8. Bookmarks
9. Recents
10. Downloads
11. Upload (community contribution queue)
12. SeekHub (resource request board)
13. **AllyBot — LIVE** (single Gemini call + RAG with `resource_id_filter`, scoped per PDF)
14. Profile + update profile

### Phase 1 — Infrastructure (4 features)
15. Onboarding (4-slide intro)
16. Report abuse bottom sheet → `userReports`
17. Deep linking (`app_links` custom scheme + universal links)
18. FCM push notifications (3-layer idempotency fix)

### Phase 2 — AI Features (6 features + foundation)
- **AI Foundation:** `AIService` interface + `MockAIService` + `AgentAIService` (real backend) + `aiServiceProvider` swap point
19. Knowledge Map / Misconception Graph — *mocks, hidden from home UI*
20. **Study Planner — LIVE** on real backend (4-agent crew)
21. Gen UI — *mocks, hidden from home UI*
22. **PYQ Analyzer — LIVE** ⭐ (5-agent flagship)
23. **Snap a Doubt — LIVE** (Gemini Vision + 4-agent crew, clickable PDF citations)
24. Project Copilot — *mocks, hidden from home UI*

### Phase 3 — Community Features (3 features, marked "Coming Soon")
25. Jobs & Internships (rules deployed)
26. Communities & Channels (real-time chat, rules deployed)
27. Marketplace (Firebase Storage image uploads + WhatsApp contact, rules deployed)

### Phase 4c — New AI Feature
28. **Adversarial Examiner — LIVE** (4-agent crew with Verifier critic, generator-critic pattern, mastery-score feedback loop)

---

## AI Backend Architecture (LIVE — local FastAPI)

### Flow

```
Flutter app (Android emulator)
  ↓ HTTPS POST  http://10.0.2.2:8000/{endpoint}  + Authorization: Bearer <Firebase ID token>
  │
FastAPI (Python 3.12, uv-managed, uvicorn :8000, bound to 127.0.0.1)
  │
  ├─ /pyq_analyze              5-agent crew — Syllabus, Web, Pattern, Predictor, Formatter
  ├─ /generate_study_plan      4-agent crew — Subject, Strategy, Schedule, Formatter
  ├─ /generate_adversarial_exam 4-agent crew — Topic, Trap Designer, Verifier, Formatter
  ├─ /solve_doubt              Gemini Vision pre-step + 4-agent crew — Topic, Solver, Citation, Formatter
  └─ /chat_about_pdf           Single Gemini call + RAG (no crew), scoped per PDF via resource_id_filter
  
Each crew uses CrewAI hierarchical process with shared tools:
  - RagSearchTool → Firestore Vector Search RagChunks/{subject_key}/chunks (cosine similarity, top-K)
  - TavilySearchTool → live web search
  
Live progress streamed via writes to Firestore AnalysisRuns/{runId} (Flutter app subscribes via real-time listener).
PYQ has a 24h cache at PyqAnalysis/{uni}/{course}/{branch}/{sem}/{subject}.
```

### Key facts

- **LLM:** Google Gemini 2.5 Flash Lite via litellm (configurable via `LLM_MODEL` env var without restart)
- **Embeddings:** `gemini-embedding-001` @ 768d (RETRIEVAL_DOCUMENT for ingestion, RETRIEVAL_QUERY at retrieval)
- **Vector store:** Firestore Vector Search at `RagChunks/{subject_key}/chunks/{chunkId}` where `subject_key = {uni}_{course}_{branch}_{sem}_{subject}`
- **Chunking:** 800-char chunks with 100-char overlap, page numbers attached at ingestion
- **Web search:** Tavily (free tier 1000 searches/month)
- **Auth — two schemes:**
  - `Authorization: Bearer <id_token>` — Firebase ID token (Flutter app)
  - `Authorization: Admin <BACKEND_ADMIN_KEY>:<uid>` — admin bypass for curl/dev
- **Env (in `backend/.env`):** `GEMINI_API_KEY`, `TAVILY_API_KEY`, `BACKEND_ADMIN_KEY`, `GOOGLE_APPLICATION_CREDENTIALS` (path to Firebase service-account JSON), `LLM_MODEL`
- **Bind:** `127.0.0.1:8000` — Android emulator reaches it via `10.0.2.2:8000` (NAT alias)
- **Cost:** ~₹2 per cold-start AI run (Gemini + Tavily); cache hits free

### How to run

```bash
cd academic_ally/backend
./run.sh    # uv sync (cached after first run) + uvicorn --reload --port 8000
```

`uv` must be installed: `pip install --user uv` puts it at `%APPDATA%\Python\Python312\Scripts\uv.exe` on Windows. Ensure that dir is on PATH or run.sh will fail with "uv: command not found."

`/health` endpoint returns config status (which env vars populated, model name, Firebase init state) without auth.

---

## Storage Architecture

### PDF Storage — Firebase Storage (R2 abandoned)

- **Bucket layout has TWO prefixes** (verified 2026-04-26 against the live bucket — total ~152 blobs / ~236 MB):
  - `Resources/{uni}/{course}/{branch}/{sem}/{type}/{subject}/{filename}.pdf` — the **curriculum PDFs** (~132 files). `type` = `Notes` / `OtherResources` / `QuestionPapers` / `Syllabus`. Subject and sem are part of the path. This is the path Firestore docs reference via the `storageId` field.
  - `Universities/{uni}/{course}/{branch}/{randomId}` — only ~20 blobs, no extension, no sem/subject in path. Likely outputs of the in-app Upload feature (community contributions).
- The Firestore tree is rooted at `Universities/`; the Storage tree for curriculum PDFs is rooted at `Resources/`. **Don't conflate them** — they share top-level naming with the Firestore tree but the prefixes are different.
- The `storageId` field on a Firestore resource doc is the **complete bucket-relative path** (e.g. `Resources/OU/BE/IT/2/Notes/English/Unit II Notes.pdf`). The Flutter app does `FirebaseStorage.instance.ref(storageId).getDownloadURL()` — see `pdf_viewer_screen.dart:138`. Treat it as a full path; never split-and-basename it.
- App streams the resolved download URL into `flutter_pdfview`.
- Initial-page jump supported (used by Snap a Doubt citations).
- Auto-download in background on first view; subsequent opens are instant via local cache.
- Many legacy Firestore docs (Phase 0 RN era) have **no `storageId` field** — the resource provider filters those out via `.where((r) => r.storageId != null && r.storageId!.isNotEmpty)`, so they don't appear in the UI.
- `R2StorageService` scaffolding still in `lib/core/services/r2_storage_service.dart` but **not used** — `publicBaseUrl` empty, code path dead. Future work could wire R2 if Firebase Storage costs become an issue.

### Doubt Photos — Firebase Storage (auth-gated, owner-only)

- Path: `Doubts/{uid}/{doubtId}.jpg`
- Storage rules require auth and that the path's `{uid}` matches `request.auth.uid`
- Backend downloads via `firebase-admin` Storage and discards local copy after Vision processing

### Marketplace Images — Firebase Storage (auth-gated)

- Path: `Marketplace/{listingId}/{i}.jpg`
- Rules: `allow read, write: if request.auth != null`

---

## Tech Stack (current, accurate)

| Layer | Choice |
|-------|--------|
| State management | Riverpod 3.x (Notifier pattern) |
| Navigation | GoRouter (declarative, deep-link ready) |
| Design system | Material Design 3 (brand: #6360FF primary, #FF8181 tertiary, #F1F1FA secondary) |
| Font | Poppins (via google_fonts) |
| PDF storage | **Firebase Storage** (downloadURL streamed via `flutter_pdfview`) |
| PDF viewing | `flutter_pdfview` |
| Image uploads | Firebase Storage (auth-gated, Marketplace + Doubts) |
| Image picker | `image_picker` |
| Deep linking | `app_links` (custom scheme + universal links) |
| **AI Backend** | **FastAPI 0.115+ (Python 3.12) on `localhost:8000`, uv-managed** |
| **Multi-Agent Framework** | **CrewAI 1.14.3** (hierarchical process, async kickoff) |
| **LLM** | **Google Gemini 2.5 Flash Lite** via litellm (`LLM_MODEL` env var swappable to GPT/Claude/etc.) |
| **Embeddings** | **gemini-embedding-001 @ 768d** |
| **Vector Store** | **Firestore Vector Search** (`RagChunks/{subject_key}/chunks`) |
| Web search (agents) | Tavily API (1000 free searches/month) |
| Backend (Node.js) | Firebase Functions — `stopBilling` (billing cap only) |
| Backend (Python) — Cloud | Firebase Functions Gen 2 — LEGACY: only `pyq_analyze` deployed, Flutter no longer points here |

**Firebase project:** `academic-ally-app` · **Plan:** Blaze (pay-as-you-go) · **Billing cap:** ₹200/month auto-disable via `stopBilling` function (Firebase only; Gemini costs separate, uncapped)

---

## Firestore Schema

### Pre-existing (from migration)
- `Users/{uid}` + subcollections (NotesBookmarked, RatedList, UserUploads, InitializedPdf, SeekHub/Requests)
- `Universities/{university}/{course}/{branch}/{sem}/{resourceType}/{subject}/{docId}` (PDF metadata)
- `QueryList/{university}/{course}/SubjectsListDetail`
- `SeekHub/{university}/{course}/{requestId}`
- `NewUploads/{university}/{course}/{branch}/uploads/{docId}`
- `userReports/{university}/{course}/{branch}/{sem}/{uid}`
- `ImmutableUserData/{uid}` (admin claims, sensitive identity fields)
- `Premium_Users/{userId}`
- `utils/meta-data`, `UtilsProtected/meta-data`

### Per-user AI state
- `Users/{uid}/Misconceptions/{nodeId}` (covered by Users/** wildcard)
- `Users/{uid}/MasteryScores/{topicId}` — exponential moving average, fed by Adversarial Examiner answers
- `Users/{uid}/StudyPlans/{planId}`
- `Users/{uid}/DoubtHistory/{doubtId}`
- `Users/{uid}/Projects/{projectId}` (Project Copilot — hidden)

### AI shared state
- `PyqAnalysis/{uni}/{course}/{branch}/{sem}/{subject}` — 24h PYQ Analyzer cache
- `KnowledgeGraph/{uni}/{course}/{subject}/nodes/{nodeId}` (Knowledge Map — hidden)
- `AnalysisRuns/{runId}` — ephemeral live progress tracker (deleted hourly by `cleanup_old_trackers` in functions_py)
- `RagChunks/{subject_key}/chunks/{chunkId}` — **vector store**. Each doc has `text`, `page`, `embedding` (768d vector), `pdfName`, `subject`, `university`, `branch`, `sem`, `resourceId`. Requires a Firestore Vector Search index per `subject_key`.

### Phase 3 community
- `Jobs/{jobId}`
- `Channels/{channelId}` + `Channels/{channelId}/Messages/{msgId}`
- `Marketplace/{listingId}`

All paths defined in `lib/core/constants/firestore_paths.dart`. Full schema in `docs/FIRESTORE_SCHEMA.md`.

---

## Critical Gotchas (memorize these)

1. **Workspace ≠ project root.** All new files go inside `academic_ally/`. Never pollute workspace root.

2. **Firestore rules deployed (2026-04-25).** No catch-all; every collection with a write block has an explicit `auth != null` rule. Phase 4 strict rules (per-user ownership, admin checks) still pending — fine for close-circle demo.

3. **`ImmutableUserData` helper functions in live rules are BROKEN** — `{document}` in function body is literal text, not a variable binding, so admin writes always evaluate false. Low priority; no admin writes happen from client anyway.

4. **Admin system uses Firestore-doc claims**, not Firebase Auth token claims. `ImmutableUserData/{uid}.customClaims.admin` is the source of truth. Phase 4 needs a Custom Claims Cloud Function to repair this.

5. **Known admin UID:** `8056itcLayZY8yDbNdi7KbqXnsw2` (cofounder).

6. **AI backend is local-only.** `aiBackendBaseUrl = 'http://10.0.2.2:8000'` in `app_constants.dart`. The backend (`backend/`) runs on the dev machine via `./run.sh`. Android emulator reaches it via `10.0.2.2`. iOS simulator or `flutter run -d windows` needs `localhost:8000`. Physical device on same Wi-Fi needs the host's LAN IP and `--host 0.0.0.0` on uvicorn. Production deployment plan still TBD.

7. **`uv` (Astral) required for backend.** Install: `pip install --user uv` → puts binary at `%APPDATA%\Python\Python312\Scripts\uv.exe` on Windows. Ensure that path is on `PATH` or `./run.sh` fails with "uv: command not found." First `uv sync` takes ~1 minute; subsequent runs cached.

8. **Backend `.env` must contain valid `GOOGLE_APPLICATION_CREDENTIALS`** pointing to a Firebase service-account JSON. Without it, Bearer-token auth and Firestore writes fail. The Admin bypass scheme (`Authorization: Admin <key>:<uid>`) still works for curl.

9. **`functions_py/` is LEGACY.** Only PYQ Analyzer was ever deployed there. The Flutter app no longer points at it (`aiBackendBaseUrl` is now local FastAPI). Keep `functions_py/` around for potential future deploy, but do NOT add new features there — add them to `backend/`.

10. **AllyBot is no longer Netlify.** The old Netlify ChatPDF function in `academic-ally-cloud-functions-main/` (workspace sibling) is DORMANT. Do not edit it. AllyBot now hits `/chat_about_pdf` on the local FastAPI backend.

11. **Home screen has 3 sections:** Quick Access (icon row) → AI Tools (4 cards: Study Planner, PYQ Analyzer, Adversarial Examiner, Snap a Doubt) → **Coming Soon...** (3 cards: Jobs, Communities, Marketplace) → Recommended. Routes for hidden features (`/knowledge-map`, `/gen-ui`, `/project-copilot`) are still wired in `app_router.dart` — only the home tiles are removed. Code is intact for re-enabling.

12. **Adversarial Examiner uses generator-critic pattern.** Trap Designer creates, Verifier rejects bad questions (math errors, ambiguity, unfair traps). Don't merge those into one agent — the separation is what produces quality output.

13. **Firestore Vector Search requires a per-subject_key index.** `RagChunks/{subject_key}/chunks` queries fail until the index is created via Firebase Console or `gcloud`. Manual today; a script to automate this is on the to-do list.

14. **QueryList `list` items use `subjectName`** (capital N), not `subject`. `SubjectModel.fromMap` reads `subjectName` as primary with `subject` fallback. Never regress this.

15. **Legacy `sem` can be int or string.** Always `.toString()` when parsing from Firestore.

16. **FCM topic names don't allow spaces.** Branches like "CSE AIML" need sanitization. `FcmService.buildTopic()` regex-replaces non-allowed chars with hyphen.

17. **FCM infinite-loop bug pattern** — 3-layer idempotency fix landed (listener guard + service-level token check + fast-path in `syncTopicsForProfile()`). See `lib/core/services/fcm_service.dart` + `lib/core/providers/fcm_provider.dart`.

18. **Custom domain `getacademically.co` EXPIRED.** Live web app is at `https://academic-ally.netlify.app/`. Don't hardcode the expired domain. Firebase Auth email templates fixed by reverting to default `noreply@academic-ally-app.firebaseapp.com` sender.

19. **User handles APK builds manually.** Do NOT run `flutter build apk` commands — tell them the command + output path.

20. **User push-to-remote rule:** Never push to `origin/master` on GitHub. All remote pushes must target the `flutter` branch.

21. **User prefers commit messages WITHOUT a `Co-Authored-By: Claude` trailer.** All new commits should be clean subject + body only.

22. **Release-grade quality bar.** User is vibe-coding; Claude owns security, error handling, UX polish, proactive risk flagging.

23. **Always add timeouts + error surfacing** on Firestore reads. Infinite spinners = untestable app. Use `.timeout(Duration(seconds: 10))` pattern, surface error message to UI. PYQ screen `_runFailed` widget is the canonical pattern.

24. **Blaze billing cap is active.** `stopBilling` Cloud Function auto-disables billing if monthly Firebase spend exceeds ₹200. **Gemini costs are billed separately via Google Cloud and are NOT capped by this function.** Monitor manually or enable a separate Google Cloud budget alert.

25. **Storage + Firestore rules deployed (2026-04-25).** Deploy via `firebase deploy --only firestore:rules` / `--only storage` from inside `academic_ally/`.

26. **iOS support added (4f7ed09).** `ios/` has Podfile, Podfile.lock, GoogleService-Info.plist, AppDelegate, SceneDelegate. Not yet exhaustively tested on a real iOS device — Android emulator is the demo target.

27. **Gemini free-tier 200 requests/day per model per project.** One PYQ run = ~15–25 Gemini calls → can hit the cap in 8–15 test runs. With 4 RAG-heavy multi-agent features running, easier to hit. Mitigations: wait for midnight Pacific reset, switch `LLM_MODEL` env var to a different Gemini model (separate buckets), or enable paid billing (~₹1–2 per run).

28. **DropdownButton `items == null || items.isEmpty || value == null || items.where(item.value == value).length == 1` assertion** is a Flutter classic — fires when a dropdown's current value is not present in the items list (zero matches) OR appears more than once (duplicates). Subject lists from Firestore can have dupes (legacy data); guard with `Set` / `toSet().toList()` before passing to `DropdownButton`.

### functions_py/ legacy gotchas (only relevant if redeploying)

29. **Firebase CLI loads `functions_py/.env` automatically** and conflicts with `secrets=[...]` declarations. Workaround on every deploy: `mv functions_py/.env functions_py/.env.local` before, restore after.

30. **CrewAI 1.x EventListener crashes on missing `LOCALAPPDATA`/`HOME`.** Shim at the top of `functions_py/main.py` sets both to `tempfile.gettempdir()` + disables CrewAI tracing. Keep it. (The same shim is also at the top of `backend/app/main.py`.)

31. **Firebase analyzer 10s timeout.** Lazy-import the handler inside the function body in `functions_py/main.py`. Do not hoist back to module-level.

32. **Cloud Run default 512MB too small for CrewAI + ChromaDB.** Memory bumped to 1GB, `memory=False` in crew factory. Keep both for any future deploy.

33. **`functions_py/` uses bare imports** (`from shared.X`, not `from functions_py.shared.X`). Tests have `conftest.py` mirroring this. Don't reintroduce the `functions_py.` prefix.

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
- **APK output path** (after `flutter build apk --release`): `academic_ally/build/app/outputs/flutter-apk/app-release.apk` (universal); add `--split-per-abi` for `app-arm64-v8a-release.apk` etc.
- **AI backend (dev):** `http://127.0.0.1:8000` from host · `http://10.0.2.2:8000` from Android emulator
- **AI backend (legacy deployed, PYQ only):** `https://us-central1-academic-ally-app.cloudfunctions.net/pyq_analyze`
- **Backend run command:** `cd academic_ally/backend && ./run.sh` (after `pip install --user uv` + ensuring `%APPDATA%\Python\Python312\Scripts` on PATH)
- **AKRAM.md:** non-technical cofounder's presentation reference at `academic_ally/AKRAM.md`
- **AA DEMO/:** major-project demo presentation kit (5 member scripts + README + PPTPROMPT) at `academic_ally/AA DEMO/`

---

## What's Still Left

Most of the original Phase 4 list shipped in commit `4f7ed09`. Remaining:

1. **Wire up the 3 hidden features** (Knowledge Map, Gen UI, Project Copilot) on the real backend — OR remove their code paths entirely if they're not part of the post-major-project roadmap.
2. **Strict Firestore rules** — per-user ownership on `Users/{uid}/*`, admin writes gated, no catch-all reads on other users' private data. Depends on Custom Claims Cloud Function.
3. **Firebase Custom Claims Cloud Function** for admin role (replaces the current Firestore-doc-claim hack).
4. **Composite indexes** for Channels messages, Marketplace, Jobs, Users subcollections ordered by `createdAt`.
5. **Storage rules hardening** — path-scoped, MIME validation, size limits (current rules are auth-gated but permissive on shape).
6. **Vector Search index automation** — script to create per-subject_key indexes (manual via Console today).
7. **LaTeX rendering** for Snap a Doubt (nice-to-have).
8. **Dart-side automated tests** — Python has 21 green tests; Dart has zero. Start with FCM idempotency, deep-link parsing, topic sanitization, mastery EMA.
9. **Revert `debug_error` / `debug_traceback`** in `functions_py/features/pyq_analyzer/handler.py` before any public release.
10. **Pre-deploy script** for `functions_py/` to auto-handle the `.env` rename dance (only relevant if we redeploy).
11. **Production deployment plan for `backend/`** — Cloud Run, Fly.io, or similar. Currently localhost-only; demo-only setup.
12. **Backend RAG-layer tests** — extend pytest coverage to embedder rate-limit, vector store, and the 4 non-PYQ feature crews.

---

## Session Context Pointer

Historical session journal (what was tried + learned on 2026-04-19) lives at:
`C:\Users\moham\.claude\projects\C--Devspace-flutterprojects-Academic-Ally\memory\project_session_2026-04-19.md`

User preferences and hard-won lessons in the `feedback_*` memory files (see `MEMORY.md` index).
