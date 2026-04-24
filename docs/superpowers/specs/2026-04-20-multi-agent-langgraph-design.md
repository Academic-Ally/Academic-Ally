# Multi-Agent LangGraph Architecture — Design Spec

**Date:** 2026-04-20
**Status:** All 5 sections approved. Spec under user final review before implementation plan.
**Feature scope:** Phase 4 of Academic Ally — real AI implementation across 7 AI endpoints (6 AI features, with Misconception Graph exposing 2 endpoints), starting with PYQ Analyzer as proof-of-concept.

---

## Context

Academic Ally (Flutter app for Osmania University + JNTUH engineering students) has 6 AI-backed features currently running on `MockAIService`. Phase 4 replaces the mock with a real multi-agent system designed to showcase agentic AI architecture for a major project submission.

**Non-goals:**
- Not shipping for public production in this phase (Phase 5+ task).
- Not wiring Cloudflare R2 in this phase (agents use prompt-reasoning + web search instead).

## Decisions locked in

| Decision | Answer |
|---|---|
| Orchestration framework | **LangGraph** (JavaScript — `@langchain/langgraph`) |
| Runtime | **Node.js on Firebase Cloud Functions Gen 2** (same `functions/` folder as `stopBilling`) |
| Primary LLM | **Minimax** (single provider for all agents) |
| Web search tool | **Tavily** |
| Workflow shape | **Supervisor pattern** (a coordinator agent orchestrates specialist workers) |
| Grounding mode | **Hybrid** — prompt-reasoning + Tavily today; PDF retrieval tool added when R2 lands post-submission |
| Loading UX | **Progressive** — Firestore-backed progress tracker drives per-agent checkmark UI |
| Caching | **24-hour Firestore cache** at `PyqAnalysis/{uni}/{course}/{branch}/{sem}/{subject}` |
| Failure model | **All-or-nothing** — full success or clean retry prompt |
| First feature to implement | **PYQ Analyzer** |

## Keys required (from user)

1. `MINIMAX_API_KEY` — already obtained
2. `TAVILY_API_KEY` — free signup at https://tavily.com

Both stored as Firebase Secrets. Never in source control.

---

# Section 1 — Architecture

## System view

```
┌────────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP (unchanged)                    │
│                                                                    │
│  UI → ref.read(aiServiceProvider).analyzePyq(...)                  │
│       ↑                                                            │
│  aiServiceProvider now returns AgentAIService (not MockAIService)  │
└────────────────────────────────────────────────────────────────────┘
                            │
                            │ HTTPS POST
                            │ Header: Authorization: Bearer <Firebase ID token>
                            │ Body: { university, course, branch, sem, subject, pyqResourceIds[] }
                            ↓
┌────────────────────────────────────────────────────────────────────┐
│     FIREBASE CLOUD FUNCTION (Node.js 20 + Gen 2 HTTP)              │
│     Location: academic_ally/functions/ (same as stopBilling)       │
│                                                                    │
│  1. Verify Firebase ID token → extract uid                         │
│  2. Route to feature handler based on endpoint                     │
│  3. Check Firestore cache (bypass workflow if fresh)               │
│  4. Kick off LangGraph workflow                                    │
│  5. Write cache doc + progress tracker to Firestore                │
│  6. Return JSON                                                    │
└────────────────────────────────────────────────────────────────────┘
                            │
                            ↓
┌────────────────────────────────────────────────────────────────────┐
│                 LANGGRAPH SUPERVISOR WORKFLOW                       │
│                                                                    │
│  Shared State: { subject_ctx, syllabus, web_results,               │
│                  pattern_notes, predictions, iteration_count }     │
│                                                                    │
│  Supervisor loops:                                                 │
│    - Reads state                                                   │
│    - Minimax LLM call: "given state, which worker should run?"     │
│    - Invokes chosen worker (or declares done)                      │
│    - Worker updates state, returns control                         │
│    - Loop until done OR max iterations hit                         │
└────────────────────────────────────────────────────────────────────┘
     │                │                │                │
     ↓                ↓                ↓                ↓
┌────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ Minimax│     │  Tavily  │     │ Firestore│     │   R2     │
│  API   │     │  Search  │     │  reads   │     │ (Phase 5)│
└────────┘     └──────────┘     └──────────┘     └──────────┘
```

## Project structure

