# Academic Ally

## What Is This?

Academic Ally is a resources platform (notes, question papers, question banks, syllabi) for B.E/B.Tech engineering students at **Osmania University (OU)** and **JNTUH** in Hyderabad, Telangana. The app is **published and LIVE on the Google Play Store as `com.academically` v1.0.0 — the Flutter build**, and has been **fully migrated from React Native to Flutter** — and **expanded into an AI-native education platform** with 5 multi-agent AI features (4 multi-agent crews + AllyBot RAG chat) for a major project submission (two cofounders).

---

## 🚨 Current Status (2026-08-29) — SUBMISSION COMPLETE, PRODUCT REVIVAL NEXT

The thesis, final 25-slide presentation, and viva preparation note in the local-only
`../Shoaib Choudry Major/` folder were completed and approved by the owner on
2026-08-29. They are no longer part of the active backlog. Resume technical work here,
starting with the billing/Storage outage and backend deployment described below.

The project sat dormant ~3.5 months (May–Aug 2026). Code is intact and synced;
**two pieces of infrastructure died** and both block the major-project demo:

| What | State | Effect |
|---|---|---|
| Google Cloud billing | **RESTORED** — account `01CF4E-E7121B-EBB122` activated after the ₹1,000 prepayment. | Project is back on Blaze and Firebase Storage access recovered. Continue monitoring usage and budget alerts. |
| Railway backend | **LIVE** — health check passes | All 5 AI endpoints are deployed at `academic-ally-production-503f.up.railway.app`; a new app release is required to replace the old URL in shipped builds. |

Data is **fully intact**: 6,481 PDFs / ~31 GB in `academic-ally-app.appspot.com`,
Firestore trees (OU + JNTUH) healthy. Because 31 GB > Spark's 5 GB free tier,
**Blaze is mandatory** — there is no free-tier path back.

### ⚠️ THIS IS A LIVE PRODUCTION OUTAGE, NOT JUST A DEMO PROBLEM

**The Flutter build is what ships on the Play Store** (`com.academically`, v1.0.0
— confirmed by the repo owner 2026-08-27; the React Native app was replaced).
So this codebase is the live app, and the two failures above are hitting **real
users right now**: nobody can open a PDF, and every AI feature errors out. This
has been the case since billing lapsed around July 2026.

Treat `master` as production code. Restoring billing is urgent for users, not
only for the major-project demo.

Revival order: (1) verify one client-side PDF download and one AI flow end to end,
(2) publish a Flutter release containing the restored backend URL when the cofounder
is available, (3) re-verify the `stopBilling` cap, (4) app bugs + UI work.

The non-technical submission work is complete. Do not spend technical sessions on
thesis screenshots or PPT work unless the owner explicitly reopens that scope.

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
│   │   ├── scripts/storage_audit.py      # Live-bucket audit (prefix counts, sizes, orphans)
│   │   ├── scripts/list_storage_pdfs.py  # List every blob under a Storage prefix
│   │   ├── scripts/list_resources.py     # Dump Firestore Universities/.../{type}/{subject} docs
│   │   ├── scripts/check_it_sem2*.py     # One-off IT/sem-2 cross-checks (kept for reuse)
│   │   ├── pyproject.toml                # crewai 1.14.3 + fastapi + firebase-admin + tavily
│   │   └── run.sh                        # ./run.sh launches uv-synced uvicorn on :8000
│   ├── firebase.json                     # Firebase CLI config (multi-codebase)
│   ├── firestore.rules                   # Deployed Firestore rules
│   ├── storage.rules                     # Deployed Storage rules (auth-gated)
│   ├── functions/                        # Firebase Cloud Functions — Node.js (billing cap only)
│   ├── functions_py/                     # ⚠️ LEGACY — Python Cloud Function (only PYQ deployed; Flutter no longer points here)
│   └── pubspec.yaml
├── Academic Ally Legacy/                 # 🟡 PRE-FLUTTER ERA — reference only, do not edit
│   ├── Academic-Ally-master/             # Original React Native app (shipped to Play Store pre-migration)
│   ├── academic-ally-web-main/           # React web app — still LIVE at academic-ally.netlify.app
│   └── academic-ally-cloud-functions-main/  # Old Netlify functions (AllyBot legacy, replaced by backend/chat_about_pdf)
├── Shoaib Choudry Major/                 # 🔵 NON-TECHNICAL — Shoaib's major-project presentation work
└── Akram's Archive/                      # 🔵 NON-TECHNICAL — Akram's team presentation material (archived favour)
```

**CRITICAL:** Workspace root is a container, not a project root. The **only active project** is `academic_ally/`. Never place new project files at workspace root. Presentation/coursework material belongs in `Shoaib Choudry Major/` or `Akram's Archive/`, never in this repo.

