# AI-Native Pivot — Build Plan

Academic Ally was repositioned from a static resource hub into an **AI-native education platform** for the major project submission. The migration is complete; Phases 1, 2, and 3 are all shipped. **Phase 4b landed the PYQ Analyzer's real multi-agent AI backend (Google Gemini via CrewAI).** The remaining Phase 4 endgame items are listed at the bottom.

## Confirmed AI Features (all built on mocks)

| Feature | Role | Status |
|---------|------|--------|
| **Gen UI** | LLM returns structured JSON → rendered as native Flutter widgets. Makes the app feel AI-native, not chatbot-bolted-on. | ✅ Built |
| **Study Planner** | AI-generated exam prep schedule (personalized to syllabus, exam date, weak topics). | ✅ Built |
| **Misconception Graph** | Knowledge-tracking graph: nodes = topics, tagged misconceptions. Backbone that makes every other AI feature smarter. | ✅ Built |
| **PYQ Analyzer** | Scans past question papers, predicts likely questions, ranks syllabus topics by exam weight. Core wedge for OU/JNTUH exam culture. | ✅ Built |
| **Snap-a-Doubt** | Photo a problem (handwritten/textbook) → step-by-step solution via vision LLM. Daily habit driver. | ✅ Built |
| **Project Copilot** | Major/minor project ideation, feasibility, lit review, scaffolding, report generation. Startup moat. | ✅ Built |

## Confirmed Non-AI Features (all built)

- **Communities & Channels** — topic-based student chat with real-time messages ✅
- **Jobs & Internships** — postings with external apply links ✅
- **Marketplace** — used textbooks + items with Firebase Storage image uploads + WhatsApp contact ✅

## Build Plan — 4 Phases

### Phase 1 — COMPLETE ✅

1. ~~**Onboarding screens**~~ ✅ (4 slides matching RN with Skip button, `intro_shown` flag)
2. ~~**Deep linking**~~ ✅ (`app_links`; custom scheme + universal links; pending-link queue for pre-auth users; FCM-tap bridge)
3. ~~**FCM push notifications**~~ ✅ (token registration on auth, auto topic subscribe/unsubscribe, foreground SnackBar + background handler, cleanup on logout, 3-layer idempotency fix)
4. ~~**Report abuse**~~ ✅ (bottom sheet: 3 reasons + mailto fallback, writes to `userReports` Firestore path)

**Known tech debt on deep linking:** Android App Links `autoVerify=true` needs `/.well-known/assetlinks.json` hosted on the HTTPS domains for chooser-less direct-to-app behavior. Without it, HTTPS links show a chooser "Open with…" dialog. Custom scheme (`academically://`) works without any domain config. Legacy `getacademically.co` domain is expired — allow-list kept for forward-compat.

### Phase 2 — COMPLETE ✅ (all features on mocks)

**Foundation (commit `6e5d2f6`):** service abstraction lives at `lib/core/services/ai/`:
- `ai_service.dart` — abstract `AIService` interface, 8 methods covering all 6 AI features + AllyBot
- `mock_ai_service.dart` — realistic mock impl with 1.5–3s simulated latency. Persists user-scoped state (study plans, doubt history, mastery scores, projects) to real Firestore so UI reads from the same source the real impl will.
- `gemini_ai_service.dart` — stub where every method throws `UnimplementedError` with Phase 4 pointer; prevents accidentally flipping to Gemini before it's ready
- `lib/core/providers/ai_provider.dart` → `aiServiceProvider` — single-line swap point for Phase 4
- Models in `lib/models/ai_models.dart` (KnowledgeNode, Misconception, MasteryScore, StudyPlan/Day/Task, PyqAnalysis, PredictedQuestion, DoubtSolution, SolutionStep, ProjectGuidance, ProjectPhase)

**Feature commits:**

