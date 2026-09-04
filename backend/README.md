# Academic Ally — Local FastAPI Backend

**The** AI backend for Academic Ally — a FastAPI service hosting all five agentic features (PYQ Analyzer, Study Planner, Adversarial Examiner, Snap a Doubt, AllyBot) plus the shared RAG layer. This replaced the Cloud Functions approach in [`functions_py/`](../functions_py/), which is now LEGACY and no longer called by the app. Runs on `localhost:8000` for development and deploys to Railway for production. The current production service is `https://academic-ally-production-503f.up.railway.app`.

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
- No scheduled cleanup function of its own. The hourly `cleanup_old_trackers` Cloud Function (source in `functions_py/features/maintenance`, still deployed) deletes stale `AnalysisRuns/{runId}` docs.

This service **is** the production backend (Railway). `functions_py/` is kept only because it is the source of the still-deployed `cleanup_old_trackers` scheduler.

### Firestore behavior

When firebase-admin is initialized (i.e., `GOOGLE_APPLICATION_CREDENTIALS` points at a valid service-account JSON), the backend writes to two collections in your real Firebase project:

- `AnalysisRuns/{runId}` — live progress tracker the Flutter app subscribes to for the agent-checkmark UI
- `PyqAnalysis/{uni}/{course}/{branch}/{sem}/{subject}` — 24h cached result the Flutter app reads to render the analysis

This is required for the Flutter UI to update when running against the local backend. The trade-off is that dev runs land in your prod Firestore. Acceptable for the close-circle demo phase; swap to the Firebase emulator if you want isolation later.

If firebase-admin isn't initialized, both modules silently fall back to a process-local dict — curl tests get sane responses but the Flutter UI won't update.

## Deploying to Railway

The backend is set up for one-click Railway deployment.

### Files involved

- [`Procfile`](Procfile) and [`railway.toml`](railway.toml) — start command + health check
- [`nixpacks.toml`](nixpacks.toml) — pins Python 3.12 + installs via `uv sync --frozen --no-dev`
- [`app/firebase_init.py`](app/firebase_init.py) — accepts service-account credentials as an env var (no file needed)

### One-time setup

1. **Push `master` to GitHub.** Railway watches that branch and auto-deploys every push (project `980e8788-589c-4568-b838-3a28240a4f6e`, service `df9d6092-baa9-4cd1-95a1-b159514b7bf4` on railway.com). After pushing, confirm the deploy actually went live: `GET /health` on the production URL must NOT contain a `demo_fallback_enabled` key — that key only exists in builds older than commit `6ab4eea`.
2. **In Railway, create a new project from the repo, root dir `backend/`.**
3. **Set these environment variables on the Railway service:**

   | Name | Value |
   |---|---|
   | `GEMINI_API_KEY` | Google AI Studio key |
   | `TAVILY_API_KEY` | Tavily search key |
   | `BACKEND_ADMIN_KEY` | Long random string for the admin auth bypass |
   | `BACKEND_STORAGE_BUCKET` | `academic-ally-app.appspot.com` |
   | `FIREBASE_SERVICE_ACCOUNT_JSON` | Full content of `service-account.json` (see below) |
   | `LLM_MODEL` (optional) | Defaults to `gemini/gemini-2.5-flash-lite` |
   | `LOG_LEVEL` (optional) | Defaults to `INFO` |
   | `EXPOSE_DEBUG_ERRORS` (optional) | Defaults to `false`. When `true`, failed AI requests also return `debug_error` / `debug_traceback` in the error body. Keep it off in production. |

4. **Deploy.** Railway will run `uv sync --frozen --no-dev` then `uv run uvicorn …`.
5. **Point Flutter at the Railway URL.** Production defaults to the URL in `lib/core/constants/app_constants.dart`; override it for a particular run or build with `--dart-define=AI_BACKEND_BASE_URL=https://<your-service>.up.railway.app`.

### Setting `FIREBASE_SERVICE_ACCOUNT_JSON`

Two equivalent formats — either works:

**Raw JSON (paste the full contents):**

```
{"type":"service_account","project_id":"academic-ally-app","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"firebase-adminsdk-...@academic-ally-app.iam.gserviceaccount.com","client_id":"...","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"...","universe_domain":"googleapis.com"}
```

Railway accepts multi-line values, but the JSON form above also works on a single line.

**Base64 (safer if Railway's UI mangles special chars):**

```bash
base64 -i service-account.json | pbcopy   # macOS
# or
base64 -w0 service-account.json            # Linux
```

Paste the resulting string. The backend auto-detects raw vs base64 in [`firebase_init.py`](app/firebase_init.py).

### Verifying the deploy

Two levels. The quick one hits the public URL:

```bash
curl https://academic-ally-production-503f.up.railway.app/health
```

Expect `firebase_credential_source: "service_account_env"` and `firebase_initialized: true`, and **no** `demo_fallback_enabled` key (that key only exists in builds older than `6ab4eea` — if you see it, the deploy did not pick up current `master`).

The real one proves Gemini works through the deployed service exactly as the app calls it:

```bash
uv run python scripts/verify_prod_ai.py            # defaults to the production URL
```

It mints a Firebase ID token for a throwaway user, runs one genuine Study Planner crew (a few rupees of Gemini), prints the outcome, and deletes the test user and every document it created. Exit code 0 means real AI output was produced; a `429 … prepayment credits are depleted` failure means the `GEMINI_API_KEY` on the service is the wrong key.

### Cost watch

Railway sleeps idle services on the free tier, so first request after idle can spike to 30 seconds while the container wakes. That's separate from the cold-start of CrewAI imports (~5–10 seconds). Together, the very first uncached PYQ run after a long idle gap can take ~150 seconds.