```
academic_ally/
└── functions/                    # Single Node.js codebase
    ├── index.js                  # Existing stopBilling + new HTTP endpoint handlers
    ├── package.json              # Adds @langchain/langgraph, @langchain/core, @langchain/openai (Minimax-compat), @tavily/core, firebase-admin, zod
    ├── shared/
    │   ├── auth.js               # Firebase ID token verifier middleware
    │   ├── minimax.js            # LangChain ChatOpenAI wrapper configured for Minimax
    │   ├── tavily.js             # Tavily search tool factory
    │   ├── supervisor.js         # Reusable supervisor graph factory (used by all features)
    │   ├── base_agent.js         # Agent class w/ prompt templating
    │   ├── cache.js              # Firestore cache read/write
    │   ├── progress.js           # Progress tracker doc read/write
    │   └── errors.js             # Typed errors + user-facing message mapping
    └── features/
        ├── pyq_analyzer/
        │   ├── workflow.js       # Graph construction
        │   ├── agents/
        │   │   ├── supervisor.js
        │   │   ├── syllabus.js
        │   │   ├── web_researcher.js
        │   │   ├── pattern_analyzer.js
        │   │   ├── question_predictor.js
        │   │   └── output_formatter.js
        │   ├── prompts/          # Markdown files with system prompts per agent
        │   └── state.js          # Zod schema for feature's workflow state
        ├── snap_doubt/           # Phase 4c
        ├── study_planner/
        ├── misconception/
        ├── project_copilot/
        ├── gen_ui/
        └── allybot/
```

## Shared infrastructure (reused across all 6 features)

- **Auth middleware** (Firebase ID token verify → extract `uid`)
- **Minimax LangChain client** (OpenAI-compatible, read API key from Firebase Secret)
- **Tavily search tool** (pre-wrapped LangChain tool)
- **Supervisor graph factory** (takes worker list + goal prompt, returns compiled graph)
- **Base agent class** (prompt templating, Minimax call, error wrapping, progress updates)
- **Cache helpers** (read/write to Firestore at known paths, 24h freshness check)
- **Progress tracker** (create/update `AnalysisRuns/{runId}` doc)
- **Error mapping** (internal exceptions → user-friendly HTTP responses)