5. ~~**Misconception Graph**~~ ✅ (`0edc0bb`) — Knowledge Map screen (subject picker + topic list with live mastery bars + misconception chips). PracticeSheet runs the quiz loop. Nodes client-generated for Phase 2 (real `KnowledgeGraph` collection seeded server-side in Phase 4).
6. ~~**Study Planner**~~ ✅ (`bdc7f1e`) — 3-screen flow (list → create → detail). Day-by-day schedule with task toggles, progress bar, days-left badge.
7. ~~**Gen UI**~~ ✅ (`2dbde35`) — prompt input + renderer. 6 primitives: Column, Row, Card, List, Text, Button. Unknown node types render as muted pill (doesn't crash on LLM hallucinations).
8. ~~**PYQ Analyzer**~~ ✅ (`ec61dba`) — subject picker + analysis results. Fetches existing QuestionPapers as corpus. Analysis cached in `PyqAnalysis/{uni}/{course}/{branch}/{sem}/{subject}`. ⚠ Writes silently fail today because this collection has no rule block in live Firestore rules (fix in Phase 4).
9. ~~**Snap-a-Doubt**~~ ✅ (`0d693f4`) — camera/gallery → mock solver. Uses local file path as `imageUrl` for Phase 2 (swaps to Firebase Storage upload in Phase 4). Solution rendering with numbered steps + monospace LaTeX placeholder (real LaTeX renderer is Phase 4 nice-to-have).
10. ~~**Project Copilot**~~ ✅ (`42d5f77`) — 3 screens (list → create → 4-tab detail). Per-phase guidance cached on project doc under `cachedGuidance.{phase.wire}`. Regenerate button overwrites.

### Phase 3 — COMPLETE ✅

11. ~~**Jobs & Internships**~~ ✅ (`f150e81`) — list with type filter + detail with external apply + post form + empty-state seeder. Apply via `url_launcher` opens recruiter's own page.
12. ~~**Communities & Channels**~~ ✅ (`08d877c`) — channels list + chat detail + create form. Real-time Firestore message stream. Seeder creates 3 sample channels with messages.
13. ~~**Marketplace**~~ ✅ (`1dfb98c`) — grid list + detail + create form. Firebase Storage image uploads (up to 5 per listing). WhatsApp deep link for seller contact. Seeder creates 4 sample listings.

**Interim (`097c10e`):** Storage rules deployed — `allow read, write: if request.auth != null`. Replaces default public scaffold. Marketplace image uploads work on top of this.

### Phase 4b — PYQ Analyzer multi-agent backend — COMPLETE ✅

Shipped 2026-04-25. PYQ Analyzer is the flagship live AI feature:

- **Architecture:** Python Firebase Cloud Functions Gen 2 (Python 3.12, us-central1, 1GB RAM, 540s timeout)
- **Framework:** CrewAI 1.14.3 hierarchical process (manager auto-provisioned + 5 specialist workers: Syllabus Researcher, Web Researcher, Pattern Analyst, Question Predictor, Output Formatter)
- **LLM:** Google Gemini 2.5 Flash Lite (via litellm routing; swap via `LLM_MODEL` Firebase Secret without redeploy)
- **Web search tool:** Tavily, attached to research agents
- **Secrets:** `GEMINI_API_KEY`, `TAVILY_API_KEY`, `LLM_MODEL` in Firebase Secret Manager
- **Progress UI:** `AnalysisRuns/{runId}` tracker doc streamed live to Flutter via Riverpod `StreamProvider`, agents check off in real time
- **Cache:** 24h at `PyqAnalysis/{uni}/{course}/{branch}/{sem}/{subject}`, cleanup function sweeps ephemeral run trackers hourly
- **Flutter integration:** `AgentAIService` replaces `MockAIService`. PYQ uses the real backend; the other 6 interface methods delegate to `MockAIService` so every other AI feature keeps working on mocks.
- **Firestore rules:** deployed 2026-04-25 — Phase 3 collections (Jobs, Channels, Marketplace) + Phase 4 collections (PyqAnalysis, AnalysisRuns, KnowledgeGraph, Premium_Users) all now have explicit rule blocks. No catch-all.
- **Tests:** 21 pytest unit tests for the Python backend, all green.
- **Auth:** Firebase ID token required on every request; 401 if missing/invalid.
- **Live endpoint:** `https://us-central1-academic-ally-app.cloudfunctions.net/pyq_analyze`

Full commit log in `../CLAUDE.md` under the "Phase 4b — PYQ Analyzer real AI backend" section.

### Phase 4 — Remaining endgame work (NOT started)

Making the app fully production-ready for public release:

14. **Cloudflare R2** — fill `publicBaseUrl` in `r2_storage_service.dart`, create bucket, upload PDFs matching folder convention (`Universities/{uni}/{course}/{branch}/{sem}/{subject}/{category}/{file}.pdf`), update Firestore resource docs' `storageId` fields. R2 chosen over Firebase Storage because egress costs scale badly for public PDF downloads.

15. **Port the remaining 5 AI features' backends** — Knowledge Map, Study Planner, Gen UI, Snap-a-Doubt, Project Copilot. Each becomes its own CrewAI crew under `functions_py/features/*/` reusing the PYQ pattern (schema/agents/tasks/crew/handler). Snap-a-Doubt additionally needs a vision-capable model variant.

16. **Port AllyBot (PDF chat)** through the same backend. Remove Netlify legacy path. Fix `cloudFunctionsBaseUrl` in `app_constants.dart`. AllyBot uses ChatPDF today; the real rewire will use Gemini with PDF grounding.

17. **Strict Firestore rules** — draft per-user ownership for `Users/{uid}/*`, admin gating on `ImmutableUserData`, and restrict `AnalysisRuns` reads to the owning user only. Depends on the Custom Claims Cloud Function landing first.

18. **Deploy composite indexes** — `Channels/{channelId}/Messages orderBy createdAt`, `Marketplace orderBy createdAt`, `Jobs orderBy postedAt`, `Users/{uid}/StudyPlans orderBy createdAt`, `Users/{uid}/Projects orderBy createdAt`, `Users/{uid}/DoubtHistory orderBy createdAt`.

19. **Firebase Custom Claims Cloud Function** — required for `isAdmin()` checks in strict rules. Admin role lives at `ImmutableUserData/{uid}.customClaims.admin`; needs an Admin SDK function that writes/reads this and mints auth custom claims.

20. **Clean up rogue Console indexes** (`undefined` collectionGroup, unused `SeekHub (APP, SeekHub)`, `Chemistry.category` override).

21. **Storage rules hardening** — path-scoped writes (users only write to their own `{uid}` prefix), MIME type validation, size limits.

22. **LaTeX rendering for Snap-a-Doubt** (optional polish) — add `flutter_math_fork` to render LaTeX steps properly instead of monospace placeholder.

23. **Automated tests (Dart side)** — Python side has 21 tests for the AI backend (all green). Dart side still zero. Start with FCM idempotency, deep-link parsing, topic sanitization, mastery EMA update.

24. **Pre-deploy script** to automate the `mv functions_py/.env functions_py/.env.local` dance. Firebase CLI auto-reads `.env` and conflicts with `secrets=[...]` declarations; right now this is manual.

25. **Revert the temporary `debug_error` / `debug_traceback` fields** in `features/pyq_analyzer/handler.py` before public release.

26. **Enable Google Cloud billing on the project** before public demo — free-tier Gemini is 200 req/day per model; hitting that during a live demo is embarrassing. Paid tier costs ~$0.01–0.02/run.

27. **Testing, polish, demo prep.**

## Key Architectural Principles (still true)

- **Service abstractions before features.** Paid off — `aiServiceProvider` is a true one-line swap for Phase 4.
- **Mocks must be realistic.** `MockAIService` returns plausible topics (actual OU/JNTUH subjects), simulates 1.5–3s latency, writes state to real Firestore.
- **Single swap point.** By Phase 4, flipping R2 + LLM config will activate every feature without feature-code changes.
- **Backend as first-class.** Every feature added its Firestore path to `firestore_paths.dart` as it landed.

## Rules status (resolved 2026-04-25)

Phase 4b deploy caught up the rule blocks that drifted during Phase 2 + 3: `PyqAnalysis`, `AnalysisRuns`, `Jobs`, `Channels`, `Marketplace`, `Premium_Users`, `KnowledgeGraph` all now have explicit `auth != null` rule blocks. This was causing silent permission-denied failures on every post-Phase-2 collection write. File: `academic_ally/firestore.rules`, deployed via `firebase deploy --only firestore:rules`.

## Reference

- Full commit log + git state: `../CLAUDE.md`
- Firestore schema deep dive: `FIRESTORE_SCHEMA.md`
- Feature-level architecture: `ARCHITECTURE.md`
- Firebase artifacts audit: `FIREBASE_AUDIT.md`
