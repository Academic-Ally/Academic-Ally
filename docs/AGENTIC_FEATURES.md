# Agentic Features — Architecture and Working

Reference document for the five agentic AI features added to Academic Ally and the shared platform that supports them. Code paths cited inline for verification.

## Contents

1. [Shared platform](#1-shared-platform)
2. [Feature: PYQ Analyzer](#2-feature--pyq-analyzer)
3. [Feature: Study Planner](#3-feature--study-planner)
4. [Feature: Adversarial Examiner](#4-feature--adversarial-examiner)
5. [Feature: Snap-a-Doubt](#5-feature--snap-a-doubt)
6. [Feature: AllyBot chat](#6-feature--allybot-chat)
7. [Cross-cutting concerns](#7-cross-cutting-concerns)

---

## 1. Shared platform

All five features sit on top of the same retrieval-augmented generation (RAG) layer plus a CrewAI agent-orchestration scaffold. The shared platform was designed once so that adding a new feature costs a new agent crew, not new infrastructure.

### 1.1 PDF ingestion pipeline

[`backend/app/shared/rag/ingest.py`](../backend/app/shared/rag/ingest.py)

For a given subject `(university, course, branch, sem, subject)`:

1. **List resources.** Walks the four resource categories (`Notes`, `QuestionPapers`, `Syllabus`, `OtherResources`) under `Universities/{uni}/{course}/{branch}/{sem}/{type}/{subject}` in Firestore and collects every doc with a populated `storageId`. Legacy docs (Phase 0 React Native era, Google-Drive-backed) lacking `storageId` are skipped.
2. **Idempotency check.** Reads `RagIndex/{subject_key}.ingestedResourceIds` to filter out resources already processed.
3. **For each pending resource:**
   - Download bytes from Firebase Storage via the Admin SDK.
   - Extract page text with `pypdfium2` ([`pdf_chunker.py`](../backend/app/shared/rag/pdf_chunker.py)).
   - Slide a 2000-character window with 200-character overlap across the page-tagged text, producing chunks that retain `page_start` / `page_end`.
   - Embed in batches via `gemini/gemini-embedding-001` at 768 dimensions ([`embedder.py`](../backend/app/shared/rag/embedder.py)). Throttled to ~85 RPM with exponential-backoff retry on 429s to stay under the free-tier rate limit.
   - Upsert each chunk into `RagChunks/{subject_key}/chunks/{auto-id}` with metadata: `subjectKey`, `subject`, `category`, `resourceId`, `storageId`, `filename`, `pageStart`, `pageEnd`, `chunkIndex`, `text`, and the `embedding` `Vector(768)`.
4. **Mark complete.** Update `RagIndex/{subject_key}` with the new `ingestedResourceIds` and `totalChunks`.

`subject_key` is a flat string `make_subject_key(uni, course, branch, sem, subject)` ([`vector_store.py`](../backend/app/shared/rag/vector_store.py)) — non-alphanumeric characters collapsed to underscores so it's safe as a Firestore document ID.

### 1.2 Vector store

Chunks are searched via Firestore's native `find_nearest` API with cosine distance. The wrapper at [`vector_store.search()`](../backend/app/shared/rag/search_tool.py) accepts an optional `resource_id_filter` argument to scope the search to chunks of a single source PDF — used by the AllyBot chat feature.

Two composite vector indexes are required:

| Use | Index |
|---|---|
| Subject-wide vector search | `chunks` collection-group, vector index on `embedding` |
| Per-PDF vector search (resource-scoped) | `chunks` collection-group, composite index on `resourceId ASC + embedding` |

Both are created via `gcloud firestore indexes composite create`.

### 1.3 RAG search tool

[`backend/app/shared/rag/search_tool.py`](../backend/app/shared/rag/search_tool.py) wraps the search in a `crewai.tools.BaseTool` named `search_subject_documents`. The tool is constructed per-request bound to a `subject_key`. Agents call it with a query string and `top_k`.

Two important design decisions:

1. **Both `_run` and `_arun`.** When CrewAI is invoked via `akickoff` (our default), it dispatches `_arun`. When invoked synchronously from inside an async loop, calling `asyncio.run` directly fails — so `_run` bridges to `_arun` via a worker thread.
2. **Resource IDs surfaced to agents, not just filenames.** The formatted result block includes `(resourceId=XYZ, ...)` next to each chunk's filename. This is the foundation for clickable citations in Snap-a-Doubt — agents cite by stable Firestore IDs, never lossy filename strings.

### 1.4 CrewAI hierarchical crew factory

[`backend/app/shared/crew_factory.py`](../backend/app/shared/crew_factory.py)

Every feature crew is built through `build_hierarchical_crew(agents, tasks, step_callback)`. The factory:

- Provisions a manager LLM (Gemini, temperature 0.1) automatically — agents only have to define their workers
- Sets `Process.hierarchical` so the manager delegates to specialists
- Sets `memory=False` (avoids the ChromaDB long-term-memory dependency that conflicted with our deployment)
- Caps `max_rpm` to keep the crew polite to Gemini's free tier

### 1.5 Live progress tracker

[`backend/app/shared/progress.py`](../backend/app/shared/progress.py)

Every feature crew gets a `make_crewai_step_callback(run_id, agent_name_map)`. After each agent step, the callback writes to `AnalysisRuns/{run_id}.agents.{tracker_name}` in Firestore, marking that specific agent done. The Flutter UI subscribes to this document via a `StreamProvider` and renders agent checkmarks live.

Tracker names per feature:
- PYQ: `syllabus`, `webResearch`, `pattern`, `predictor`, `formatter`
- Study Planner: `importance`, `mastery`, `effort`, `scheduler`
- Adversarial Examiner: `topicSelector`, `trapMiner`, `questionGenerator`, `formatter`
- Snap-a-Doubt: `vision`, `retriever`, `solver`, `validator`

Dual-write fallback: if `firebase_admin` is not initialised (e.g., during local smoke tests without service-account credentials), the tracker falls back to a process-local dict so feature code is unchanged.

### 1.6 Caching layer

[`backend/app/shared/cache.py`](../backend/app/shared/cache.py)

PYQ Analyzer and Adversarial Examiner output is cached in Firestore for 24 hours, keyed by request parameters. Re-running the same `(uni, course, branch, sem, subject)` hits cache and returns instantly without re-running the crew. Same dual-write fallback as the progress tracker.

---

## 2. Feature — PYQ Analyzer

[`backend/app/features/pyq_analyzer/`](../backend/app/features/pyq_analyzer/)

**Purpose.** Predict the questions most likely to appear in the student's next exam, with topic weights and likelihood scores grounded in actual past papers.

**Endpoint.** `POST /pyq_analyze`

**Input.** `PyqAnalyzeRequest{run_id, university, course, branch, sem, subject, pyq_resource_ids, force_refresh}`

**Output.** `PyqAnalysisOutput{subject, topic_weights{topic: weight}, predicted_questions[{question, topic, expected_marks, likelihood, source_paper_ids}], source_resource_ids}`

### 2.1 Agent crew

Five specialist agents plus an auto-provisioned hierarchical manager. Four of the five carry the RAG search tool; the Output Formatter is pure restructuring.

| # | Agent | Tools | Job |
|---|---|---|---|
| 1 | Syllabus Researcher | RAG search + Tavily web search | Produces the official topic list for the subject. RAG-first; Tavily as fallback when the indexed syllabus is incomplete. |
| 2 | Web Researcher | RAG search + Tavily | Mines past-paper patterns. Tags each insight as `[INDEXED]` or `[WEB]` for transparency. |
| 3 | Pattern Analyst | RAG search | Synthesises a ranked top-5–6 topic list with mark-distribution percentages. Cites filename + page for each frequency claim. |
| 4 | Question Predictor | RAG search | Drafts 5–8 likely questions in JNTUH/OU style. Records `source_paper_ids` of any indexed papers it modelled the question on. |
| 5 | Output Formatter | none | Packages prior outputs into a Pydantic-validated JSON. Uses `output_pydantic=PyqAnalysisOutput` so CrewAI validates shape automatically. |

Tasks are chained — each task's `context` includes prior tasks so accumulated findings flow forward without re-querying.

### 2.2 End-to-end flow

```
Flutter request
  ↓
Lazy-ingest if RAG missing for the subject
  ↓
init_tracker(run_id, agents=[syllabus, webResearch, pattern, predictor, formatter])
  ↓
Hierarchical crew kickoff:
  manager → syllabus_researcher → web_researcher → pattern_analyst
         → question_predictor → output_formatter
  ↓
Crew returns Pydantic-validated PyqAnalysisOutput
  ↓
Cache to PyqAnalysis/{path} (24h)
  ↓
Mark run complete
  ↓
Return JSON to Flutter
```

### 2.3 Demo behaviour

Each predicted question carries:
- A `topic` it tests
- An `expected_marks` value (2 / 5 / 10 / 16, the standard JNTUH/OU mark bands)
- A `likelihood` score in 0.30–0.95 (calibrated by the agent's prompt to never claim 0.99 confidence)
- A `source_paper_ids` list pointing at the actual indexed past papers it modelled the question on

The Flutter PYQ screen renders the topic-weights map as a chart and the predicted-questions list as expandable cards.

---

## 3. Feature — Study Planner

[`backend/app/features/study_planner/`](../backend/app/features/study_planner/)

**Purpose.** Generate a personalised day-by-day study schedule from today through the exam date, given the student's subjects, daily time budget, and any self-reported weak topics.

**Endpoint.** `POST /generate_study_plan`

**Input.** `StudyPlanRequest{run_id, uid, university/course/branch/sem, subjects[], exam_date, daily_study_minutes, weak_topics[]}`

**Output.** `StudyPlanOutput{plan_id, exam_date, subjects, days[StudyDay{date, tasks[StudyTask{subject, topic, duration_minutes, rationale, completed}]}], overall_strategy}`

### 3.1 Agent crew — toolless, pre-fetched context

Four agents — but unlike PYQ, none of them carry the RAG search tool. Instead, the relevant signals are pre-fetched server-side and **injected as text into each agent's task description.**

This design exists because the Study Planner reasons across multiple subjects simultaneously, but CrewAI's tool dispatcher conflates tool instances with the same name. Pre-fetching avoids the multi-subject tool-naming issue, removes per-step tool latency, and gives the crew strict deterministic data to reason over.

| # | Agent | Pre-fetched data injected into prompt |
|---|---|---|
| 1 | Topic Importance Analyzer | Per-subject context block: cached PYQ topic weights (if available) + top-4 indexed-document hits for "important topics" |
| 2 | Mastery Reader | `Users/{uid}/MasteryScores` snapshot — per-topic scores from past Adversarial Examiner runs + the user's `weak_topics` input |
| 3 | Effort Estimator | Per-subject Notes density (chunk counts) — proxy for material depth |
| 4 | Schedule Planner | All of the above (via task `context`) + today's date + exam date + daily minutes |

### 3.2 Pre-fetch step

Before the crew runs, [`crew.py`](../backend/app/features/study_planner/crew.py) `_build_subjects_context` does:

1. For each subject, ensure RAG is indexed.
2. Read cached `PyqAnalysis/{path}` if it exists — use those `topicWeights` directly.
3. Otherwise, embed the query "important topics frequently asked exam questions" and pull top-4 chunks via vector search.
4. Count Notes chunks for the subject (effort proxy).
5. Read user's `MasteryScores` from Firestore.

All this is materialised into `subjects_context` and `effort_snapshot` strings injected into the task descriptions verbatim.

### 3.3 Date anchoring

A subtle but critical detail. The agent doesn't know what day it is — without explicit anchors, it tends to invent plan dates that don't match reality (e.g., assuming a 2024 starting point). Three values are passed via `inputs`:

- `today_iso` — UTC date when the request was received
- `exam_date_iso` — request's exam date
- `days_until_exam` — clamp to ≥ 1

The `plan_schedule` task description bolds these as "DATE ANCHORS — do not invent dates" with explicit instructions that every output `date` field must be an ISO date starting from `today_iso` and ending on `exam_date_iso`.

### 3.4 Persistence

The route writes the plan to `Users/{uid}/StudyPlans/{plan_id}` so the Flutter Study Planner list (a Firestore stream) picks it up automatically. The existing detail screen renders day cards with task checkboxes unchanged.

### 3.5 Constraints enforced in the prompt

- Hard daily budget cap: `daily_study_minutes`
- No subject scheduled more than 2 consecutive days
- Last 2 days reserved for revision (no new topics)
- Priority = `topic_weight × (1 − mastery)` — high-weight low-mastery topics get the most time and the earliest days
- Rationale field must use natural language; explicit prompt guard against leaking internal jargon ("222/260 chunks", "mastery 0.5")

---

## 4. Feature — Adversarial Examiner

[`backend/app/features/adversarial_examiner/`](../backend/app/features/adversarial_examiner/)

**Purpose.** Generate a quiz of trap questions designed to expose blind spots in the student's understanding — the kinds of questions where students typically lose marks.

**Endpoint.** `POST /generate_adversarial_exam`

**Input.** `AdversarialRequest{run_id, university/course/branch/sem, subject, focus_topics[], question_count, force_refresh}`

**Output.** `AdversarialExamOutput{subject, overall_focus, questions[{topic, question, trap_type, common_mistake, correct_approach, expected_marks, difficulty, source_paper_ids}]}`

### 4.1 Agent crew

Four agents, single subject per request (so the standard `search_subject_documents` tool works without the multi-subject naming issue).

| # | Agent | Tools | Job |
|---|---|---|---|
| 1 | Topic Selector | RAG search | Picks 4–6 topics where students typically lose marks. Searches for "common mistakes", "distinguish between", "often confused" patterns in indexed notes + question banks. |
| 2 | Trap Pattern Miner | RAG search | For each topic, identifies the specific trap phrasings examiners use. Looks for "differentiate between", "state the conditions under which", "what happens if", and questions that mix two related concepts. |
| 3 | Adversarial Question Generator | RAG search | Generates new questions following those trap patterns, with `trap_type`, `common_mistake`, and `correct_approach` annotations. |
| 4 | Output Formatter | none | Pydantic-validated JSON. |

### 4.2 Why this is different from a "hard quiz" generator

Two design choices distinguish it:

1. **Trap-pattern mining.** The Trap Miner agent's prompt explicitly hunts for the trap categories examiners actually use — confusable concepts, missing-assumption traps, edge-case probes. The output isn't "harder questions", it's questions that target the exact failure modes students have on this subject.
2. **Diagnostic metadata, not just questions.** Each question is paired with the `common_mistake` it tests and the `correct_approach`. The student isn't getting a quiz — they're getting an annotated map of their likely failure modes.

### 4.3 Caching

Output cached at `AdversarialExams/{uni}/{course}/{branch}/{sem}/{subject}__{focus}__q{count}` for 24h. Document ID packs subject + focus + count into a single segment so the path remains an even-segment-count valid Firestore document path.

---

## 5. Feature — Snap-a-Doubt

[`backend/app/features/snap_doubt/`](../backend/app/features/snap_doubt/)

**Purpose.** A student takes a photo of a doubt — handwritten or printed. The system reads the question with vision, retrieves relevant theory from the student's notes, produces a worked solution with clickable citations to the source PDFs.

**Endpoint.** `POST /solve_doubt`

**Input.** `SnapDoubtRequest{run_id, uid, doubt_id, storage_id, university/course/branch/sem, subject}`

**Output.** `DoubtSolutionOutput{extracted_question, subject, topic, steps[{index, description, latex?, citations[{filename, page_start, page_end, storage_id, resource_id, category}]}], final_answer}`

### 5.1 Vision pre-step (not a CrewAI agent)

[`backend/app/features/snap_doubt/vision.py`](../backend/app/features/snap_doubt/vision.py)

CrewAI 1.x supports multimodal LLMs but image-input plumbing through agents is brittle. Cleaner: do the vision call as a plain `litellm.acompletion` call before the crew kicks off.

The vision step:
1. Downloads image bytes from Firebase Storage via firebase-admin.
2. Base64-encodes for Gemini's data-URL format.
3. Calls `gemini/gemini-2.5-flash` (the multimodal-capable model) with a structured prompt that demands `QUESTION:`, `GIVEN VALUES:`, `WHAT TO FIND:` blocks — or a sentinel `NO_QUESTION_DETECTED` if the image is unreadable.
4. After success, calls `update_agent_status(run_id, "vision", "done")` so the UI renders it as a regular agent checkmark — Flutter sees it as the first of four agents.

If `NO_QUESTION_DETECTED` is returned, the route raises a typed `ValidationError` mapped to a clean 400 with a friendly retry message — no crew runs, no wasted LLM calls.

### 5.2 Agent crew

After vision, the extracted question text is passed to a four-agent CrewAI crew:

| # | Agent | Tools | Job |
|---|---|---|---|
| 1 | Notes Retriever | RAG search | Pulls 4–6 most relevant chunks from the subject's indexed notes for this specific question. |
| 2 | Step Solver | none | Produces a numbered solution. Each fact lifted from notes is annotated with `[CITE:resourceId:page]` markers inline. |
| 3 | Solution Validator | none | Second-opinion review. Checks: does the answer match the question? Do steps follow logically? Are units consistent? Surfaces issues for the formatter to weave into specific steps. |
| 4 | Output Formatter | none | Strips `[CITE:...]` markers from descriptions, parses them into a structured `citations` list per step. Splits multi-part questions (1a, 1b, 1c) into separate steps. |

### 5.3 ID-based citation system

The single most important design choice in this feature.

The Notes Retriever's output includes `(resourceId=<firestore-id>, ...)` for each chunk. The Solver is instructed to cite by `resourceId` (stable Firestore IDs), **not by filename** (lossy strings with spaces, casing drift, parentheses).

After the crew finishes, [`crew.py`](../backend/app/features/snap_doubt/crew.py) `_resolve_citations` runs:

1. Build a `{resource_id: doc}` index from the subject's resource collection — a single Firestore traversal.
2. For each citation in each step, look up the `resource_id` directly. Populate `filename`, `storage_id`, and `category` from the resolved doc.
3. If the `resource_id` doesn't match anything in the index, fall back to `filename = "(unknown source)"` and leave `storage_id` null — the Flutter UI renders such citations as non-clickable plain chips.

100% accurate when the agent uses a resource ID it actually saw in the search results — no fuzzy-matching false positives.

### 5.4 Clickable citations end-to-end

Flutter renders each `SolutionStep`'s citations as a horizontal `Wrap` of chips. Tapping a chip:

```
chip.onTap
  → context.push('/pdf-viewer?storageId=...&page=...')
  → PdfViewerScreen.initState  (in addPostFrameCallback)
  → _bootstrapPdf()
  → FirebaseStorage.ref(storageId).getDownloadURL()
  → http stream-download to local cache
  → setState(_localFilePath = path)
  → PDFView(filePath: _localFilePath, defaultPage: initialPage - 1)
  → PDF opens on the cited page
```

The PDF viewer uses `flutter_pdfview`'s `defaultPage` plus a deferred `controller.setPage()` after first render to ensure the page jump lands even on platforms where `defaultPage` is ignored on first paint.

### 5.5 Flutter UI flow

1. User taps Snap-a-Doubt → subject picker (modal) → image source picker (camera or gallery) → image picker
2. Image bytes uploaded to Firebase Storage at `Doubts/{uid}/{doubtId}.jpg`
3. POST /solve_doubt with the storage path
4. `_SolveSheet` opens, listens to `analysisRunProvider(runId)` for live agent checkmarks
5. On success, the sheet replaces the loading view with `_SolutionBody`: extracted question, numbered steps with citation chips, final answer
6. Doubt persists to `Users/{uid}/DoubtHistory/{doubt_id}` — the existing history list (a Firestore stream) auto-updates

---

## 6. Feature — AllyBot chat

[`backend/app/features/chat_about_pdf/`](../backend/app/features/chat_about_pdf/)

**Purpose.** Conversational Q&A scoped to one specific PDF. Replaces the dead Phase 0 Netlify ChatPDF integration.

**Endpoint.** `POST /chat_about_pdf`

**Input.** `ChatRequest{uid, university/course/branch/sem/subject, resource_id, question, prior_turns[]}`

**Output.** `ChatResponse{reply, citations[{page_start, page_end}], grounded}`

### 6.1 Why no multi-agent crew

Chat needs sub-5s latency per turn — students will not wait 60s for "thanks for asking". Multi-agent crews are fundamentally too slow for that turn budget.

So this feature is **not a crew**. It's a single-LLM-call handler ([`handler.py`](../backend/app/features/chat_about_pdf/handler.py)) — but it still uses the shared RAG infrastructure, just inline:

```
1. embed_one(question) → 768-d query vector
2. search(subject_key, query_embedding, top_k=5,
          resource_id_filter=req.resource_id)
   → top 5 chunks from THIS specific PDF only
3. Build a system prompt that includes the chunks as
   labelled excerpts with their page tags
4. Single litellm.acompletion call with last 10 prior_turns + question
5. Return reply + page citations + grounded boolean
```

### 6.2 Resource-scoped vector search

The key technical move: `vector_store.search()` accepts an optional `resource_id_filter`. Inside, it adds a `where("resourceId", "==", filter)` clause before the `find_nearest` call. The result is a vector search restricted to chunks belonging to one specific PDF.

This requires a composite Firestore index: `resourceId ASC + embedding vector`. Created via:

```bash
gcloud firestore indexes composite create \
  --project=academic-ally-app \
  --collection-group=chunks \
  --query-scope=COLLECTION \
  --field-config=order=ASCENDING,field-path=resourceId \
  --field-config=field-path=embedding,vector-config='{"dimension":"768","flat":"{}"}'
```

### 6.3 Honest grounding

The system prompt enforces three rules:

- Cite specific page numbers using `(p.N)` or `(pp.N–M)` inline. Use only the page spans shown in the excerpt headers — never invent.
- If the excerpts don't cover the question, say so explicitly: "I couldn't find that in this document — let me give you a general answer." Then answer using general knowledge but flag it clearly.
- Keep replies concise (2–5 short paragraphs at most).

The `grounded: bool` field in the response is true when the RAG search returned at least one chunk — false otherwise. Flutter can use this to render "answered from your notes" vs "general answer" badges.

### 6.4 Flutter integration

The original Phase 0 implementation called a Netlify cloud function (`/chat/initiate`, `/chat/message`) that wrapped ChatPDF. That endpoint is dead — Snap-a-Doubt's "Failed to initiate chat" error stemmed from this.

The replacement at [`allybot_provider.dart`](../lib/features/allybot/providers/allybot_provider.dart):

- `initiateChat` no longer calls a remote service. It just persists a Firestore session record at `Users/{uid}/InitializedPdf/{sessionId}` with the metadata our backend needs (`resourceId`, `storageId`, `university`, `course`, `branch`, `sem`, `subject`).
- `sendMessage` reads the session metadata, posts to `/chat_about_pdf` with the prior turns, and appends both the user message and the bot reply to the Firestore conversation log.

The existing chat UI (`ally_chat_screen.dart`) renders the conversation directly from the Firestore stream and didn't need changes beyond the metadata-passing.

---

## 7. Cross-cutting concerns

### 7.1 Authentication

[`backend/app/deps.py`](../backend/app/deps.py)

A single FastAPI dependency `get_uid` is used by every endpoint. It accepts two `Authorization` schemes:

- `Bearer <firebase_id_token>` — verified by the Firebase Admin SDK. The token's `uid` is the caller identity.
- `Admin <BACKEND_ADMIN_KEY>:<uid>` — a development bypass for curl/Postman testing. The key is constant-time-compared against `BACKEND_ADMIN_KEY` from `.env`. The supplied `uid` is trusted.

### 7.2 Error envelope

Every endpoint catches exceptions, maps them to a typed `AIBackendError` subclass, and returns:

```json
{
  "detail": {
    "error": "<user-facing message from errors.user_facing_message>",
    "debug_error": "<truncated exception text>",
    "debug_traceback": "<truncated traceback>"
  }
}
```

The Flutter `_extractErrorMessage` parser looks at `body['detail']` first (FastAPI's standard wrapper) before falling back to `body['error']`. `AgentBackendException.toString()` returns just `message` (no `(401):` prefix) so error UIs render cleanly.

### 7.3 Model rotation under quota pressure

Gemini's free tier has separate daily request buckets per model:

- `gemini-2.5-flash-lite` — 200 RPD, fastest, lowest quality
- `gemini-2.5-flash` — separate bucket, used for vision (Snap-a-Doubt) since lite doesn't reliably do multimodal
- `gemini-2.0-flash` — separate bucket, used as fallback when lite is exhausted

`LLM_MODEL` in `.env` controls which model the crew agents use. Changing it requires no code change — both the crew factory and the manager LLM read it from the environment.

### 7.4 Resource model robustness

[`lib/models/resource_model.dart`](../lib/models/resource_model.dart)

The Phase 0 React Native era stored numeric fields as doubles (`views: 1.0`), `units` sometimes as a string, `sem` sometimes as int, and `date` as either a `Timestamp`, an int (millis), or a double. `ResourceModel.fromFirestore` defensively coerces all of these:

- `(data['views'] as num?)?.toInt() ?? 0`
- `_parseUnits(data['units'])` — handles List, comma-separated String, or null
- `data['sem']?.toString() ?? ''`
- `_parseDate(data['date'])` — handles Timestamp, num, ISO String, or null

`resourcesProvider` further filters out legacy docs without `storageId` (Drive-backed PDFs we can't fetch) so users never see dead-link entries in the resource list.

### 7.5 Riverpod 3.x post-frame deferrals

Riverpod 3.x is strict about provider mutations during widget build. Two places needed `Future.microtask` or `addPostFrameCallback` to defer mutations:

- `_showSolveSheet` in Snap-a-Doubt — wraps `reset()` + `solve()` so the modal mounts before state changes.
- `PdfViewerScreen.initState` — auto-download + view tracking + recents-update all run inside `addPostFrameCallback` rather than directly in `initState`.

This pattern is also used in PYQ Analyzer / Adversarial Examiner screens for the auto-select-first-subject behaviour.

---

## Endpoints summary

| Endpoint | Feature | Latency target | Auth |
|---|---|---|---|
| `GET /health` | Sanity-check config | <100ms | none |
| `POST /pyq_analyze` | PYQ Analyzer | 60–120s | Firebase / Admin |
| `POST /generate_study_plan` | Study Planner | 60–120s | Firebase / Admin |
| `POST /generate_adversarial_exam` | Adversarial Examiner | 60–120s | Firebase / Admin |
| `POST /solve_doubt` | Snap-a-Doubt | 60–120s | Firebase / Admin |
| `POST /chat_about_pdf` | AllyBot chat | 3–6s | Firebase / Admin |

---

## Agent count

Around 14 distinct agents across the platform:

- PYQ Analyzer: 5 + auto manager
- Study Planner: 4 + auto manager
- Adversarial Examiner: 4 + auto manager
- Snap-a-Doubt: 4 + auto manager + 1 vision pre-step
- AllyBot chat: 0 (single LLM call by design)

Each is a CrewAI `Agent` instance with its own role, goal, backstory, tools, and prompt. The shared platform makes adding a 6th, 7th, Nth feature primarily a matter of writing new agents and tasks against the existing RAG, search, progress, and crew infrastructure.
