# AI-Native Pivot — Build Plan

Academic Ally is being repositioned from a static resource hub into an **AI-native education platform** for the major project submission. The migration is complete; the AI layer is the new build.

## Confirmed AI Features

| Feature | Role |
|---------|------|
| **Gen UI** | LLM returns structured JSON → rendered as native Flutter widgets (via `flutter_genui` or equivalent). Makes the app feel AI-native, not chatbot-bolted-on. |
| **Study Planner** | AI-generated exam prep schedule (personalized to syllabus, exam date, weak topics). |
| **Misconception Graph** | Knowledge-tracking graph: nodes = topics, edges = prerequisites, tags = common wrong mental models. Backbone that makes every other AI feature smarter. |
| **PYQ Analyzer** | Scans past question papers, predicts likely questions, ranks syllabus topics by exam weight. Core wedge for OU/JNTUH exam culture. |
| **Snap-a-Doubt** | Photo a problem (handwritten/textbook) → step-by-step solution via vision LLM. Daily habit driver. |
| **Project Copilot** | Major/minor project ideation, feasibility, lit review, scaffolding, report generation. Startup moat — no Indian edtech owns this cleanly. |

## Confirmed Non-AI Features (planned long ago, now committed)

- **Communities & Channels** — topic-based student chat, doubt discussion, memes, updates
- **Jobs & Internships** — postings directly on the platform
- **Marketplace** — used textbooks and bookstore inventory, buy/sell through the app

## Build Plan — 4 Phases

**R2 and LLM integration are deferred to the endgame.** Everything is built on mocks first so the app is fully demoable without external service costs/setup.

### Phase 1 — COMPLETE ✅

1. ~~**Onboarding screens**~~ ✅ (4 slides matching RN, no skip button, `intro_shown` flag)
2. ~~**Deep linking**~~ ✅ (`app_links`; custom scheme + universal links for getacademically.co + app.getacademically.co; pending-link queue for pre-auth users; FCM-tap bridge)
3. ~~**FCM push notifications**~~ ✅ (token registration on auth, auto topic subscribe/unsubscribe on profile change, foreground SnackBar + background handler, cleanup on logout)
4. ~~**Report abuse**~~ ✅ (bottom sheet: 3 reasons + mailto fallback, writes to `userReports` Firestore path)

**Tech debt on deep linking:** Android App Links `autoVerify=true` needs `/.well-known/assetlinks.json` hosted on `https://getacademically.co/` and `https://app.getacademically.co/` for chooser-less direct-to-app behavior. Without it, HTTPS links show a chooser "Open with…" dialog. Links still work, just with extra tap.

### Phase 2 — AI features with mock AI service

**Step 0 (DONE 2026-04-18):** abstraction lives at `lib/core/services/ai/`:
- `ai_service.dart` — abstract `AIService` interface, 8 methods covering all 6 AI features + AllyBot
- `mock_ai_service.dart` — realistic mock impl with 1.5–3s simulated latency; persists user-scoped data (study plans, doubt history, mastery) to real Firestore so UI reads from same source the real impl will
- `gemini_ai_service.dart` — stub where every method throws `UnimplementedError` with Phase 4 pointer; prevents accidentally flipping to Gemini before it's ready
- `lib/core/providers/ai_provider.dart` → `aiServiceProvider` — single-line swap point for Phase 4
- Models in `lib/models/ai_models.dart`

Then build features in this order (each one built on mock data):

5. ~~**Misconception Graph**~~ ✅ DONE — Knowledge Map screen (subject picker + topic list with live mastery bars + misconception chips). PracticeSheet runs the quiz loop: user answer → `AIService.tagMisconceptions` + `updateMastery` → results persist to `Users/{uid}/Misconceptions` + `/MasteryScores`, stream back into UI live. Topic nodes client-generated for Phase 2 (rules block top-level `KnowledgeGraph` writes; Phase 4 will seed that collection server-side).
6. **Study Planner** — UI + schedule storage + mock plan
7. **Gen UI** — widget catalog + JSON renderer + hand-written test JSONs
8. **PYQ Analyzer** — UI + mock analysis results
9. **Snap-a-Doubt** — camera + image picker + mock solver
10. **Project Copilot** — UI + mock responses

### Phase 3 — Non-AI confirmed features

11. Communities & Channels
12. Jobs & Internships
13. Marketplace

### Phase 4 — Wire real services (endgame)

14. **Cloudflare R2** — fill config in `r2_storage_service.dart` → PDFs light up
15. **LLM** — swap `MockAIService` → `GeminiAIService` (Gemini 1.5 Flash recommended for cost/capability). AllyBot cloud function likely needs rewrite: ChatPDF → Gemini. Also fix `cloudFunctionsBaseUrl` in `app_constants.dart:55` (currently wrong — points to Firebase Functions, backend is Netlify).
16. **Deploy Firestore/Storage rules + indexes** from `academic_ally/firestore.rules` and `firestore.indexes.json`. Diff against live Console rules first.
17. **Set up Firebase Custom Claims Cloud Function** (required for `isAdmin()` checks in rules to work).
18. Clean up rogue Console indexes (`undefined` collectionGroup, unused `SeekHub (APP, SeekHub)`, `Chemistry.category` override).
19. Testing, polish, demo prep.

**⚠ Discipline for Phases 1–3:** every new Firestore collection introduced in a feature must have its rule block added to `firestore.rules` in the same change — just not deployed until Phase 4. This keeps Phase 4 a "deploy + test" task, not a "design from scratch" task. Same for new compound queries → add to `firestore.indexes.json`.

## Key Architectural Principles

- **Service abstractions before features.** Nail the `AIService` interface + Gen UI JSON schema before building any AI feature — wrong interface = refactor every feature later.
- **Mocks must be realistic.** Mock responses should match the shape/latency of real LLM output so UI behaves correctly when swapped.
- **Single swap point.** By Phase 4, flipping R2 + LLM config should activate every feature without feature-code changes.
- **Backend as first-class.** Every feature has Firestore/rules/indexes implications — never treat backend as an afterthought.