Feature-specific code (what's NOT shared): agent prompts, state shape, workflow graph, endpoint handler.

## Endpoints (8 total — 6 AI features + Misconception Graph's second endpoint + AllyBot chat)

```
POST  /ai/pyq-analyze             ← Phase 4b: build this first (proof-of-concept)
POST  /ai/snap-doubt              ← AIService.solveDoubtFromImage
POST  /ai/study-plan              ← AIService.generateStudyPlan
POST  /ai/misconception-tag       ← AIService.tagMisconceptions
POST  /ai/misconception-mastery   ← AIService.updateMastery
POST  /ai/project-guidance        ← AIService.getProjectGuidance
POST  /ai/gen-ui                  ← AIService.generateUIResponse
POST  /ai/allybot-chat            ← AIService.chatAboutPdf
```

All follow the same request shape: Firebase auth token + feature-specific JSON payload. Response matches the existing `AIService` return types exactly (so Flutter's existing UI works without changes).

## Support functions (not user-facing endpoints)

- **`cleanupOldTrackers`** — scheduled Cloud Function (Firebase Scheduler, hourly). Deletes `AnalysisRuns/*` docs older than 1 hour. Lives in same `functions/` codebase, separate export.

---

# Section 2 — The 6 Agents (PYQ Analyzer)

## Agent roster

| # | Agent | Role | Tools | LLM calls |
|---|---|---|---|---|
| 1 | **Supervisor** | Decides which worker runs next based on state | — | 3-8 per run (one decision each) |
| 2 | **Syllabus Worker** | Produces the official topic list for the subject | Minimax | 1 |
| 3 | **Web Researcher** | Searches web for past-paper patterns + current syllabus info | Minimax + Tavily | 1-2 |
| 4 | **Pattern Analyzer** | Reasons about exam conventions, marks distribution, question formats | Minimax | 1 |
| 5 | **Question Predictor** | Generates predicted questions with likelihood percentages | Minimax | 1 |
| 6 | **Output Formatter** | Shapes final JSON matching `PyqAnalysis` schema | Minimax (small call) | 1 |

## Student-facing status strings

Progress tracker updates drive these:

```
1. Consulting supervisor...
2. Mapping out the syllabus...
3. Searching the web for past paper patterns...
4. Analyzing exam patterns...
5. Predicting likely questions...
6. Finalizing your analysis...
```

## Supervisor behavior

The Supervisor reads the shared workflow state and decides what's next. Prompt template (simplified):

```
You are the Supervisor coordinating 5 specialist agents building an exam
analysis for {subject} ({university} {course} {branch} Sem {sem}).

Available workers: SYLLABUS, WEB_RESEARCHER, PATTERN_ANALYZER,
QUESTION_PREDICTOR, OUTPUT_FORMATTER.

Current state: {state_summary}

Reply with ONLY the next worker name, or "DONE" if ready for formatter.
```

Supervisor adapts: if Syllabus Worker returns thin results, it may re-route to Web Researcher for a second pass before moving on.

## Progressive loading mechanism

Firestore doc `AnalysisRuns/{runId}` is written at workflow start with all agents `pending`. As each agent completes, the doc is updated (`agents.syllabus: "done"`). Flutter subscribes to the doc in real time — checkmarks tick over as the workflow progresses. Same Firestore-stream pattern used for Communities chat.

---

# Section 3 — Data Flow

## Happy-path sequence

1. **Flutter generates `runId`** — client-side UUID generated before the HTTP call. Passed in the request body. Flutter subscribes to `AnalysisRuns/{runId}` immediately (empty doc initially).
2. **Flutter → Cloud Function** — HTTPS POST with auth token + curriculum data + `runId`.
3. **Auth check** — Function verifies Firebase ID token, extracts `uid`. Bad token → 401.
4. **Cache check** — Read `PyqAnalysis/{path}`. If exists and `lastAnalyzed < 24h ago` → return cached value (no workflow run, no progress tracker used).
5. **Progress tracker init** — Write `AnalysisRuns/{runId}` with all agents as `pending`.
6. **Flutter sees tracker doc populate** — renders the initial progress UI (all checkmarks empty).
7. **Workflow runs** — LangGraph supervisor loop executes. Each agent completes → progress doc updated → Flutter re-renders checkmarks.
8. **Cache write** — Final `PyqAnalysis` JSON committed to Firestore at canonical path.
9. **Tracker marked complete** — Progress doc `status: complete`. Scheduled `cleanupOldTrackers` function deletes it later.
10. **HTTP response** — Function returns the same JSON to Flutter. App renders the analysis screen.

## Cache policy

| Situation | Behavior |
|---|---|
| Fresh cache exists (<24h) | Instant return, no workflow |
| Stale cache (>24h) | Cache bypassed, fresh workflow |
| No cache | Fresh workflow, cache written on success |
| User taps "Re-analyze" | Cache bypassed explicitly |

## Progress tracker doc shape

```json
{
  "status": "running" | "complete" | "failed" | "timeout",
  "subject": "DBMS",
  "runId": "abc123",
  "createdAt": <timestamp>,
  "agents": {
    "supervisor": "pending" | "running" | "done" | "failed",
    "syllabus": "...",
    "webResearch": "...",
    "pattern": "...",
    "predictor": "...",
    "formatter": "..."
  },
  "errorMessage": <optional string when failed>
}
```

Auto-deleted after 1 hour by a nightly cleanup function.

## Cache output shape

Matches `PyqAnalysis.toMap()` in `lib/models/ai_models.dart` exactly:

```
{
  subject, topicWeights: {topic: weight},
  predictedQuestions: [{question, topic, expectedMarks, likelihood, sourcePaperIds}],
  sourceResourceIds, lastAnalyzed
}
```

No schema changes required to Firestore or Flutter.

---

# Section 4 — Error Handling

## Failure categories + policies

### 1. Individual agent failures

- Retry same agent up to **2 times** (1s → 3s backoff).
- Still failing → whole workflow cancelled, return user-facing error "We couldn't complete the analysis this time. Tap to try again."
- Progress doc updated: failed agent shows ✗, remaining agents show "cancelled."

### 2. Supervisor loop guard

- Hard cap: **8 supervisor decisions per run**.
- Exceeding cap → force Output Formatter with partial state → best-effort result.

### 3. Overall timeout

- **180 seconds** maximum per request.
- Exceeding → cancel workflow, tracker status = `timeout`, HTTP returns timeout error.
- App shows "Analysis took too long. Try again in a moment."

### 4. Infrastructure failures

| Failure | Server behavior | Student sees |
|---|---|---|
| Invalid/expired auth token | Return 401 | Redirect to login |
| Firestore cache read fails | Proceed to fresh workflow | Normal loading |
| Firestore progress write fails | Skip progress UI, continue | Plain spinner (no checkmarks) |
| Firestore final write fails | Retry once, else return via HTTP only | Results show, not cached |
| Minimax API down (5xx) | Fail cleanly | "AI service temporarily unavailable" |
| Tavily API down | Web Researcher proceeds without results | Analysis quality slightly lower (still completes) |
| Network drops mid-request | Server completes in background, writes cache | On reopen, cache is available |

### 5. Rate limits

| Limit | Server behavior |
|---|---|
| Minimax 429 | Retry once after 5s backoff, then fail |
| Tavily quota exhausted | Web Researcher falls back to Minimax-only |
| Firestore quota | Return cached only (unlikely at this scale) |

### 6. Input validation

- Validate `university, course, branch, sem, subject` are non-empty strings before starting work.
- Missing/invalid → 400 response with clear error field name.

## Guarantees

1. Every request terminates within 180s.
2. No infinite spinners (hard timeouts everywhere).
3. No corrupted cache writes (all-or-nothing commits).
4. No silent failures (logged server-side, user-facing message always).
5. Best-effort graceful degradation (e.g., Tavily down → still complete).

## What the student NEVER sees

- Raw LLM errors, stack traces, or internal exception classes
- Any sign that "the AI is 6 prompts stitched together"
- Token counts, model names, or backend internals

All errors mapped to plain-English friendly messages.

---

# Section 5 — Testing (submission-focused, lean)

Goal: confirm the demo doesn't break during the submission, nothing more. Heavy test automation deferred to post-submission hardening.

## What we actually test for submission

### 1. Manual end-to-end smoke (3 runs, ~10 minutes total)

Run PYQ Analyzer for 3 subjects across different branches/sems:

| Subject | University | Course | Branch | Sem | Expected |
|---|---|---|---|---|---|
| DBMS | JNTUH | BTECH | CSE | 3 | Topic weights favor Normalization/ER Model; 5+ questions generated |
| Data Structures | OU | BE | CSE | 3 | Trees + Graphs show up prominently; questions mention traversals/traversal complexity |
| Computer Networks | JNTUH | BTECH | IT | 5 | OSI/TCP/IP-weighted; question stems reference layers |

Each run: confirm workflow finishes in <120s, output is well-formatted, progressive UI shows correct agent checkpoints.

### 2. Error path check (~5 minutes)

- Temporarily invalidate `MINIMAX_API_KEY` (set to a bogus value)
- Run a PYQ analysis
- Confirm: graceful error message appears in app (no crashes, no stack traces, no infinite spinner)
- Restore real key

### 3. Pre-demo dress rehearsal (~30 minutes, day before submission)

- Deploy to Firebase (final production deploy)
- Build release APK, install on demo device
- Walk through the full flow: log in → home → AI Tools → Knowledge Map OR PYQ Analyzer → see results
- Watch for any rough edges: slow transitions, weird text, wrong colors
- If anything looks off, fix and re-deploy

### 4. JSON shape sanity (one-time after first real run)

After the first successful end-to-end, manually inspect the resulting `PyqAnalysis` Firestore doc:

- `topicWeights` values sum to ~1.0
- `predictedQuestions` has 5+ entries, each with all required fields
- `lastAnalyzed` timestamp is recent
- Nothing hallucinated or malformed

This catches schema bugs that Flutter might silently mishandle.

## Tooling stack (lean)

- **Test runner:** not needed for submission — manual testing only
- **Firestore emulator:** not needed for submission
- **Mock HTTP:** not needed for submission
- **CI:** skip
- **Load testing:** skip

## Appendix A — Post-submission hardening (when going public)

When you decide to open Academic Ally to real users, bolt on:

- Unit tests for each agent's output parsing (~20 tests, ~1 day)
- Integration tests for supervisor graph with mocked Minimax/Tavily (~10 tests, ~1 day)
- End-to-end test in CI with real API (1 test, runs nightly)
- Automated output-quality gates (JSON schema validation, topic-weight sum check, forbidden-string detection)
- GitHub Actions pipeline for PR validation
- Load testing at 50 concurrent requests
- Firestore emulator suite for offline dev

This appendix is NOT submission-blocking. Deferred to Phase 5+.

---

## Implementation plan location

This spec drives the implementation plan written by the `superpowers:writing-plans` skill once the user approves the full spec. The plan file lives at `docs/superpowers/plans/2026-04-20-multi-agent-langgraph-plan.md` (date may shift if plan-writing happens on a different day).