On the owner's machine the workspace root also carries its own `CLAUDE.md` + `AGENTS.md` for whoever lands there first; **those are local-only and are not in this repo**, so ignore them if you cloned it — this file is self-sufficient. The `AGENTS.md` sitting next to this file IS in the repo and redirects Codex/other tools here. Keep whichever ones you can see in sync.

---

## 🟢 Current Git State (as of 2026-08-27)

**History unification (2026-08-27).** The repo used to hold two disconnected
histories: `master` had the React Native app (all Affan's work) and `flutter` had
the Flutter rewrite (all Shoaib's), with no common ancestor. Because GitHub only
credits commits reachable from the **default branch**, whichever branch was made
default would have erased the other person's contribution graph. Fix: a `-s ours`
graft merge (`d560fd8`) recording `master`, `prod-fixes` and `dev-affan` as extra
parents of the Flutter line — **zero file changes**, but all 155 commits are now
reachable from `master`, so both contributors keep full credit. No force-push,
nothing rewritten, and every original branch still exists.

```
  master   (= origin/master)       = ⭐ DEFAULT + MAIN LINE since 2026-08-27. Carries the UNIFIED history:
                                     React Native era (Affan, 79 commits) + Flutter era (Shoaib, 75 commits)
                                     + the graft merge = 155 commits. Tip is the Flutter codebase. Push here.
  flutteroptimalstate              = frozen snapshot at f689196 (state before the history unification) — safety net
  reactnative                      = the React Native app at its final state (v1.0.0, = prod-fixes) — do not edit
  prod-fixes / stable / dev-affan  = Affan's original RN branches, preserved untouched
  session-2026-04-19-backup        = historical work backup (local only, superseded)

DELETED 2026-08-27 (both were exact duplicates of commits already in master — zero commits lost):
  flutter                          = had become identical to master after the graft
  agentic-rag-platform             = merged PR #3 branch, fully contained in master

Six remote branches remain: master, reactnative, flutteroptimalstate, prod-fixes, stable, dev-affan.

WORKING TREE IS DIRTY (uncommitted, as of 2026-08-27):
  - deletions: AA DEMO/** (moved out of the repo to ../Akram's Archive/ on 2026-08-23)
  - modified:  pubspec.lock
  - untracked: ~15 backend/scripts/*.py bulk-upload + audit utilities from the May 2026
               JNTUH/OU ingestion marathon, plus devtools_options.yaml
  These are pending the pre-push cleanup commit.
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

--- 2026-04-26 ---
9c89f61  chore: deps update + AI backend URL switched to 10.0.2.2 (Android emulator)
         + UI cleanup (hide Knowledge Map / Gen UI / Project Copilot from home,
         rename Explore → Coming Soon...) + AA DEMO presentation prep folder

--- 2026-04-27 (today) ---
cbb0b15  docs(claude.md): refresh to Phase 4c state, correct Storage path layout
23cbca9  fix(ai): always run agents fresh — set force_refresh=true on all 5 endpoints
51ccbf1  feat(ui): home redesign + comprehensive dark mode overhaul
         (theme tokens + context.mutedText/faintText extensions + Quick Access
         tile size bump + AI Tools/Coming Soon as horizontal pill tiles +
         dark-mode-aware login/signup/forgot/onboarding + onboarding theme toggle)
86d0ab6  feat(upload+ux): real PDF upload + share + bookmarks message + tile redesign
         (Upload now writes to Firebase Storage at Resources/{...} + 3 Firestore
         indexes; Subject Resources tiles redesigned as vertical pills; Share
         uses Play Store deep link; "PDF storage not connected" message replaced
         with the real reason; backend/scripts/ audit utilities)
a600e0a  fix(auth): reset user-scoped Riverpod state on logout/login + demo script
59f4157  feat(backend): Railway deployment + JSON-string Firebase credentials
f931b33  feat(flutter): point AI backend at Railway-hosted service

--- 2026-05-09 (HEAD) ---
a871481  chore: add AA DEMO assessment materials, move AKRAM.md into AA DEMO/
```

### ⚠️ Uncommitted work done since (May–Aug 2026, not in any commit)

A large JNTUH + OU curriculum bulk upload ran in May 2026 via the untracked
`backend/scripts/bulk_upload_*.py` utilities. It took the Storage bucket from
~152 blobs to **6,481 PDFs / ~31 GB** and deleted the legacy `Universities/`
stray blobs. The scripts themselves were never committed.

**Status:** All 28 features ship in code. **5 AI backends live on local FastAPI:** PYQ Analyzer (5 agents), Study Planner (4 agents), Adversarial Examiner (4 agents, generator-critic), Snap a Doubt (Gemini Vision + 4 agents), AllyBot (single LLM call + RAG with resource_id_filter). 3 AI features still on mocks but **hidden from the home screen UI**: Knowledge Map, Gen UI, Project Copilot. Phase 3 community features (Jobs, Channels, Marketplace) shown as "Coming Soon" — code wired, Firestore rules deployed.

---

## 🧳 Continuity — starting on a new machine, or with a different AI agent

**This file is the complete entry point.** If you have just cloned the repo and
have no prior conversation history, everything you need is here plus `docs/`.

### What you get in the clone, and what you don't

The git repository root is `academic_ally/` — **not** the workspace folder above
it. The sibling folders described in Repository Structure (`Academic Ally
Legacy/`, `Shoaib Choudry Major/`, `Akram's Archive/`) and the workspace-root
`CLAUDE.md`/`AGENTS.md` are **local-only and deliberately outside git**: legacy
reference code and personal coursework have no business in the app repo. Their
absence on a fresh machine is expected and costs you nothing — this file carries
the orientation they provided.

### Setup on a fresh machine

```bash
git clone https://github.com/Academic-Ally/Academic-Ally.git
cd Academic-Ally
flutter pub get          # Firebase configs ARE committed, so the app builds as-is
flutter analyze          # should report: No issues found
```

The Flutter app runs immediately. The Python backend needs two files that are
gitignored and can never be committed:

| File | How to recreate it |
|---|---|
| `backend/.env` | `cp backend/.env.example backend/.env`, then fill in `GEMINI_API_KEY` (aistudio.google.com), `TAVILY_API_KEY` (tavily.com), and `BACKEND_ADMIN_KEY` (any long random string you choose) |
| `backend/service-account.json` | Firebase Console → ⚙️ Project settings → **Service accounts** → **Generate new private key** → save as `backend/service-account.json` |

Then `cd backend && ./run.sh` (requires `uv`: `pip install --user uv`, and that
install dir on PATH). `GET /health` reports which env vars actually loaded.

If the backend is being deployed rather than run locally, use
`FIREBASE_SERVICE_ACCOUNT_JSON` instead — the whole service-account JSON pasted
as one env var. See `backend/.env.example` and `backend/README.md`.

### Expect these to be broken until fixed

Read the status banner at the top of this file first. As of 2026-08-27 the
billing account is closed (Storage 402s → no PDF opens) and the hosted backend
is down (all AI features fail). Neither is caused by anything in the code, so
don't debug the app looking for them.

### Keeping continuity alive

Chat history does not travel between machines or AI tools — **the repo is the
only durable memory.** When you finish a significant change, update this file
(and the matching `docs/` deep-dive) in the same commit. A doc that lies is
worse than no doc: an agent will trust it. When a plan is executed or an
approach abandoned, move the doc to `docs/archive/` and log it in `STALE.md`.

---

## 📚 Documentation Map & Context Loading Protocol

**Read this file first, in full.** Then read the doc(s) below that match your
task — before writing code, not after. Each is marked with how far it can be
trusted as of 2026-08-27.

| Doc | Covers | Read it when | Accuracy |
|---|---|---|---|
| `AGENTS.md` | Hard rules for any AI agent | Always, if you are Codex or a non-Claude tool | ✅ Current |
| `README.md` | What Academic Ally is, for a human landing on the repo | Onboarding a person, or writing anything public-facing | ✅ Current |
| `docs/AGENTIC_FEATURES.md` | The 5 AI features end-to-end: crews, agents, tasks, RAG pipeline, code paths | Any AI / backend / RAG work | ✅ Current — the most reliable deep-dive |
| `docs/FIRESTORE_SCHEMA.md` | Every collection, field, rule status, index, plus the `RagChunks` vector store | Any Firestore read/write/rule change | ✅ Current |
| `docs/ARCHITECTURE.md` | Flutter structure, 31 routes, state management, deep-link allow-list, assets, deps | Any UI / navigation / provider work | ✅ Refreshed 2026-08-27 |
| `backend/README.md` | How to run the FastAPI backend + the Railway deploy procedure | Running or deploying the backend | ✅ Current |
| `functions/README.md` | The `stopBilling` billing hard-cap function | Billing / cost-cap work | ✅ Current |
| `docs/REACT_NATIVE_REFERENCE.md` · `docs/WEB_REFERENCE.md` · `docs/CLOUD_FUNCTIONS.md` | The three pre-Flutter codebases. **The code itself is not in this repo** — these docs ARE the reference | Checking how the original app behaved | ✅ Reference only |
| `docs/archive/` | Executed plans and abandoned approaches, indexed by `STALE.md` | Archaeology only | 🔴 **Deliberately out of date — do not act on it** |

**That table is the complete active documentation set** — this file plus nine
docs, three of which are small legacy references. It is kept deliberately small.
Before adding a new doc, ask whether the content belongs in an existing one; when
a doc's plan gets executed, move it to `docs/archive/` and add an entry to
`STALE.md` rather than leaving it to rot. Presentation and coursework material
never belongs in this repo at all.

**Protocol:**
1. `CLAUDE.md` (this file) → the status banner + gotchas are non-negotiable context.
2. The matching deep-dive doc above.
3. Then verify against **live source** — code, the bucket, Firestore. Where a doc
   and reality disagree, reality wins and the doc gets fixed in the same session.
   (Docs here have been wrong before: this file claimed 800/100 chunking and a
   non-existent "Verifier" agent, and `ARCHITECTURE.md` still described PDFs as
   living on Cloudflare R2 behind a placeholder viewer. All corrected 2026-08-27.)

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
11. **Upload — LIVE** (community PDF contribution: `file_picker` → Firebase Storage at `Resources/{uni}/{course}/{branch}/{sem}/{category}/{subject}/{uploadId}_{name}.pdf` → 3 parallel Firestore writes: `Universities/...` for visibility, `NewUploads/...` admin queue, `Users/{uid}/UserUploads/...` history)
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
- **Chunking:** **2000-char chunks with 200-char overlap** (`CHUNK_SIZE`/`CHUNK_OVERLAP` in `backend/app/shared/rag/pdf_chunker.py`), page numbers attached at ingestion
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

- **Bucket contents (verified 2026-08-27 by a full listing):** `Resources/` **6,481 PDFs**, `Avatars/` 14, `logo/` 10, `Doubts/` 5, `SeekHub/` 4 — **~31 GB total**. The legacy `Universities/` stray blobs described below have since been DELETED. 31 GB is far past Spark's 5 GB free tier, so **the project structurally requires Blaze**.
- **Bucket layout** (the `Universities/` prefix is historical — kept here for context only):
  - `Resources/{uni}/{course}/{branch}/{sem}/{type}/{subject}/{filename}.pdf` — the **curriculum PDFs** (~132 files) AND **all new community uploads** (since 2026-04-27 the in-app Upload feature writes here too, with a `{uploadId}_` prefix on the filename to avoid collisions). `type` = `Notes` / `OtherResources` / `QuestionPapers` / `Syllabus`. Subject and sem are part of the path. This is the path Firestore docs reference via the `storageId` field.
  - `Universities/{uni}/{course}/{branch}/{randomId}` — ~20 legacy blobs from the React Native era's Upload feature, no extension, no sem/subject in path. Inert; left in bucket but no new writes go here.
- The Firestore tree is rooted at `Universities/`; the Storage tree for curriculum PDFs is rooted at `Resources/`. **Don't conflate them** — they share top-level naming with the Firestore tree but the prefixes are different.
- The `storageId` field on a Firestore resource doc is the **complete bucket-relative path** (e.g. `Resources/OU/BE/IT/2/Notes/English/Unit II Notes.pdf`). The Flutter app does `FirebaseStorage.instance.ref(storageId).getDownloadURL()` — see `pdf_viewer_screen.dart:138`. Treat it as a full path; never split-and-basename it.
- App streams the resolved download URL into `flutter_pdfview`.
- Initial-page jump supported (used by Snap a Doubt citations).
- Auto-download in background on first view; subsequent opens are instant via local cache.
- Many legacy Firestore docs (Phase 0 RN era) have **no `storageId` field** — the resource provider filters those out via `.where((r) => r.storageId != null && r.storageId!.isNotEmpty)`, so they don't appear in the UI.
- **R2 is fully removed** (2026-08-27). `r2_storage_service.dart` and the `r2Endpoint`/`r2BucketName` constants were deleted — they were unreferenced dead code from an abandoned plan. If Firebase Storage egress ever becomes a cost problem, R2 would be a fresh implementation, not a revival.

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

**Firebase project:** `academic-ally-app` · **Plan:** Blaze — ⚠️ **billing account currently CLOSED (2026-08-27), Storage returns 402** · **Billing cap:** ₹200/month auto-disable via `stopBilling` function (Firebase only; Gemini costs separate, uncapped) — re-verify the budget/Pub/Sub wiring after billing is re-linked

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
- `Users/{uid}/MasteryScores/{topicId}` — bounded additive update (start 0.5; **+0.10** correct, **−0.12** incorrect, clamped to [0,1]), fed by Adversarial Examiner answers. NOT an exponential moving average — see `mock_ai_service.dart:80-82`, which `AgentAIService.updateMastery()` delegates to.
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

6. **AI backend URL — restored 2026-08-29.** `aiBackendBaseUrl` in `lib/core/constants/app_constants.dart` defaults to `https://academic-ally-production-503f.up.railway.app` and supports an `AI_BACKEND_BASE_URL` dart-define override. The production `/health` check reports Gemini, Tavily, the admin key, and Firebase Admin credentials ready. Existing Play Store builds still contain the retired URL and require a new release. Local overrides: `http://10.0.2.2:8000` (Android emulator NAT alias), `http://localhost:8000` (iOS sim / `flutter run -d windows`), or host LAN IP + uvicorn `--host 0.0.0.0` (physical device on the same Wi-Fi).

7. **`uv` (Astral) required for backend.** Install: `pip install --user uv` → puts binary at `%APPDATA%\Python\Python312\Scripts\uv.exe` on Windows. Ensure that path is on `PATH` or `./run.sh` fails with "uv: command not found." First `uv sync` takes ~1 minute; subsequent runs cached.

8. **Backend `.env` must contain valid `GOOGLE_APPLICATION_CREDENTIALS`** pointing to a Firebase service-account JSON. Without it, Bearer-token auth and Firestore writes fail. The Admin bypass scheme (`Authorization: Admin <key>:<uid>`) still works for curl.

9. **`functions_py/` is LEGACY.** Only PYQ Analyzer was ever deployed there. The Flutter app no longer points at it (`aiBackendBaseUrl` is now local FastAPI). Keep `functions_py/` around for potential future deploy, but do NOT add new features there — add them to `backend/`.

10. **AllyBot is no longer Netlify.** The old Netlify ChatPDF function in `academic-ally-cloud-functions-main/` (workspace sibling) is DORMANT. Do not edit it. AllyBot now hits `/chat_about_pdf` on the local FastAPI backend.

11. **Home screen has 3 sections:** Quick Access (icon row) → AI Tools (4 cards: Study Planner, PYQ Analyzer, Adversarial Examiner, Snap a Doubt) → **Coming Soon...** (3 cards: Jobs, Communities, Marketplace) → Recommended. Routes for hidden features (`/knowledge-map`, `/gen-ui`, `/project-copilot`) are still wired in `app_router.dart` — only the home tiles are removed. Code is intact for re-enabling.

12. **Adversarial Examiner's real agent lineup** (verified in `backend/app/features/adversarial_examiner/agents.py`) is **Topic Selector → Trap Pattern Miner → Adversarial Question Generator → Output Formatter**. There is NO standalone "Verifier" agent — self-verification is folded into the generator's task instructions (it must RAG-check that each question sounds like the source material). Earlier docs describing a separate Verifier critic were wrong.

13. **Firestore Vector Search requires a per-subject_key index.** `RagChunks/{subject_key}/chunks` queries fail until the index is created via Firebase Console or `gcloud`. Manual today; a script to automate this is on the to-do list.

14. **QueryList `list` items use `subjectName`** (capital N), not `subject`. `SubjectModel.fromMap` reads `subjectName` as primary with `subject` fallback. Never regress this.

15. **Legacy `sem` can be int or string.** Always `.toString()` when parsing from Firestore.

16. **FCM topic names don't allow spaces.** Branches like "CSE AIML" need sanitization. `FcmService.buildTopic()` regex-replaces non-allowed chars with hyphen.

17. **FCM infinite-loop bug pattern** — 3-layer idempotency fix landed (listener guard + service-level token check + fast-path in `syncTopicsForProfile()`). See `lib/core/services/fcm_service.dart` + `lib/core/providers/fcm_provider.dart`.

18. **Custom domain `getacademically.co` EXPIRED.** Live web app is at `https://academic-ally.netlify.app/`. Don't hardcode the expired domain. Firebase Auth email templates fixed by reverting to default `noreply@academic-ally-app.firebaseapp.com` sender.

19. **User handles APK builds manually.** Do NOT run `flutter build apk` commands — tell them the command + output path.

20. **User push-to-remote rule (CHANGED 2026-08-27):** `master` is now the default and main line, holding the unified RN + Flutter history — push there. The old "never push to master" rule is retired. Still forbidden: force-pushing `master`, and touching `reactnative` / `prod-fixes` / `stable` / `dev-affan` / `flutteroptimalstate`, which preserve history.

21. **User prefers commit messages WITHOUT a `Co-Authored-By: Claude` trailer.** All new commits should be clean subject + body only.

22. **Release-grade quality bar.** User is vibe-coding; Claude owns security, error handling, UX polish, proactive risk flagging.

23. **Always add timeouts + error surfacing** on Firestore reads. Infinite spinners = untestable app. Use `.timeout(Duration(seconds: 10))` pattern, surface error message to UI. PYQ screen `_runFailed` widget is the canonical pattern.

24. **Blaze billing cap is active.** `stopBilling` Cloud Function auto-disables billing if monthly Firebase spend exceeds ₹200. **Gemini costs are billed separately via Google Cloud and are NOT capped by this function.** Monitor manually or enable a separate Google Cloud budget alert.

25. **Storage + Firestore rules deployed (2026-04-25).** Deploy via `firebase deploy --only firestore:rules` / `--only storage` from inside `academic_ally/`.

26. **iOS support added (4f7ed09).** `ios/` has Podfile, Podfile.lock, GoogleService-Info.plist, AppDelegate, SceneDelegate. Not yet exhaustively tested on a real iOS device — Android emulator is the demo target.

27. **Gemini free-tier 200 requests/day per model per project.** One PYQ run = ~15–25 Gemini calls → can hit the cap in 8–15 test runs. With 4 RAG-heavy multi-agent features running, easier to hit. Mitigations: wait for midnight Pacific reset, switch `LLM_MODEL` env var to a different Gemini model (separate buckets), or enable paid billing (~₹1–2 per run).

28. **DropdownButton `items == null || items.isEmpty || value == null || items.where(item.value == value).length == 1` assertion** is a Flutter classic — fires when a dropdown's current value is not present in the items list (zero matches) OR appears more than once (duplicates). Subject lists from Firestore can have dupes (legacy data); guard with `Set` / `toSet().toList()` before passing to `DropdownButton`.

29. **All AI features always run agents fresh.** `AgentAIService` sends `force_refresh: true` on every call to all 5 backend endpoints (PYQ, Study Planner, Adversarial Examiner, Snap a Doubt, AllyBot) — the backend's 24h cache is intentionally bypassed from the client. If you ever need cached behavior back, that's the single line per call to flip in `lib/core/services/ai/agent_ai_service.dart`. Each PYQ run still costs ~₹2 — keep the Gemini quota in mind during demos.

30. **Dark-mode text colors must use `context.mutedText` / `context.faintText`**, not raw `Colors.grey[XXX]`. These are `BuildContext` extensions defined in `lib/config/theme.dart` that resolve to lighter shades in dark mode (`darkOnSurfaceMuted` / `darkOnSurfaceFaint`) and darker shades in light mode. The bulk of the codebase has been swapped; if you add a new screen with `Colors.grey[600]` for body text, run a grep before merging — the pattern is `mutedText` for secondary text, `faintText` for hints/disabled state. Helper methods that use these need `BuildContext context` in their signature.

### functions_py/ legacy gotchas (only relevant if redeploying)

29. **Firebase CLI loads `functions_py/.env` automatically** and conflicts with `secrets=[...]` declarations. Workaround on every deploy: `mv functions_py/.env functions_py/.env.local` before, restore after.

30. **CrewAI 1.x EventListener crashes on missing `LOCALAPPDATA`/`HOME`.** Shim at the top of `functions_py/main.py` sets both to `tempfile.gettempdir()` + disables CrewAI tracing. Keep it. (The same shim is also at the top of `backend/app/main.py`.)

31. **Firebase analyzer 10s timeout.** Lazy-import the handler inside the function body in `functions_py/main.py`. Do not hoist back to module-level.

32. **Cloud Run default 512MB too small for CrewAI + ChromaDB.** Memory bumped to 1GB, `memory=False` in crew factory. Keep both for any future deploy.

33. **`functions_py/` uses bare imports** (`from shared.X`, not `from functions_py.shared.X`). Tests have `conftest.py` mirroring this. Don't reintroduce the `functions_py.` prefix.

---

## Quick Reference

- **Firebase project:** `academic-ally-app` — ⚠️ **billing account CLOSED as of 2026-08-27** (Storage 402s). Was Blaze with a ₹200/month `stopBilling` cap; needs re-linking + re-verification.
- **Primary brand color:** `#6360FF` · Tertiary: `#FF8181` · Secondary: `#F1F1FA`
- **Font:** Poppins
- **Support email:** `support@getacademically.co` (domain EXPIRED — update when renewed)
- **Web app (live):** `https://academic-ally.netlify.app/`
- **Play Store listing:** `https://play.google.com/store/apps/details?id=com.academically`
- **Legacy deep link schemes:** `academically://` (works), `https://getacademically.co/` (domain expired), `https://app.getacademically.co/` (domain expired)
- **FCM topic format:** `{university}_{course}_{branch}_{sem}` — sanitize to `[a-zA-Z0-9-_.~%]`
- **APK output path** (after `flutter build apk --release`): `academic_ally/build/app/outputs/flutter-apk/app-release.apk` (universal); add `--split-per-abi` for `app-arm64-v8a-release.apk` etc.
- **AI backend (prod):** `https://academic-ally-production-503f.up.railway.app` — live; `/health` verified 2026-08-29
- **AI backend (dev):** `http://127.0.0.1:8000` from host · `http://10.0.2.2:8000` from Android emulator
- **AI backend (legacy deployed, PYQ only):** `https://us-central1-academic-ally-app.cloudfunctions.net/pyq_analyze`
- **Backend run command:** `cd academic_ally/backend && ./run.sh` (after `pip install --user uv` + ensuring `%APPDATA%\Python\Python312\Scripts` on PATH)
- **Presentation material lives OUTSIDE this repo:** Akram's team kit (5 member scripts, AKRAM.md, assessment briefs, PPTPROMPT) is at `../Akram's Archive/`; Shoaib's own major-project work goes in `../Shoaib Choudry Major/`. Do not re-add either to this repo.

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
