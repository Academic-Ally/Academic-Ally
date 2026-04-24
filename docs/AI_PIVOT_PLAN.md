# AI-Native Pivot — Build Plan

Academic Ally was repositioned from a static resource hub into an **AI-native education platform** for the major project submission. The migration is complete; Phases 1, 2, and 3 are all shipped. Phase 4 is the remaining endgame work.

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

### Phase 4 — Wire real services (endgame, not started)

This is the remaining work to make the app production-ready. All Phase 1-3 work runs on mocks + permissive rules — fine for close-circle demo, not fine for public release.

14. **Cloudflare R2** — fill `publicBaseUrl` in `r2_storage_service.dart`, create bucket, upload PDFs matching folder convention (`Universities/{uni}/{course}/{branch}/{sem}/{subject}/{category}/{file}.pdf`), update Firestore resource docs' `storageId` fields. R2 chosen over Firebase Storage because egress costs scale badly for public PDF downloads (napkin: ~₹2,250/month at 500 students × 3 downloads/day × 5 MB vs ~₹0 on R2).

15. **LLM** — swap `MockAIService` → `GeminiAIService` (Gemini 1.5 Flash for cost/capability). Requires a Firebase Function proxy to keep the API key off-device. Feature code doesn't change — only `aiServiceProvider`.

16. **Re-wire AllyBot** — `MockAIService.chatAboutPdf` is ready for Phase 4 swap, but AllyBot UI currently calls a legacy Netlify/ChatPDF path. Audit `cloudFunctionsBaseUrl` in `app_constants.dart:55` (currently wrong).

17. **Deploy strict Firestore rules** — draft locally first covering all 27 collections (10 pre-existing + 9 Phase 2 + 3 Phase 3). Must fix the broken `ImmutableUserData` helper function (uses `{document}` as literal text, not a variable). Must add `PyqAnalysis` rule block. Must enforce per-user ownership on all `Users/{uid}/*` subcollections.

18. **Deploy composite indexes** — `Channels/{channelId}/Messages orderBy createdAt`, `Marketplace orderBy createdAt`, `Jobs orderBy postedAt`, `Users/{uid}/StudyPlans orderBy createdAt`, `Users/{uid}/Projects orderBy createdAt`, `Users/{uid}/DoubtHistory orderBy createdAt`.

19. **Set up Firebase Custom Claims Cloud Function** (required for `isAdmin()` checks in rules to work). Admin system uses Firestore doc claims at `ImmutableUserData/{uid}.customClaims.admin` — needs an Admin SDK function to write to this path.

20. **Clean up rogue Console indexes** (`undefined` collectionGroup, unused `SeekHub (APP, SeekHub)`, `Chemistry.category` override).

21. **Storage rules hardening** — path-scoped writes (users only write to their own `{uid}` prefix), MIME type validation (`contentType.matches('image/.*')`), size limits (`< 5 * 1024 * 1024`).

22. **LaTeX rendering for Snap-a-Doubt** (optional polish) — add `flutter_math_fork` to render LaTeX steps properly instead of monospace placeholder.

23. **Automated tests** — zero today. FCM idempotency logic, deep-link parsing, topic sanitization, and mastery EMA update are the highest-value unit tests to add before flipping to real services.

24. **Testing, polish, demo prep.**

## Key Architectural Principles (still true)

- **Service abstractions before features.** Paid off — `aiServiceProvider` is a true one-line swap for Phase 4.
- **Mocks must be realistic.** `MockAIService` returns plausible topics (actual OU/JNTUH subjects), simulates 1.5–3s latency, writes state to real Firestore.
- **Single swap point.** By Phase 4, flipping R2 + LLM config will activate every feature without feature-code changes.
- **Backend as first-class.** Every feature added its Firestore path to `firestore_paths.dart` as it landed.

## Honest Phase 2/3 drift (worth noting)

The "add Firestore rule block in the same change" discipline from the original plan was NOT followed during Phase 2/3 builds. The 9 new collections added in Phase 2 + 3 exist in Firestore with no rule blocks — they work because the live wildcard rules (`Users/**`, `Marketplace/**` don't exist but `PyqAnalysis` doesn't either). Phase 4 will catch this up in one pass rather than retroactively adding them per-feature.

**`PyqAnalysis` in particular has no wildcard covering it** — PYQ Analyzer "Run Analysis" writes fail silently today. Fix as part of Phase 4 rules deploy, or as a one-liner rule add to make it work pre-Phase 4 if needed for demo.

## Reference

- Full commit log + git state: `../CLAUDE.md`
- Firestore schema deep dive: `FIRESTORE_SCHEMA.md`
- Feature-level architecture: `ARCHITECTURE.md`
- Firebase artifacts audit: `FIREBASE_AUDIT.md`
