# Academic Ally — Local FastAPI Backend

Local dev mirror of the PYQ Analyzer agent crew that ships as a Firebase Cloud Function in [`functions_py/`](../functions_py/). Same agent prompts, same response shape — but runs on `localhost:8000` so iteration doesn't need a deploy.

## Setup

1. Install [uv](https://docs.astral.sh/uv/).
2. Copy `.env.example` to `.env` and fill in keys:
   - `GEMINI_API_KEY` — from Google AI Studio
   - `TAVILY_API_KEY` — from tavily.com (free tier: 1000 searches/month)
   - `BACKEND_ADMIN_KEY` — any long random string
   - `GOOGLE_APPLICATION_CREDENTIALS` — absolute path to a Firebase service-account JSON (download from Firebase console → Project Settings → Service Accounts)
3. `./run.sh`

`uv sync` materializes `.venv/` on first run; subsequent starts are instant.

## Endpoints

### `GET /health`

Sanity-check config without auth. Reports which env vars are populated and the active LLM model.

```bash
curl http://localhost:8000/health
```

### `POST /pyq_analyze`

Run the 5-agent PYQ Analyzer crew. Same request/response shape as the deployed Firebase Function.

**Auth — two schemes accepted:**

| Scheme | Header | When |
|---|---|---|
| Firebase ID token | `Authorization: Bearer <id_token>` | Flutter app, real users |
| Admin bypass | `Authorization: Admin <BACKEND_ADMIN_KEY>:<uid>` | curl/Postman dev |

**Request body** (matches what the Flutter client already sends):

```json
{
  "run_id": "smoke-1",
  "university": "JNTUH",
  "course": "BTECH",
  "branch": "CSE",
  "sem": "3",
  "subject": "Database Management Systems",
  "pyq_resource_ids": [],
  "force_refresh": true
}
```

**Smoke test with admin bypass:**

```bash
source .env  # or `export $(grep -v '^#' .env | xargs)`
curl -X POST http://localhost:8000/pyq_analyze \
  -H "Content-Type: application/json" \
  -H "Authorization: Admin $BACKEND_ADMIN_KEY:test-uid" \
  -d '{
    "run_id": "smoke-1",
    "university": "JNTUH",
    "course": "BTECH",
    "branch": "CSE",
    "sem": "3",
    "subject": "Database Management Systems",
    "pyq_resource_ids": [],
    "force_refresh": true
  }'
```

Expect 60–120s, then JSON with `subject`, `topicWeights`, `predictedQuestions`, `sourceResourceIds`. Backend console logs each agent transition.

## Layout

```
app/
├── main.py                       # FastAPI app, CORS, route mount, /health
├── settings.py                   # pydantic-settings (env)
├── deps.py                       # get_uid auth dependency
├── errors.py                     # typed exception hierarchy
├── shared/
│   ├── llm.py                    # CrewAI LLM (Gemini via litellm)
│   ├── tavily_tool.py            # CrewAI Tavily search tool
│   ├── crew_factory.py           # build_hierarchical_crew helper
│   ├── progress.py               # in-memory run tracker
│   └── cache.py                  # in-memory TTL cache
└── features/pyq_analyzer/
    ├── schema.py                 # Pydantic request/output
    ├── agents.py                 # 5 specialist agents
    ├── tasks.py                  # 5 chained tasks
    ├── crew.py                   # async run_pyq_analysis (akickoff)
    └── routes.py                 # POST /pyq_analyze
```

## Differences from `functions_py/`

- Python-only (no firebase_functions decorator) — this is a regular HTTP service
- `await crew.akickoff(...)` instead of sync `crew.kickoff(...)` for non-blocking event loop
- Progress + cache write to **Firestore when `GOOGLE_APPLICATION_CREDENTIALS` is set**, otherwise fall back to an in-memory dict (curl smoke tests still work without Firebase creds)
- Auth supports an `Admin` scheme for keyless dev requests
- No scheduled cleanup function (`AnalysisRuns/{runId}` docs accumulate; the prod scheduler in `functions_py/features/maintenance` cleans them up)

`functions_py/` remains the deploy target. This service is purely for local iteration.

### Firestore behavior

When firebase-admin is initialized (i.e., `GOOGLE_APPLICATION_CREDENTIALS` points at a valid service-account JSON), the backend writes to two collections in your real Firebase project:

- `AnalysisRuns/{runId}` — live progress tracker the Flutter app subscribes to for the agent-checkmark UI
- `PyqAnalysis/{uni}/{course}/{branch}/{sem}/{subject}` — 24h cached result the Flutter app reads to render the analysis

This is required for the Flutter UI to update when running against the local backend. The trade-off is that dev runs land in your prod Firestore. Acceptable for the close-circle demo phase; swap to the Firebase emulator if you want isolation later.

If firebase-admin isn't initialized, both modules silently fall back to a process-local dict — curl tests get sane responses but the Flutter UI won't update.
