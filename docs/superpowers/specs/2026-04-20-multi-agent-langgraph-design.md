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
| Orchestration framework | **CrewAI** (https://www.crewai.com/) — role-based multi-agent framework |
| Runtime | **Python 3.12 on Firebase Cloud Functions Gen 2** (new `functions_py/` codebase alongside existing Node.js `functions/`) |
| Primary LLM | **Minimax** (single provider for all agents, via LangChain's OpenAI-compatible adapter) |
| Web search tool | **Tavily** |
| Workflow shape | **Hierarchical Crew** — a manager agent orchestrates specialist worker agents (CrewAI's `Process.hierarchical`) |
| Grounding mode | **Hybrid** — prompt-reasoning + Tavily today; PDF retrieval tool added when R2 lands post-submission |
| Loading UX | **Progressive** — Firestore-backed progress tracker drives per-agent checkmark UI, updated via CrewAI's step/task callbacks |
| Caching | **24-hour Firestore cache** at `PyqAnalysis/{uni}/{course}/{branch}/{sem}/{subject}` |
| Failure model | **All-or-nothing** — full success or clean retry prompt |
| First feature to implement | **PYQ Analyzer** |

## Why Python + CrewAI (rationale, locked in 2026-04-20)

Chose over an earlier Node.js + LangGraph tentative direction because:

- Python is the industry standard for AI agent frameworks — CrewAI, AutoGen, LangChain, Haystack, LlamaIndex all Python-first; ecosystem depth roughly 10x Node.js
- CrewAI's role-based agent model (`Agent(role=..., backstory=..., goal=...)`) produces shorter, more readable code than LangGraph's graph wiring
- "Crew of AI agents" is a more compelling submission narrative than "graph workflow"
- Firebase Functions Gen 2 supports Python 3.10–3.12 natively; adding a Python codebase alongside existing Node.js is a supported, non-disruptive pattern

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
│     FIREBASE CLOUD FUNCTION (Python 3.12 + Gen 2 HTTP)             │
│     Location: academic_ally/functions_py/ (NEW codebase;           │
│                existing Node.js functions/ unchanged)              │
│                                                                    │
│  1. Verify Firebase ID token → extract uid                         │
│  2. Route to feature handler based on endpoint                     │
│  3. Check Firestore cache (bypass workflow if fresh)               │
│  4. Kick off CrewAI hierarchical crew                              │
│  5. Write cache doc + progress tracker to Firestore                │
│  6. Return JSON                                                    │
└────────────────────────────────────────────────────────────────────┘
                            │
                            ↓
┌────────────────────────────────────────────────────────────────────┐
│                    CREWAI HIERARCHICAL CREW                         │
│                                                                    │
│  Agents: manager + 5 specialist workers (each with role/backstory) │
│  Shared context passed between agents via CrewAI's built-in memory │
│                                                                    │
│  Manager agent:                                                    │
│    - Reads current task state                                      │
│    - Minimax LLM call: "which worker handles this next?"           │
│    - Delegates task to chosen worker                               │
│    - Worker executes (Minimax + optional tools)                    │
│    - Result bubbles back to manager                                │
│    - Loop until all tasks complete OR max iter hit                 │
│                                                                    │
│  Step callbacks fire → progress tracker doc updated                │
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
├── functions/                    # Existing Node.js codebase — UNCHANGED
│   ├── index.js                  # stopBilling (billing cap Cloud Function)
│   └── package.json
└── functions_py/                 # NEW Python 3.12 codebase for AI agents
    ├── main.py                   # HTTP endpoint exports (Firebase Functions Python Gen 2)
    ├── requirements.txt          # crewai, langchain-openai, tavily-python, firebase-functions, firebase-admin, pydantic
    ├── .python-version           # 3.12
    ├── shared/
    │   ├── __init__.py
    │   ├── auth.py               # Firebase ID token verifier decorator
    │   ├── minimax_llm.py        # CrewAI LLM config pointed at Minimax (OpenAI-compat endpoint)
    │   ├── tavily_tool.py        # CrewAI tool wrapping Tavily search
    │   ├── crew_factory.py       # Reusable hierarchical crew builder (used by all features)
    │   ├── cache.py              # Firestore cache read/write helpers
    │   ├── progress.py           # Progress tracker doc read/write, step callback factory
    │   └── errors.py             # Typed exceptions + user-facing message mapping
    └── features/
        ├── __init__.py
        ├── pyq_analyzer/
        │   ├── __init__.py
        │   ├── crew.py           # Crew construction (agents + tasks + process)
        │   ├── agents.py         # All 6 agent definitions (role/backstory/goal)
        │   ├── tasks.py          # Task definitions (one per agent contribution)
        │   ├── schema.py         # Pydantic models for input + output shape
        │   └── prompts/          # Markdown files for backstories/goals (optional)
        ├── snap_doubt/           # Phase 4c
        ├── study_planner/
        ├── misconception/
        ├── project_copilot/
        ├── gen_ui/
        └── allybot/
```

## Firebase multi-codebase configuration

The existing `firebase.json` needs a small update to register both codebases:

```json
{
  "functions": [
    { "source": "functions",    "codebase": "default", ... },
    { "source": "functions_py", "codebase": "ai",       "runtime": "python312" }
  ],
  "storage": { "rules": "storage.rules" }
}
```

`firebase deploy --only functions` deploys both. `firebase deploy --only functions:ai` deploys only Python. Zero risk to the Node.js codebase.

## Shared infrastructure (reused across all 6 features)

- **Auth decorator** (Firebase ID token verify → extract `uid`, wraps endpoint handlers)
- **Minimax LLM config** (CrewAI `LLM` wrapper pointed at Minimax OpenAI-compatible endpoint, reads API key from Firebase Secret)
- **Tavily tool** (pre-wrapped CrewAI `Tool`, reads Tavily key from Secret)
- **Crew factory** (takes agent list + task list + manager LLM, returns configured `Crew` with hierarchical process)
- **Cache helpers** (read/write to Firestore at known paths, 24h freshness check)
- **Progress tracker + step callback** (create/update `AnalysisRuns/{runId}`, exposes a CrewAI-compatible `step_callback` that logs which agent is currently working)
- **Error mapping** (internal exceptions → user-friendly HTTP responses)

Feature-specific code (what's NOT shared): agent roles/backstories, task definitions, output schemas, endpoint handler.

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

## Agent roster (CrewAI `Agent` definitions)

Each agent is a CrewAI `Agent` with a `role`, `goal`, and `backstory` — the manager agent is configured separately via `manager_llm` in the `Crew`.

| # | Agent | Role (CrewAI label) | Tools | Task calls |
|---|---|---|---|---|
| 1 | **Manager** (via `Process.hierarchical`) | Orchestrator — delegates tasks to workers | — | 3-8 delegation decisions per run |
| 2 | **Syllabus Researcher** | Produces the official topic list for the subject | Minimax LLM | 1 task |
| 3 | **Web Researcher** | Searches web for past-paper patterns + current syllabus info | Minimax + Tavily tool | 1 task |
| 4 | **Pattern Analyst** | Reasons about exam conventions, marks distribution, question formats | Minimax LLM | 1 task |
| 5 | **Question Predictor** | Generates predicted questions with likelihood percentages | Minimax LLM | 1 task |
| 6 | **Output Formatter** | Shapes final JSON matching `PyqAnalysis` schema | Minimax LLM | 1 task |

## Example agent definition (CrewAI pattern)

```python
syllabus_researcher = Agent(
    role='Syllabus Researcher',
    goal='Produce the official topic list for {subject} in {university} {course} {branch} Sem {sem}',
    backstory=(
        "You are an expert in Indian engineering curricula with deep "
        "knowledge of JNTUH and Osmania University syllabi. You are "
        "meticulous, cite your reasoning, and never invent topics that "
        "aren't in the official curriculum."
    ),
    llm=minimax_llm,
    allow_delegation=False,
    verbose=True
)
```

All 5 worker agents follow this shape — only `role`, `goal`, `backstory`, and `tools` change per agent.

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

## Manager behavior (CrewAI `Process.hierarchical`)

In CrewAI's hierarchical process, the manager agent is auto-configured by CrewAI itself — we just pass `manager_llm=minimax_llm` in the `Crew` constructor. CrewAI generates the manager's prompt internally based on the task list and agent roster. The manager:

- Reads the current task assigned by the Crew
- Decides which worker agent is best suited (based on role + goal)
- Delegates the task to that worker
- Reviews the worker's output
- Either passes the work forward to the next task or asks the worker to revise

CrewAI's manager adapts similarly to our earlier supervisor concept: if Syllabus Researcher returns thin results, the manager may re-delegate to Web Researcher to fill gaps before moving on to Pattern Analyst.

## Crew construction (PYQ Analyzer)

```python
pyq_crew = Crew(
    agents=[syllabus_researcher, web_researcher, pattern_analyst,
            question_predictor, output_formatter],
    tasks=[research_syllabus, research_web, analyze_patterns,
           predict_questions, format_output],
    process=Process.hierarchical,
    manager_llm=minimax_llm,
    verbose=True,
    step_callback=progress_tracker_callback(run_id),
    max_rpm=60,
    memory=True
)
result = pyq_crew.kickoff(inputs={
    'subject': 'DBMS',
    'university': 'JNTUH',
    'course': 'BTECH',
    'branch': 'CSE',
    'sem': '3'
})
```

The `step_callback` is our Firestore progress-tracker hook — fires after each agent completes their task, updates `AnalysisRuns/{runId}.agents.{name}` to `"done"`.

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

### 2. Manager loop guard (CrewAI `max_iter`)

- `max_iter=8` set on each agent (CrewAI's built-in iteration cap)
- Additionally: `max_rpm=60` on the crew (caps total Minimax calls per minute)
- Exceeding either → CrewAI raises → caught and mapped to user-facing "couldn't complete" error

### 3. Overall timeout

- **180 seconds** maximum per request (enforced via CrewAI's `Task(max_execution_time=180)` at the top-level task)
- Exceeding → CrewAI cancels, tracker status = `timeout`, HTTP returns timeout error
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

- Unit tests for each agent's output parsing using `pytest` (~20 tests, ~1 day)
- Integration tests for the crew with mocked Minimax/Tavily via `vcrpy` or similar (~10 tests, ~1 day)
- End-to-end test in CI with real API (1 test, runs nightly)
- Automated output-quality gates (Pydantic schema validation already in place via CrewAI, plus topic-weight sum check, forbidden-string detection)
- GitHub Actions pipeline for PR validation
- Load testing at 50 concurrent requests
- Firestore emulator suite for offline dev

This appendix is NOT submission-blocking. Deferred to Phase 5+.

---

## Implementation plan location

This spec drives the implementation plan written by the `superpowers:writing-plans` skill once the user approves the full spec. The plan file lives at `docs/superpowers/plans/2026-04-20-multi-agent-langgraph-plan.md` (date may shift if plan-writing happens on a different day).
