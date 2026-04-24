# Phase 4 PYQ Analyzer — Multi-Agent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the PYQ Analyzer's `MockAIService` with a real multi-agent CrewAI workflow running on a Python Firebase Cloud Function, using Minimax as the LLM and Tavily for web search, with progressive loading UX via Firestore-streamed progress tracking.

**Architecture:** New Python 3.12 Firebase Functions Gen 2 codebase at `functions_py/` lives alongside the existing Node.js `functions/` codebase. Shared infra modules (auth, LLM, Tavily tool, cache, progress, errors, crew factory) are reusable for the remaining 5 AI features ported in later plans. First feature wired end-to-end is PYQ Analyzer. Flutter's `aiServiceProvider` swaps from `MockAIService` to a new `AgentAIService` that POSTs to the HTTPS endpoint.

**Tech Stack:** Python 3.12, CrewAI, LangChain (OpenAI-compat for Minimax), Tavily, Firebase Functions Gen 2 (Python runtime), Firebase Firestore (cache + progress), Firebase Auth (ID token verification), Flutter + Riverpod on the client.

**Spec reference:** `docs/superpowers/specs/2026-04-20-multi-agent-langgraph-design.md` (commit `199238e`)

---

## File structure

New files created:

```
academic_ally/
├── functions_py/                        # NEW Python Firebase Functions codebase
│   ├── main.py                          # HTTPS endpoint exports
│   ├── requirements.txt                 # Python dependencies
│   ├── .python-version                  # "3.12"
│   ├── .gitignore                       # __pycache__, *.pyc, .venv
│   ├── shared/
│   │   ├── __init__.py                  # empty marker
│   │   ├── auth.py                      # Firebase ID token verifier decorator
│   │   ├── minimax_llm.py               # CrewAI LLM config for Minimax
│   │   ├── tavily_tool.py               # CrewAI tool wrapping Tavily search
│   │   ├── cache.py                     # Firestore cache read/write
│   │   ├── progress.py                  # AnalysisRuns progress tracker + step callback
│   │   ├── errors.py                    # Typed exceptions + user-facing mapping
│   │   └── crew_factory.py              # Reusable Crew builder
│   ├── features/
│   │   ├── __init__.py
│   │   ├── maintenance/
│   │   │   ├── __init__.py
│   │   │   └── cleanup.py               # cleanupOldTrackers scheduled function
│   │   └── pyq_analyzer/
│   │       ├── __init__.py
│   │       ├── schema.py                # Pydantic input + output models
│   │       ├── agents.py                # 5 agent definitions
│   │       ├── tasks.py                 # 5 task definitions
│   │       ├── crew.py                  # Crew assembly + run_analysis()
│   │       └── handler.py               # HTTP handler for /ai/pyq-analyze
│   └── tests/
│       ├── __init__.py
│       ├── conftest.py                  # pytest fixtures
│       ├── test_auth.py                 # unit tests for auth verifier
│       ├── test_cache.py                # unit tests for cache helpers
│       ├── test_progress.py             # unit tests for progress tracker
│       └── test_errors.py               # unit tests for error mapping
├── lib/
│   ├── core/
│   │   ├── services/ai/
│   │   │   └── agent_ai_service.dart    # NEW — replaces MockAIService
│   │   ├── providers/
│   │   │   └── ai_provider.dart         # MODIFIED — swaps to AgentAIService
│   │   └── constants/
│   │       └── app_constants.dart       # MODIFIED — adds aiBackendBaseUrl
│   └── features/
│       └── pyq_analyzer/
│           ├── providers/
│           │   └── analysis_run_provider.dart   # NEW — streams AnalysisRuns/{runId}
│           └── screens/
│               └── pyq_analyzer_screen.dart     # MODIFIED — shows progressive UI
├── firebase.json                        # MODIFIED — add functions_py codebase
└── .firebaserc                          # (may need creation if absent)
```

Everything else (existing `functions/`, `lib/` outside the above, Flutter screens outside PYQ, Firestore rules) stays untouched.

---

# Phase 1 — Python scaffolding

## Task 1: Create the Python project skeleton

**Files:**
- Create: `academic_ally/functions_py/.python-version`
- Create: `academic_ally/functions_py/.gitignore`
- Create: `academic_ally/functions_py/requirements.txt`
- Create: `academic_ally/functions_py/__init__.py` (empty marker)
- Create: `academic_ally/functions_py/shared/__init__.py` (empty)
- Create: `academic_ally/functions_py/features/__init__.py` (empty)
- Create: `academic_ally/functions_py/features/maintenance/__init__.py` (empty)
- Create: `academic_ally/functions_py/features/pyq_analyzer/__init__.py` (empty)
- Create: `academic_ally/functions_py/tests/__init__.py` (empty)

- [ ] **Step 1: Create `.python-version`**

```
3.12
```

- [ ] **Step 2: Create `.gitignore`**

```
__pycache__/
*.pyc
*.pyo
.venv/
venv/
.pytest_cache/
.coverage
htmlcov/
*.egg-info/
```

- [ ] **Step 3: Create `requirements.txt`**

```
firebase-functions==0.4.3
firebase-admin==6.9.0
crewai==0.98.0
langchain-openai==0.3.7
tavily-python==0.5.1
pydantic==2.10.3
python-dotenv==1.0.1
pytest==8.3.4
pytest-mock==3.14.0
```

- [ ] **Step 4: Create all empty `__init__.py` marker files**

Files to create (each with empty content):
- `functions_py/__init__.py`
- `functions_py/shared/__init__.py`
- `functions_py/features/__init__.py`
- `functions_py/features/maintenance/__init__.py`
- `functions_py/features/pyq_analyzer/__init__.py`
- `functions_py/tests/__init__.py`

- [ ] **Step 5: Commit**

```bash
cd "C:/Devspace/flutterprojects/Academic Ally/academic_ally"
git add functions_py/
git commit -m "feat(functions_py): scaffold Python Firebase Functions codebase

Creates the project skeleton for the Phase 4 multi-agent AI backend.
requirements.txt pins key versions: CrewAI 0.98 (hierarchical process
stable), langchain-openai 0.3 (for Minimax OpenAI-compat), Tavily
Python 0.5 (web search), firebase-functions 0.4.3 (Gen 2 Python).

No endpoint code yet — just module structure + dependency list.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Create a Python virtual environment and install dependencies

**Files:** no files created — this sets up the local dev environment

- [ ] **Step 1: Create venv inside `functions_py/`**

```bash
cd "C:/Devspace/flutterprojects/Academic Ally/academic_ally/functions_py"
python -m venv venv
```

- [ ] **Step 2: Activate venv (Windows PowerShell)**

```powershell
.\venv\Scripts\Activate.ps1
```

Expected: prompt now shows `(venv)` prefix.

If PowerShell blocks with "scripts are disabled on this system":
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```
Then re-run Activate.ps1.

- [ ] **Step 3: Upgrade pip**

```bash
python -m pip install --upgrade pip
```

Expected: pip upgrades to latest.

- [ ] **Step 4: Install dependencies**

```bash
pip install -r requirements.txt
```

Expected: all packages install. Takes 2-4 minutes (crewai + langchain are heavy).

- [ ] **Step 5: Verify install**

```bash
python -c "import crewai; import langchain_openai; import tavily; import firebase_functions; print('all imports OK')"
```

Expected output: `all imports OK`

- [ ] **Step 6: Add venv to .gitignore (already done in Task 1 but verify)**

The `venv/` line was added in Task 1's `.gitignore`. Verify it's there.

- [ ] **Step 7: No commit needed**

This task sets up local state only. No files to commit.

---

## Task 3: Wire Firebase multi-codebase config

**Files:**
- Modify: `academic_ally/firebase.json`
- Create: `academic_ally/.firebaserc` (only if absent — check first)

- [ ] **Step 1: Check if `.firebaserc` exists**

```bash
cd "C:/Devspace/flutterprojects/Academic Ally/academic_ally"
ls -la .firebaserc 2>&1
```

If absent, create it with:
```json
{
  "projects": {
    "default": "academic-ally-app"
  }
}
```

If present, skip creation.

- [ ] **Step 2: Read current `firebase.json`**

```bash
cat firebase.json
```

Expected current content:
```json
{
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "ignore": [
        "node_modules",
        ".git",
        "firebase-debug.log",
        "firebase-debug.*.log",
        "*.local"
      ]
    }
  ],
  "storage": {
    "rules": "storage.rules"
  }
}
```

- [ ] **Step 3: Update `firebase.json` to add the Python codebase**

Replace the content with:
```json
{
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "ignore": [
        "node_modules",
        ".git",
        "firebase-debug.log",
        "firebase-debug.*.log",
        "*.local"
      ]
    },
    {
      "source": "functions_py",
      "codebase": "ai",
      "runtime": "python312",
      "ignore": [
        "venv",
        ".venv",
        "__pycache__",
        "*.pyc",
        ".pytest_cache",
        "tests",
        ".git"
      ]
    }
  ],
  "storage": {
    "rules": "storage.rules"
  }
}
```

- [ ] **Step 4: Verify CLI sees both codebases**

```bash
firebase functions:list --project academic-ally-app 2>&1 | head -5
```

Expected: lists existing `stopBilling` function without errors (no Python functions yet — that's fine).

- [ ] **Step 5: Commit**

```bash
git add firebase.json .firebaserc 2>/dev/null || git add firebase.json
git commit -m "chore(firebase): register functions_py as 'ai' codebase

Adds Firebase multi-codebase config so the new Python AI backend
deploys alongside the existing Node.js stopBilling function without
conflict. Python runtime pinned to 3.12. Tests and venv excluded
from deploy bundle.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

# Phase 2 — Shared infrastructure

## Task 4: Implement `shared/errors.py`

**Files:**
- Create: `academic_ally/functions_py/shared/errors.py`
- Create: `academic_ally/functions_py/tests/test_errors.py`

- [ ] **Step 1: Write the failing test**

File: `functions_py/tests/test_errors.py`

```python
"""Tests for shared.errors — typed exception hierarchy + user-facing mapping."""
import pytest

from functions_py.shared.errors import (
    AIBackendError,
    AuthError,
    RateLimitError,
    TimeoutError as BackendTimeout,
    AgentFailureError,
    user_facing_message,
)


def test_auth_error_maps_to_friendly_message():
    err = AuthError("invalid token")
    assert user_facing_message(err) == "Your session has expired. Please log in again."


def test_rate_limit_error_maps_to_friendly_message():
    err = RateLimitError("minimax 429")
    assert user_facing_message(err) == "AI service is busy. Please try again in a moment."


def test_timeout_error_maps_to_friendly_message():
    err = BackendTimeout("exceeded 180s")
    assert user_facing_message(err) == "Analysis took too long. Try again in a moment."


def test_agent_failure_maps_to_friendly_message():
    err = AgentFailureError("syllabus agent failed")
    assert user_facing_message(err) == "We couldn't complete the analysis this time. Tap to try again."


def test_generic_error_maps_to_catchall():
    err = Exception("something unexpected")
    assert user_facing_message(err) == "Something went wrong. Please try again."
```

- [ ] **Step 2: Run the test to verify failure**

```bash
cd "C:/Devspace/flutterprojects/Academic Ally/academic_ally"
.\functions_py\venv\Scripts\Activate.ps1
pytest functions_py/tests/test_errors.py -v
```

Expected: all 5 tests FAIL with `ModuleNotFoundError: No module named 'functions_py.shared.errors'`.

- [ ] **Step 3: Implement `shared/errors.py`**

File: `functions_py/shared/errors.py`

```python
"""Typed exceptions for the AI backend, with user-facing message mapping.

Internal exceptions carry technical details for logging. ``user_facing_message``
translates them into plain-English strings safe to return in HTTP responses.
"""


class AIBackendError(Exception):
    """Base class for all AI backend errors."""


class AuthError(AIBackendError):
    """Firebase ID token verification failed."""


class RateLimitError(AIBackendError):
    """Upstream LLM or search provider returned 429."""


class TimeoutError(AIBackendError):
    """Overall workflow exceeded its time budget."""


class AgentFailureError(AIBackendError):
    """A worker agent failed after exhausting retries."""


class ValidationError(AIBackendError):
    """Client sent an invalid payload."""


_MESSAGES = {
    AuthError: "Your session has expired. Please log in again.",
    RateLimitError: "AI service is busy. Please try again in a moment.",
    TimeoutError: "Analysis took too long. Try again in a moment.",
    AgentFailureError: "We couldn't complete the analysis this time. Tap to try again.",
    ValidationError: "Request is missing required information.",
}


def user_facing_message(err: Exception) -> str:
    """Translate an internal exception into a plain-English message."""
    for cls, msg in _MESSAGES.items():
        if isinstance(err, cls):
            return msg
    return "Something went wrong. Please try again."
```

- [ ] **Step 4: Run the test to verify pass**

```bash
pytest functions_py/tests/test_errors.py -v
```

Expected: all 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add functions_py/shared/errors.py functions_py/tests/test_errors.py
git commit -m "feat(functions_py): add typed error hierarchy + user-facing mapping

Defines AIBackendError base + AuthError / RateLimitError / TimeoutError
/ AgentFailureError / ValidationError. user_facing_message() maps any
exception to a plain-English string safe for HTTP responses.

Covered by 5 unit tests in test_errors.py.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Implement `shared/auth.py`

**Files:**
- Create: `academic_ally/functions_py/shared/auth.py`
- Create: `academic_ally/functions_py/tests/test_auth.py`

- [ ] **Step 1: Write the failing test**

File: `functions_py/tests/test_auth.py`

```python
"""Tests for shared.auth — Firebase ID token verifier."""
from unittest.mock import patch, MagicMock

import pytest

from functions_py.shared.auth import verify_token, extract_uid
from functions_py.shared.errors import AuthError


def test_verify_token_returns_uid_on_valid():
    with patch("functions_py.shared.auth.firebase_auth") as mock_auth:
        mock_auth.verify_id_token.return_value = {"uid": "user-123", "email": "a@b.c"}
        uid = verify_token("valid-token")
        assert uid == "user-123"
        mock_auth.verify_id_token.assert_called_once_with("valid-token")


def test_verify_token_raises_auth_error_on_invalid():
    with patch("functions_py.shared.auth.firebase_auth") as mock_auth:
        mock_auth.verify_id_token.side_effect = Exception("invalid signature")
        with pytest.raises(AuthError):
            verify_token("bad-token")


def test_extract_uid_reads_bearer_token():
    with patch("functions_py.shared.auth.verify_token") as mock_verify:
        mock_verify.return_value = "user-xyz"
        headers = {"Authorization": "Bearer abc.def.ghi"}
        uid = extract_uid(headers)
        assert uid == "user-xyz"
        mock_verify.assert_called_once_with("abc.def.ghi")


def test_extract_uid_raises_when_header_missing():
    with pytest.raises(AuthError):
        extract_uid({})


def test_extract_uid_raises_when_header_malformed():
    with pytest.raises(AuthError):
        extract_uid({"Authorization": "NotBearer xyz"})
```

- [ ] **Step 2: Run test to verify failure**

```bash
pytest functions_py/tests/test_auth.py -v
```

Expected: all 5 tests FAIL (module not found).

- [ ] **Step 3: Implement `shared/auth.py`**

File: `functions_py/shared/auth.py`

```python
"""Firebase ID token verification helpers.

The verifier assumes ``firebase_admin`` has been initialized elsewhere
(main.py does this on module load). A fresh initialization per request
would be wasteful.
"""
from typing import Mapping

from firebase_admin import auth as firebase_auth

from .errors import AuthError


def verify_token(id_token: str) -> str:
    """Verify a Firebase ID token and return the authenticated user's uid.

    Raises ``AuthError`` if the token is invalid, expired, or revoked.
    """
    if not id_token:
        raise AuthError("missing token")
    try:
        decoded = firebase_auth.verify_id_token(id_token)
    except Exception as exc:
        raise AuthError(f"token verification failed: {exc}") from exc
    return decoded["uid"]


def extract_uid(headers: Mapping[str, str]) -> str:
    """Extract and verify the Firebase ID token from an Authorization header.

    Expected header format: ``Authorization: Bearer <id_token>``.
    """
    auth_header = headers.get("Authorization") or headers.get("authorization")
    if not auth_header:
        raise AuthError("missing Authorization header")
    if not auth_header.startswith("Bearer "):
        raise AuthError("Authorization header must use Bearer scheme")
    id_token = auth_header[len("Bearer "):].strip()
    return verify_token(id_token)
```

- [ ] **Step 4: Run test to verify pass**

```bash
pytest functions_py/tests/test_auth.py -v
```

Expected: all 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add functions_py/shared/auth.py functions_py/tests/test_auth.py
git commit -m "feat(functions_py): add Firebase ID token verifier

verify_token() wraps firebase_admin.auth.verify_id_token() and
translates any failure into AuthError. extract_uid() handles the
'Authorization: Bearer <token>' HTTP header parsing, rejecting
missing or malformed headers cleanly.

Covered by 5 unit tests using mocked firebase_admin.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: Implement `shared/minimax_llm.py`

**Files:**
- Create: `academic_ally/functions_py/shared/minimax_llm.py`

No unit test — this is pure configuration. End-to-end smoke test covers real LLM behavior.

- [ ] **Step 1: Implement `shared/minimax_llm.py`**

File: `functions_py/shared/minimax_llm.py`

```python
"""CrewAI LLM configuration for Minimax.

Minimax exposes an OpenAI-compatible chat-completions endpoint, so we
use CrewAI's built-in ``LLM`` class configured with the OpenAI provider
and point ``base_url`` at Minimax's endpoint.

The API key is read from the ``MINIMAX_API_KEY`` environment variable,
which is populated by Firebase Secrets at runtime (see main.py secrets
declaration).
"""
import os

from crewai import LLM


# Minimax's international OpenAI-compatible endpoint
# Source: https://www.minimaxi.com/en/document/guides/chat-model/pro/api
MINIMAX_BASE_URL = "https://api.minimaxi.chat/v1"

# Default model — tunable via MINIMAX_MODEL env var
_DEFAULT_MODEL = "MiniMax-M2"


def get_minimax_llm(temperature: float = 0.3) -> LLM:
    """Build a CrewAI LLM configured for Minimax.

    Args:
        temperature: Sampling temperature. 0.3 is a good balance for
            structured agent tasks. Agents needing more creativity can
            request a higher value.
    """
    api_key = os.environ.get("MINIMAX_API_KEY")
    if not api_key:
        raise RuntimeError(
            "MINIMAX_API_KEY not set. Configure via "
            "'firebase functions:secrets:set MINIMAX_API_KEY' and "
            "declare the secret on the function."
        )
    model = os.environ.get("MINIMAX_MODEL", _DEFAULT_MODEL)
    return LLM(
        model=f"openai/{model}",
        base_url=MINIMAX_BASE_URL,
        api_key=api_key,
        temperature=temperature,
    )
```

- [ ] **Step 2: Verify it imports cleanly**

```bash
python -c "from functions_py.shared import minimax_llm; print('import ok')"
```

Expected: `import ok`

(The `get_minimax_llm()` function won't actually succeed until the env var is set — that's expected for local dev.)

- [ ] **Step 3: Commit**

```bash
git add functions_py/shared/minimax_llm.py
git commit -m "feat(functions_py): add Minimax LLM config for CrewAI

Wraps CrewAI's LLM class with Minimax's OpenAI-compatible endpoint.
API key read from MINIMAX_API_KEY (populated by Firebase Secrets at
runtime). MINIMAX_MODEL env var allows overriding the default model.

No unit test — pure configuration. End-to-end smoke covers behavior.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: Implement `shared/tavily_tool.py`

**Files:**
- Create: `academic_ally/functions_py/shared/tavily_tool.py`

- [ ] **Step 1: Implement `shared/tavily_tool.py`**

File: `functions_py/shared/tavily_tool.py`

```python
"""CrewAI tool wrapping Tavily web search.

Agents that need real-time web context (e.g., the Web Researcher agent)
get this tool in their ``tools=[]`` list. The agent decides when to call
it; we don't pre-fetch.
"""
import os
from typing import List

from crewai.tools import BaseTool
from pydantic import BaseModel, Field
from tavily import TavilyClient


class TavilySearchInput(BaseModel):
    """Input schema for the Tavily search tool."""
    query: str = Field(..., description="Search query, as natural-language text")
    max_results: int = Field(5, description="Maximum results to return (1-10)")


class TavilyWebSearchTool(BaseTool):
    name: str = "web_search"
    description: str = (
        "Search the web for up-to-date information. Useful for finding "
        "current syllabi, past paper patterns, exam conventions, or any "
        "information that might have changed recently. Returns the top "
        "search results with titles, URLs, and content snippets."
    )
    args_schema: type[BaseModel] = TavilySearchInput

    def _run(self, query: str, max_results: int = 5) -> str:
        api_key = os.environ.get("TAVILY_API_KEY")
        if not api_key:
            return "ERROR: web_search unavailable — TAVILY_API_KEY not configured"
        client = TavilyClient(api_key=api_key)
        try:
            response = client.search(
                query=query,
                max_results=max(1, min(max_results, 10)),
                include_answer=False,
                search_depth="basic",
            )
        except Exception as exc:
            return f"ERROR: web_search failed — {exc}"

        results = response.get("results", [])
        if not results:
            return f"No web results for query: {query}"

        lines: List[str] = [f"Search results for: {query}", ""]
        for i, r in enumerate(results, start=1):
            title = r.get("title", "(no title)")
            url = r.get("url", "")
            content = r.get("content", "")[:500]  # truncate long snippets
            lines.append(f"{i}. {title}\n   URL: {url}\n   Snippet: {content}\n")
        return "\n".join(lines)


def get_tavily_tool() -> TavilyWebSearchTool:
    """Factory for the CrewAI-compatible Tavily search tool."""
    return TavilyWebSearchTool()
```

- [ ] **Step 2: Verify import**

```bash
python -c "from functions_py.shared.tavily_tool import get_tavily_tool; t = get_tavily_tool(); print(f'tool: {t.name}')"
```

Expected: `tool: web_search`

- [ ] **Step 3: Commit**

```bash
git add functions_py/shared/tavily_tool.py
git commit -m "feat(functions_py): add Tavily web search as a CrewAI tool

TavilyWebSearchTool extends CrewAI's BaseTool with a clear description
(so the LLM knows when to use it) and a Pydantic input schema
(query + max_results). Reads TAVILY_API_KEY from env at call time,
returning an ERROR line on missing/failing config so the agent can
gracefully proceed without web results if Tavily is down.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: Implement `shared/cache.py`

**Files:**
- Create: `academic_ally/functions_py/shared/cache.py`
- Create: `academic_ally/functions_py/tests/test_cache.py`

- [ ] **Step 1: Write the failing test**

File: `functions_py/tests/test_cache.py`

```python
"""Tests for shared.cache — Firestore cache helpers."""
from datetime import datetime, timedelta, timezone
from unittest.mock import MagicMock, patch

import pytest

from functions_py.shared.cache import read_cache, write_cache, is_fresh


def _mock_firestore():
    """Return (client_mock, doc_ref_mock, doc_snapshot_mock) for chaining."""
    snap = MagicMock()
    doc_ref = MagicMock()
    doc_ref.get.return_value = snap
    client = MagicMock()
    client.document.return_value = doc_ref
    return client, doc_ref, snap


def test_read_cache_returns_data_when_fresh():
    client, doc_ref, snap = _mock_firestore()
    snap.exists = True
    snap.to_dict.return_value = {
        "subject": "DBMS",
        "topicWeights": {"ER Model": 0.3},
        "lastAnalyzed": datetime.now(timezone.utc) - timedelta(hours=1),
    }
    with patch("functions_py.shared.cache.firestore.client", return_value=client):
        result = read_cache("PyqAnalysis/JNTUH/BTECH/CSE/3/DBMS", freshness_hours=24)
    assert result is not None
    assert result["subject"] == "DBMS"


def test_read_cache_returns_none_when_missing():
    client, doc_ref, snap = _mock_firestore()
    snap.exists = False
    with patch("functions_py.shared.cache.firestore.client", return_value=client):
        result = read_cache("PyqAnalysis/missing", freshness_hours=24)
    assert result is None


def test_read_cache_returns_none_when_stale():
    client, doc_ref, snap = _mock_firestore()
    snap.exists = True
    snap.to_dict.return_value = {
        "subject": "DBMS",
        "lastAnalyzed": datetime.now(timezone.utc) - timedelta(hours=48),
    }
    with patch("functions_py.shared.cache.firestore.client", return_value=client):
        result = read_cache("PyqAnalysis/stale", freshness_hours=24)
    assert result is None


def test_write_cache_sets_document():
    client, doc_ref, _ = _mock_firestore()
    data = {"subject": "DBMS", "topicWeights": {"ER": 0.3}}
    with patch("functions_py.shared.cache.firestore.client", return_value=client):
        write_cache("PyqAnalysis/JNTUH/BTECH/CSE/3/DBMS", data)
    client.document.assert_called_once()
    doc_ref.set.assert_called_once()
    written = doc_ref.set.call_args[0][0]
    assert written["subject"] == "DBMS"
    assert "lastAnalyzed" in written


def test_is_fresh_within_window():
    ts = datetime.now(timezone.utc) - timedelta(hours=12)
    assert is_fresh(ts, hours=24) is True


def test_is_fresh_outside_window():
    ts = datetime.now(timezone.utc) - timedelta(hours=48)
    assert is_fresh(ts, hours=24) is False


def test_is_fresh_handles_none():
    assert is_fresh(None, hours=24) is False
```

- [ ] **Step 2: Run test to verify failure**

```bash
pytest functions_py/tests/test_cache.py -v
```

Expected: all 7 tests FAIL (module not found).

- [ ] **Step 3: Implement `shared/cache.py`**

File: `functions_py/shared/cache.py`

```python
"""Firestore cache helpers for AI results.

All AI features write their final output to a canonical Firestore path
(e.g., PyqAnalysis/{uni}/{course}/{branch}/{sem}/{subject}). Subsequent
requests within the freshness window return the cached value without
running the workflow.
"""
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional

from firebase_admin import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP


def is_fresh(ts: Optional[datetime], hours: int) -> bool:
    """Return True if ``ts`` is within the last ``hours`` hours.

    Handles None (treats as stale) and naive datetimes (assumes UTC).
    """
    if ts is None:
        return False
    if ts.tzinfo is None:
        ts = ts.replace(tzinfo=timezone.utc)
    cutoff = datetime.now(timezone.utc) - timedelta(hours=hours)
    return ts >= cutoff


def read_cache(doc_path: str, freshness_hours: int = 24) -> Optional[Dict[str, Any]]:
    """Read a cached AI result if present and fresh.

    Returns the document data as a dict, or None if missing/stale.
    """
    client = firestore.client()
    snap = client.document(doc_path).get()
    if not snap.exists:
        return None
    data = snap.to_dict()
    if not is_fresh(data.get("lastAnalyzed"), freshness_hours):
        return None
    return data


def write_cache(doc_path: str, data: Dict[str, Any]) -> None:
    """Persist an AI result to the cache.

    Adds/overwrites ``lastAnalyzed`` with the server timestamp so
    downstream freshness checks work correctly.
    """
    client = firestore.client()
    payload = {**data, "lastAnalyzed": SERVER_TIMESTAMP}
    client.document(doc_path).set(payload)
```

- [ ] **Step 4: Run test to verify pass**

```bash
pytest functions_py/tests/test_cache.py -v
```

Expected: all 7 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add functions_py/shared/cache.py functions_py/tests/test_cache.py
git commit -m "feat(functions_py): add Firestore cache helpers

read_cache() returns parsed doc if fresh (default 24h), else None.
write_cache() persists result + SERVER_TIMESTAMP lastAnalyzed.
is_fresh() does the date math, UTC-safe, handles None and naive ts.

Covered by 7 unit tests using mocked firestore.client.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: Implement `shared/progress.py`

**Files:**
- Create: `academic_ally/functions_py/shared/progress.py`
- Create: `academic_ally/functions_py/tests/test_progress.py`

- [ ] **Step 1: Write the failing test**

File: `functions_py/tests/test_progress.py`

```python
"""Tests for shared.progress — AnalysisRuns tracker + step callback."""
from unittest.mock import MagicMock, patch

import pytest

from functions_py.shared.progress import (
    init_tracker,
    update_agent_status,
    mark_complete,
    mark_failed,
)


def _mock_firestore():
    doc_ref = MagicMock()
    client = MagicMock()
    client.document.return_value = doc_ref
    return client, doc_ref


def test_init_tracker_writes_initial_doc():
    client, doc_ref = _mock_firestore()
    agents = ["syllabus", "web", "pattern", "predictor", "formatter"]
    with patch("functions_py.shared.progress.firestore.client", return_value=client):
        init_tracker(run_id="abc123", subject="DBMS", agent_names=agents)
    client.document.assert_called_once_with("AnalysisRuns/abc123")
    doc_ref.set.assert_called_once()
    written = doc_ref.set.call_args[0][0]
    assert written["status"] == "running"
    assert written["subject"] == "DBMS"
    assert written["runId"] == "abc123"
    assert written["agents"] == {a: "pending" for a in agents}


def test_update_agent_status_writes_single_field():
    client, doc_ref = _mock_firestore()
    with patch("functions_py.shared.progress.firestore.client", return_value=client):
        update_agent_status("abc123", "syllabus", "done")
    doc_ref.update.assert_called_once()
    updated = doc_ref.update.call_args[0][0]
    assert updated == {"agents.syllabus": "done"}


def test_mark_complete_updates_status():
    client, doc_ref = _mock_firestore()
    with patch("functions_py.shared.progress.firestore.client", return_value=client):
        mark_complete("abc123")
    updated = doc_ref.update.call_args[0][0]
    assert updated["status"] == "complete"


def test_mark_failed_includes_message():
    client, doc_ref = _mock_firestore()
    with patch("functions_py.shared.progress.firestore.client", return_value=client):
        mark_failed("abc123", "syllabus", "rate limit hit")
    updated = doc_ref.update.call_args[0][0]
    assert updated["status"] == "failed"
    assert updated["errorMessage"] == "rate limit hit"
    assert updated["agents.syllabus"] == "failed"
```

- [ ] **Step 2: Run test to verify failure**

```bash
pytest functions_py/tests/test_progress.py -v
```

Expected: all 4 tests FAIL (module not found).

- [ ] **Step 3: Implement `shared/progress.py`**

File: `functions_py/shared/progress.py`

```python
"""Progress tracker for the AnalysisRuns Firestore collection.

Each run gets a doc at ``AnalysisRuns/{runId}`` that tracks per-agent
status. Flutter subscribes to this doc in real time to render the
progressive loading UI.

Trackers are transient — a separate scheduled function (cleanup.py)
deletes docs older than 1 hour.
"""
from typing import List

from firebase_admin import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP


def _tracker_path(run_id: str) -> str:
    return f"AnalysisRuns/{run_id}"


def init_tracker(*, run_id: str, subject: str, agent_names: List[str]) -> None:
    """Create the initial tracker doc with all agents as 'pending'."""
    client = firestore.client()
    agents = {name: "pending" for name in agent_names}
    client.document(_tracker_path(run_id)).set(
        {
            "runId": run_id,
            "subject": subject,
            "status": "running",
            "agents": agents,
            "createdAt": SERVER_TIMESTAMP,
        }
    )


def update_agent_status(run_id: str, agent_name: str, status: str) -> None:
    """Update a single agent's status in the tracker.

    Uses dotted-path update so we only write one field, not the whole map.
    """
    client = firestore.client()
    client.document(_tracker_path(run_id)).update(
        {f"agents.{agent_name}": status}
    )


def mark_complete(run_id: str) -> None:
    """Mark the whole run complete."""
    client = firestore.client()
    client.document(_tracker_path(run_id)).update(
        {"status": "complete", "completedAt": SERVER_TIMESTAMP}
    )


def mark_failed(run_id: str, failing_agent: str, error_message: str) -> None:
    """Mark the run as failed, attributing the failure to an agent."""
    client = firestore.client()
    client.document(_tracker_path(run_id)).update(
        {
            "status": "failed",
            "errorMessage": error_message,
            f"agents.{failing_agent}": "failed",
            "completedAt": SERVER_TIMESTAMP,
        }
    )


def make_crewai_step_callback(run_id: str, agent_name_map: dict):
    """Factory for a CrewAI-compatible ``step_callback``.

    CrewAI fires ``step_callback`` after each agent step. We inspect the
    step's agent role and update the tracker. ``agent_name_map`` maps
    CrewAI role strings (e.g., "Syllabus Researcher") to tracker agent
    names (e.g., "syllabus").
    """
    _seen_done = set()

    def _callback(step_output) -> None:
        role = getattr(step_output, "agent_role", None) or getattr(step_output, "role", None)
        if not role:
            return
        tracker_name = agent_name_map.get(role)
        if not tracker_name or tracker_name in _seen_done:
            return
        update_agent_status(run_id, tracker_name, "done")
        _seen_done.add(tracker_name)

    return _callback
```

- [ ] **Step 4: Run test to verify pass**

```bash
pytest functions_py/tests/test_progress.py -v
```

Expected: all 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add functions_py/shared/progress.py functions_py/tests/test_progress.py
git commit -m "feat(functions_py): add AnalysisRuns progress tracker + step callback

init_tracker, update_agent_status, mark_complete, mark_failed cover
the write side of the AnalysisRuns/{runId} doc that Flutter subscribes
to for progressive loading UI.

make_crewai_step_callback() returns a CrewAI-compatible step_callback
that automatically bumps per-agent status to 'done' based on the
step_output's agent role. agent_name_map maps CrewAI role strings to
tracker-friendly short names.

Covered by 4 unit tests.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 10: Implement `shared/crew_factory.py`

**Files:**
- Create: `academic_ally/functions_py/shared/crew_factory.py`

No unit test — integration-tested end-to-end via PYQ feature.

- [ ] **Step 1: Implement `shared/crew_factory.py`**

File: `functions_py/shared/crew_factory.py`

```python
"""Reusable CrewAI Crew factory.

All 6 AI features construct their crews through this factory so the
hierarchical-process + step-callback + max-iter wiring is consistent
and maintainable.
"""
from typing import List

from crewai import Agent, Crew, Process, Task

from .minimax_llm import get_minimax_llm


def build_hierarchical_crew(
    *,
    agents: List[Agent],
    tasks: List[Task],
    step_callback=None,
    max_iter: int = 8,
    max_rpm: int = 60,
    verbose: bool = True,
) -> Crew:
    """Build a CrewAI Crew with hierarchical process and sensible defaults.

    Args:
        agents: Worker agents (the manager is auto-injected by CrewAI).
        tasks: Ordered task list.
        step_callback: Optional callback fired after each agent step.
        max_iter: Max delegation iterations the manager can perform.
        max_rpm: Max LLM calls per minute across the whole crew.
        verbose: Log agent thinking for debugging.
    """
    manager_llm = get_minimax_llm(temperature=0.1)  # low-temp for routing
    return Crew(
        agents=agents,
        tasks=tasks,
        process=Process.hierarchical,
        manager_llm=manager_llm,
        max_rpm=max_rpm,
        verbose=verbose,
        step_callback=step_callback,
        memory=True,
    )
```

- [ ] **Step 2: Verify import**

```bash
python -c "from functions_py.shared.crew_factory import build_hierarchical_crew; print('ok')"
```

Expected: `ok` (but may warn about MINIMAX_API_KEY — fine; won't be called yet).

- [ ] **Step 3: Commit**

```bash
git add functions_py/shared/crew_factory.py
git commit -m "feat(functions_py): add reusable hierarchical Crew factory

build_hierarchical_crew() centralizes CrewAI Process.hierarchical
setup with manager_llm (low-temp Minimax), step_callback wiring,
max_iter=8, max_rpm=60, and memory=True. All 6 AI features go
through this to stay consistent.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 11: Create pytest `conftest.py`

**Files:**
- Create: `academic_ally/functions_py/tests/conftest.py`

- [ ] **Step 1: Implement `conftest.py`**

File: `functions_py/tests/conftest.py`

```python
"""Shared pytest fixtures for functions_py tests."""
import sys
from pathlib import Path

# Ensure the parent directory (academic_ally/) is on sys.path so
# `from functions_py...` imports work during testing.
_ACADEMIC_ALLY_ROOT = Path(__file__).resolve().parent.parent.parent
if str(_ACADEMIC_ALLY_ROOT) not in sys.path:
    sys.path.insert(0, str(_ACADEMIC_ALLY_ROOT))
```

- [ ] **Step 2: Verify all tests still pass**

```bash
cd "C:/Devspace/flutterprojects/Academic Ally/academic_ally"
.\functions_py\venv\Scripts\Activate.ps1
pytest functions_py/tests/ -v
```

Expected: all 4 test files (errors, auth, cache, progress) pass cleanly (17 tests total).

- [ ] **Step 3: Commit**

```bash
git add functions_py/tests/conftest.py
git commit -m "test(functions_py): add pytest conftest for import path setup

Ensures 'from functions_py.*' imports resolve regardless of where
pytest is invoked. Without this, tests run from the functions_py/
subdir but need the parent on sys.path.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

# Phase 3 — PYQ Analyzer feature

## Task 12: Define Pydantic schemas for PYQ input/output

**Files:**
- Create: `academic_ally/functions_py/features/pyq_analyzer/schema.py`

No unit test — trivial data models; any issues surface during endpoint testing.

- [ ] **Step 1: Implement `schema.py`**

File: `functions_py/features/pyq_analyzer/schema.py`

```python
"""Pydantic schemas for PYQ Analyzer input + output.

Input matches what the Flutter client POSTs. Output matches the
existing ``PyqAnalysis`` Firestore doc shape (lib/models/ai_models.dart)
so Flutter renders it identically to the MockAIService output.
"""
from typing import Dict, List, Optional

from pydantic import BaseModel, Field


class PyqAnalyzeRequest(BaseModel):
    """Input from Flutter."""

    run_id: str = Field(..., description="Client-generated UUID for progress tracking")
    university: str = Field(..., min_length=1)
    course: str = Field(..., min_length=1)
    branch: str = Field(..., min_length=1)
    sem: str = Field(..., min_length=1)
    subject: str = Field(..., min_length=1)
    pyq_resource_ids: List[str] = Field(default_factory=list)
    force_refresh: bool = Field(False, description="Bypass cache if True")


class PredictedQuestion(BaseModel):
    """One predicted exam question."""

    question: str
    topic: str
    expected_marks: int = Field(ge=1, le=20)
    likelihood: float = Field(ge=0.0, le=1.0)
    source_paper_ids: List[str] = Field(default_factory=list)


class PyqAnalysisOutput(BaseModel):
    """Final output returned to Flutter + written to Firestore cache."""

    subject: str
    topic_weights: Dict[str, float]
    predicted_questions: List[PredictedQuestion] = Field(..., min_length=3)
    source_resource_ids: List[str] = Field(default_factory=list)

    def to_firestore_dict(self) -> dict:
        """Render to the snake_case→camelCase shape Flutter expects."""
        return {
            "subject": self.subject,
            "topicWeights": self.topic_weights,
            "predictedQuestions": [
                {
                    "question": q.question,
                    "topic": q.topic,
                    "expectedMarks": q.expected_marks,
                    "likelihood": q.likelihood,
                    "sourcePaperIds": q.source_paper_ids,
                }
                for q in self.predicted_questions
            ],
            "sourceResourceIds": self.source_resource_ids,
        }
```

- [ ] **Step 2: Verify import**

```bash
python -c "from functions_py.features.pyq_analyzer.schema import PyqAnalyzeRequest, PyqAnalysisOutput; print('schemas ok')"
```

Expected: `schemas ok`

- [ ] **Step 3: Commit**

```bash
git add functions_py/features/pyq_analyzer/schema.py
git commit -m "feat(pyq): add Pydantic schemas for PYQ Analyzer

PyqAnalyzeRequest validates incoming payload (run_id, curriculum,
subject, optional pyq_resource_ids, force_refresh). PyqAnalysisOutput
mirrors the existing PyqAnalysis Firestore shape and exposes
to_firestore_dict() for camelCase serialization.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 13: Define the 5 PYQ worker agents

**Files:**
- Create: `academic_ally/functions_py/features/pyq_analyzer/agents.py`

- [ ] **Step 1: Implement `agents.py`**

File: `functions_py/features/pyq_analyzer/agents.py`

```python
"""CrewAI agent definitions for PYQ Analyzer.

Five specialist agents. The manager is auto-provisioned by
Process.hierarchical in the Crew config.
"""
from crewai import Agent

from functions_py.shared.minimax_llm import get_minimax_llm
from functions_py.shared.tavily_tool import get_tavily_tool


# Map CrewAI role strings → tracker agent names (used by step_callback)
AGENT_ROLE_TO_TRACKER = {
    "Syllabus Researcher": "syllabus",
    "Web Researcher": "webResearch",
    "Pattern Analyst": "pattern",
    "Question Predictor": "predictor",
    "Output Formatter": "formatter",
}

TRACKER_AGENT_NAMES = list(AGENT_ROLE_TO_TRACKER.values())


def build_pyq_agents():
    """Return the 5 specialist agents for PYQ Analyzer."""
    llm = get_minimax_llm(temperature=0.3)
    tavily_tool = get_tavily_tool()

    syllabus_researcher = Agent(
        role="Syllabus Researcher",
        goal=(
            "Produce the complete official topic list for the target subject "
            "in the target university and semester. Cite only topics that "
            "appear in the official curriculum."
        ),
        backstory=(
            "You are an expert in Indian engineering curricula with deep "
            "knowledge of Jawaharlal Nehru Technological University Hyderabad "
            "(JNTUH) and Osmania University (OU) syllabi across all B.E/B.Tech "
            "branches. You have spent years reviewing official syllabus documents "
            "and you refuse to invent topics that aren't in the curriculum. "
            "When uncertain, you say so rather than fabricate. You use the "
            "web_search tool when your knowledge is stale or the subject is "
            "obscure."
        ),
        llm=llm,
        tools=[tavily_tool],
        allow_delegation=False,
        verbose=True,
    )

    web_researcher = Agent(
        role="Web Researcher",
        goal=(
            "Find current, real-world information about the subject's past "
            "exam patterns — which topics have repeated, how questions are "
            "typically phrased, and any student-community insights on "
            "important questions."
        ),
        backstory=(
            "You are a research analyst specializing in Indian engineering "
            "education. You know how to query Tavily effectively for exam "
            "content. You always pair search results with the syllabus context "
            "you were given. You extract specific, actionable insights — never "
            "generic platitudes like 'study hard'. If a search returns nothing "
            "useful, you say so honestly."
        ),
        llm=llm,
        tools=[tavily_tool],
        allow_delegation=False,
        verbose=True,
    )

    pattern_analyst = Agent(
        role="Pattern Analyst",
        goal=(
            "Synthesize the syllabus and web research into a clear picture of "
            "exam conventions: how marks are distributed, what types of "
            "questions (2-mark definitions, 5-mark short, 10-mark long, "
            "16-mark essay) map to which topics, and which topics recur."
        ),
        backstory=(
            "You are an exam-pattern analyst with 10 years of experience "
            "decoding Indian engineering university papers. You think "
            "systematically about mark distribution and question taxonomy. "
            "You identify the top 5-6 topics by weight, estimate their "
            "percentage share of the paper, and flag which question-formats "
            "each topic tends to appear in."
        ),
        llm=llm,
        tools=[],
        allow_delegation=False,
        verbose=True,
    )

    question_predictor = Agent(
        role="Question Predictor",
        goal=(
            "Generate 5-8 specific exam questions that are most likely to "
            "appear in the next semester's paper, each with a plausibility "
            "score between 0.3 and 0.95."
        ),
        backstory=(
            "You are a seasoned coaching-center instructor who has correctly "
            "predicted exam questions for years based on syllabus + past "
            "pattern analysis. You write questions in the exact style "
            "JNTUH/OU papers use — clear, often phrased as 'Explain...' or "
            "'Define...' or 'Derive...'. You assign realistic likelihoods — "
            "never all 0.95 (unrealistic) and never all 0.40 (unhelpful). "
            "Top topics get 0.75-0.90, mid-tier 0.50-0.70, long-shot 0.30-0.45. "
            "You never produce fewer than 5 questions."
        ),
        llm=llm,
        tools=[],
        allow_delegation=False,
        verbose=True,
    )

    output_formatter = Agent(
        role="Output Formatter",
        goal=(
            "Assemble all prior agent outputs into the exact JSON structure "
            "the Flutter client expects, matching the PyqAnalysisOutput "
            "Pydantic schema."
        ),
        backstory=(
            "You are a precise data-formatter. You take the messy natural "
            "language outputs from earlier agents and produce clean, "
            "schema-conformant JSON. You never paraphrase or editorialize. "
            "topic_weights values sum to ~1.0 (tolerance 0.05). "
            "predicted_questions has at least 3 entries. Every field is "
            "populated; no nulls for required fields."
        ),
        llm=llm,
        tools=[],
        allow_delegation=False,
        verbose=True,
    )

    return {
        "syllabus_researcher": syllabus_researcher,
        "web_researcher": web_researcher,
        "pattern_analyst": pattern_analyst,
        "question_predictor": question_predictor,
        "output_formatter": output_formatter,
    }
```

- [ ] **Step 2: Verify import**

```bash
# From project root with venv active
python -c "from functions_py.features.pyq_analyzer.agents import build_pyq_agents; print('agents ok')"
```

Expected: `agents ok` (MINIMAX_API_KEY warning is fine; we only built the function, didn't call it).

- [ ] **Step 3: Commit**

```bash
git add functions_py/features/pyq_analyzer/agents.py
git commit -m "feat(pyq): define 5 specialist agents for PYQ Analyzer

Each agent has a crisp role + strict goal + backstory grounding them
in Indian engineering exam culture. Syllabus Researcher and Web
Researcher get the Tavily tool; the other three are pure-reasoning.
AGENT_ROLE_TO_TRACKER maps CrewAI role strings to tracker short names
for the step_callback.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 14: Define the 5 PYQ tasks

**Files:**
- Create: `academic_ally/functions_py/features/pyq_analyzer/tasks.py`

- [ ] **Step 1: Implement `tasks.py`**

File: `functions_py/features/pyq_analyzer/tasks.py`

```python
"""CrewAI task definitions for PYQ Analyzer.

Tasks are chained — each one's ``context`` includes prior tasks so the
agent sees accumulated findings. The Output Formatter task produces the
final structured JSON.
"""
from crewai import Task

from .schema import PyqAnalysisOutput


def build_pyq_tasks(agents: dict):
    """Build the 5 ordered tasks for PYQ Analyzer.

    Args:
        agents: Output of build_pyq_agents() — dict of role name → Agent.

    Returns:
        List of 5 Task objects in execution order.
    """
    research_syllabus = Task(
        description=(
            "Research and produce the official topic list for "
            "{subject} taught in {university} {course} {branch} Semester {sem}.\n\n"
            "Requirements:\n"
            "1. List 5-8 major topics (units or chapters) that are in the "
            "   official curriculum.\n"
            "2. For each topic, include 2-3 sub-topics.\n"
            "3. Use web_search if you're unsure about the current JNTUH/OU "
            "   syllabus for this subject.\n"
            "4. Do NOT invent topics. If information is genuinely unavailable, "
            "   say so.\n\n"
            "Format as Markdown with topic headings and bullet sub-topics."
        ),
        expected_output=(
            "A Markdown document with 5-8 H2 topic headings and 2-3 bullet "
            "sub-topics per heading."
        ),
        agent=agents["syllabus_researcher"],
    )

    research_web = Task(
        description=(
            "Given the syllabus produced by the Syllabus Researcher, use "
            "web_search to find current information about exam patterns for "
            "{subject} in {university} {branch} Semester {sem}.\n\n"
            "Search for things like:\n"
            "- '{subject} important questions {university}'\n"
            "- '{subject} past papers {branch} sem {sem}'\n"
            "- '{subject} repeated questions JNTUH OU'\n\n"
            "Return a summary of 5-7 actionable insights from the web results — "
            "which topics repeat, what kinds of questions are typical, any "
            "student-community hints about 'must-study' topics.\n\n"
            "If web_search returns nothing useful, say so honestly — don't "
            "invent data."
        ),
        expected_output=(
            "A bulleted summary of 5-7 specific insights about {subject} exam "
            "patterns, each with a one-line justification."
        ),
        agent=agents["web_researcher"],
        context=[research_syllabus],
    )

    analyze_patterns = Task(
        description=(
            "Synthesize the syllabus and web research into exam-pattern "
            "analysis for {subject}.\n\n"
            "Produce:\n"
            "1. A ranked list of the top 5-6 topics by expected weight "
            "   (each with a percentage 0-100% of the paper).\n"
            "2. For each topic, the question formats it tends to appear in "
            "   (2-mark, 5-mark, 10-mark, 16-mark).\n"
            "3. An overall note on mark distribution (e.g., 'papers are "
            "   typically 30% short-answer, 70% long-answer')."
        ),
        expected_output=(
            "Markdown with a ranked topic list (topic name, % weight, typical "
            "question formats), plus a mark-distribution note."
        ),
        agent=agents["pattern_analyst"],
        context=[research_syllabus, research_web],
    )

    predict_questions = Task(
        description=(
            "Generate 5-8 specific exam questions for {subject} in {university} "
            "{branch} Semester {sem} that are most likely to appear.\n\n"
            "For EACH question:\n"
            "- Write the question in the exact style used in JNTUH/OU papers.\n"
            "- Assign an expected_marks value (2, 5, 10, or 16).\n"
            "- Assign a likelihood between 0.30 and 0.95 (NEVER 1.0, NEVER 0.0).\n"
            "  Top 2-3 questions: 0.75-0.90. Middle tier: 0.50-0.70. "
            "  Long-shot: 0.30-0.45.\n"
            "- Tag which topic the question belongs to (from the pattern analysis).\n\n"
            "Output as Markdown — one question per section."
        ),
        expected_output=(
            "5-8 Markdown sections, each with: Question text, Topic, "
            "Expected Marks, Likelihood."
        ),
        agent=agents["question_predictor"],
        context=[research_syllabus, research_web, analyze_patterns],
    )

    format_output = Task(
        description=(
            "Assemble all prior agent outputs into the final JSON structure. "
            "Do NOT paraphrase; only restructure.\n\n"
            "The output JSON must match this Pydantic schema exactly:\n"
            "```\n"
            "{\n"
            "  \"subject\": str,\n"
            "  \"topic_weights\": {{topic_name: float_between_0_and_1}},  // values sum to ~1.0\n"
            "  \"predicted_questions\": [\n"
            "    {{\n"
            "      \"question\": str,\n"
            "      \"topic\": str,\n"
            "      \"expected_marks\": int (1-20),\n"
            "      \"likelihood\": float (0.0-1.0),\n"
            "      \"source_paper_ids\": []\n"
            "    }}, ... (at least 3 entries)\n"
            "  ],\n"
            "  \"source_resource_ids\": []\n"
            "}\n"
            "```\n\n"
            "The `subject` field must be exactly '{subject}'. topic_weights "
            "come from the Pattern Analyst output (convert percentages to "
            "decimals). predicted_questions come from the Question Predictor. "
            "Return ONLY the JSON — no surrounding Markdown, no commentary."
        ),
        expected_output=(
            "A single JSON object matching PyqAnalysisOutput schema. No "
            "code fences, no explanation."
        ),
        agent=agents["output_formatter"],
        context=[analyze_patterns, predict_questions],
        output_pydantic=PyqAnalysisOutput,
    )

    return [research_syllabus, research_web, analyze_patterns, predict_questions, format_output]
```

- [ ] **Step 2: Verify import**

```bash
python -c "from functions_py.features.pyq_analyzer.tasks import build_pyq_tasks; print('tasks ok')"
```

Expected: `tasks ok`

- [ ] **Step 3: Commit**

```bash
git add functions_py/features/pyq_analyzer/tasks.py
git commit -m "feat(pyq): define 5 PYQ tasks chained via context

Each task has a strict description, clear expected_output, and an
explicit agent assignment. Later tasks list earlier ones in 'context'
so downstream agents see accumulated findings. The final formatter
task uses output_pydantic=PyqAnalysisOutput so CrewAI validates the
JSON structure automatically.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 15: Wire the PYQ Crew runner

**Files:**
- Create: `academic_ally/functions_py/features/pyq_analyzer/crew.py`

- [ ] **Step 1: Implement `crew.py`**

File: `functions_py/features/pyq_analyzer/crew.py`

```python
"""PYQ Analyzer crew assembly and invocation.

``run_pyq_analysis`` is the single entry point — it builds the crew,
kicks off the workflow, and returns a validated PyqAnalysisOutput.
Exceptions bubble up to the HTTP handler for user-facing translation.
"""
import logging
from typing import Any

from functions_py.shared.crew_factory import build_hierarchical_crew
from functions_py.shared.errors import AgentFailureError
from functions_py.shared.progress import make_crewai_step_callback

from .agents import AGENT_ROLE_TO_TRACKER, TRACKER_AGENT_NAMES, build_pyq_agents
from .schema import PyqAnalysisOutput, PyqAnalyzeRequest
from .tasks import build_pyq_tasks


logger = logging.getLogger(__name__)


def run_pyq_analysis(req: PyqAnalyzeRequest) -> PyqAnalysisOutput:
    """Run the PYQ Analyzer workflow.

    Assumes progress tracker already exists at AnalysisRuns/{req.run_id}.
    Updates the tracker as agents complete. Raises AgentFailureError on
    any unrecoverable crew failure.
    """
    agents_dict = build_pyq_agents()
    tasks = build_pyq_tasks(agents_dict)

    step_callback = make_crewai_step_callback(
        run_id=req.run_id,
        agent_name_map=AGENT_ROLE_TO_TRACKER,
    )

    crew = build_hierarchical_crew(
        agents=list(agents_dict.values()),
        tasks=tasks,
        step_callback=step_callback,
    )

    inputs: dict[str, Any] = {
        "subject": req.subject,
        "university": req.university,
        "course": req.course,
        "branch": req.branch,
        "sem": req.sem,
    }

    try:
        result = crew.kickoff(inputs=inputs)
    except Exception as exc:
        logger.exception("PYQ crew failed")
        raise AgentFailureError(f"crew.kickoff failed: {exc}") from exc

    # CrewAI returns a TaskOutput; the final task's pydantic output is in
    # result.pydantic when output_pydantic was set.
    pydantic_output = getattr(result, "pydantic", None)
    if pydantic_output is None or not isinstance(pydantic_output, PyqAnalysisOutput):
        # Fallback: parse raw string if pydantic didn't capture it
        try:
            import json

            raw = getattr(result, "raw", str(result))
            pydantic_output = PyqAnalysisOutput.model_validate_json(raw)
        except Exception as exc:
            raise AgentFailureError(
                f"output formatter did not produce valid JSON: {exc}"
            ) from exc
    return pydantic_output
```

- [ ] **Step 2: Verify import**

```bash
python -c "from functions_py.features.pyq_analyzer.crew import run_pyq_analysis; print('crew ok')"
```

Expected: `crew ok`

- [ ] **Step 3: Commit**

```bash
git add functions_py/features/pyq_analyzer/crew.py
git commit -m "feat(pyq): add run_pyq_analysis entry point

Builds agents + tasks + step_callback + hierarchical crew, kicks off
with curriculum inputs, extracts validated PyqAnalysisOutput from the
final task's pydantic output. Falls back to JSON parsing if
output_pydantic didn't capture. Any failure raises AgentFailureError
so the HTTP handler can map to a user-facing error.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 16: Implement the PYQ HTTP handler

**Files:**
- Create: `academic_ally/functions_py/features/pyq_analyzer/handler.py`

- [ ] **Step 1: Implement `handler.py`**

File: `functions_py/features/pyq_analyzer/handler.py`

```python
"""HTTP handler for POST /ai/pyq-analyze.

Wired up by main.py via firebase_functions.https_fn.on_request.
"""
import json
import logging

from firebase_functions import https_fn
from pydantic import ValidationError as PydanticValidationError

from functions_py.shared.auth import extract_uid
from functions_py.shared.cache import read_cache, write_cache
from functions_py.shared.errors import (
    AgentFailureError,
    AuthError,
    ValidationError,
    user_facing_message,
)
from functions_py.shared.progress import (
    init_tracker,
    mark_complete,
    mark_failed,
)

from .agents import TRACKER_AGENT_NAMES
from .crew import run_pyq_analysis
from .schema import PyqAnalyzeRequest


logger = logging.getLogger(__name__)


def _cache_path(req: PyqAnalyzeRequest) -> str:
    return f"PyqAnalysis/{req.university}/{req.course}/{req.branch}/{req.sem}/{req.subject}"


def pyq_analyze_handler(request: https_fn.Request) -> https_fn.Response:
    """Handle POST /ai/pyq-analyze."""
    if request.method != "POST":
        return https_fn.Response(
            json.dumps({"error": "method not allowed"}),
            status=405,
            content_type="application/json",
        )

    # Auth
    try:
        uid = extract_uid(request.headers)
    except AuthError as exc:
        logger.warning("auth rejected: %s", exc)
        return https_fn.Response(
            json.dumps({"error": user_facing_message(exc)}),
            status=401,
            content_type="application/json",
        )

    # Parse + validate input
    try:
        body = request.get_json(silent=True) or {}
        req = PyqAnalyzeRequest(**body)
    except PydanticValidationError as exc:
        return https_fn.Response(
            json.dumps(
                {
                    "error": user_facing_message(ValidationError(str(exc))),
                    "details": exc.errors(),
                }
            ),
            status=400,
            content_type="application/json",
        )

    cache_key = _cache_path(req)

    # Cache hit → return immediately
    if not req.force_refresh:
        cached = read_cache(cache_key, freshness_hours=24)
        if cached:
            logger.info("cache hit for %s", cache_key)
            return https_fn.Response(
                json.dumps(cached, default=str),
                status=200,
                content_type="application/json",
            )

    # Initialize progress tracker so Flutter can subscribe
    init_tracker(
        run_id=req.run_id,
        subject=req.subject,
        agent_names=TRACKER_AGENT_NAMES,
    )

    # Run the crew
    try:
        output = run_pyq_analysis(req)
    except Exception as exc:
        logger.exception("pyq analysis failed")
        mark_failed(req.run_id, failing_agent="crew", error_message=str(exc))
        status = 503 if isinstance(exc, AgentFailureError) else 500
        return https_fn.Response(
            json.dumps({"error": user_facing_message(exc)}),
            status=status,
            content_type="application/json",
        )

    # Persist to cache
    firestore_doc = output.to_firestore_dict()
    firestore_doc["sourceResourceIds"] = req.pyq_resource_ids
    write_cache(cache_key, firestore_doc)
    mark_complete(req.run_id)

    return https_fn.Response(
        json.dumps(firestore_doc, default=str),
        status=200,
        content_type="application/json",
    )
```

- [ ] **Step 2: Verify import**

```bash
python -c "from functions_py.features.pyq_analyzer.handler import pyq_analyze_handler; print('handler ok')"
```

Expected: `handler ok`

- [ ] **Step 3: Commit**

```bash
git add functions_py/features/pyq_analyzer/handler.py
git commit -m "feat(pyq): add HTTP handler for POST /ai/pyq-analyze

Full request lifecycle:
1. Method check (405 on non-POST)
2. Firebase ID token verify (401 on invalid)
3. Pydantic request validation (400 on bad payload)
4. Cache check (24h freshness, short-circuit on hit)
5. Init progress tracker
6. Run CrewAI workflow
7. Write cache + mark tracker complete
8. Return firestore-shaped JSON

Errors at every stage are mapped to user-facing messages via
user_facing_message() with appropriate HTTP status codes.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 17: Create the cleanup scheduled function

**Files:**
- Create: `academic_ally/functions_py/features/maintenance/cleanup.py`

- [ ] **Step 1: Implement `cleanup.py`**

File: `functions_py/features/maintenance/cleanup.py`

```python
"""Scheduled function that deletes stale AnalysisRuns tracker docs.

Trackers are transient — they only exist during a workflow run to
drive the progress UI. After the run completes, they're not needed.
We delete docs older than 1 hour to keep the collection small.
"""
import logging
from datetime import datetime, timedelta, timezone

from firebase_admin import firestore
from firebase_functions import scheduler_fn


logger = logging.getLogger(__name__)


@scheduler_fn.on_schedule(schedule="every 1 hours", region="us-central1")
def cleanup_old_trackers(event: scheduler_fn.ScheduledEvent) -> None:
    """Delete AnalysisRuns docs older than 1 hour."""
    client = firestore.client()
    cutoff = datetime.now(timezone.utc) - timedelta(hours=1)
    stale = (
        client.collection("AnalysisRuns")
        .where("createdAt", "<", cutoff)
        .limit(500)
        .stream()
    )
    deleted = 0
    for snap in stale:
        snap.reference.delete()
        deleted += 1
    logger.info("cleanup_old_trackers deleted %d stale tracker docs", deleted)
```

- [ ] **Step 2: Verify import**

```bash
python -c "from functions_py.features.maintenance.cleanup import cleanup_old_trackers; print('cleanup ok')"
```

Expected: `cleanup ok`

- [ ] **Step 3: Commit**

```bash
git add functions_py/features/maintenance/cleanup.py
git commit -m "feat(functions_py): add hourly cleanup for AnalysisRuns trackers

cleanup_old_trackers runs every hour and deletes AnalysisRuns docs
with createdAt older than 1h. Caps at 500 deletes per run to avoid
transaction limits. Deployed via Cloud Scheduler automatically.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 18: Wire up `main.py` entry point

**Files:**
- Create: `academic_ally/functions_py/main.py`

- [ ] **Step 1: Implement `main.py`**

File: `functions_py/main.py`

```python
"""Firebase Functions Gen 2 entry point for the Python AI backend.

Exports every HTTPS + scheduled function Firebase deploys to this
codebase. Each feature lives in its own module; main.py just re-exports
the right symbols.
"""
import firebase_admin
from firebase_functions import https_fn, options

# Initialize firebase_admin once at module load.
# Cloud Functions Gen 2 reuses the Python process across requests, so
# this runs once per cold start, not per request.
if not firebase_admin._apps:
    firebase_admin.initialize_app()


# Global options: all HTTPS functions get CORS + timeout + region.
options.set_global_options(
    region="us-central1",
    timeout_sec=540,  # Gen 2 max; our workflow budget is 180s, this is headroom
    memory=options.MemoryOption.MB_512,
    cors=options.CorsOptions(
        cors_origins=["*"],
        cors_methods=["POST", "OPTIONS"],
    ),
)


# Import feature handlers AFTER firebase_admin is initialized so modules
# that use firestore.client() inside imports don't fail.
from functions_py.features.pyq_analyzer.handler import pyq_analyze_handler  # noqa: E402
from functions_py.features.maintenance.cleanup import cleanup_old_trackers  # noqa: E402,F401


@https_fn.on_request(
    secrets=["MINIMAX_API_KEY", "TAVILY_API_KEY"],
    timeout_sec=540,
)
def pyq_analyze(request: https_fn.Request) -> https_fn.Response:
    """POST /pyq_analyze — PYQ Analyzer endpoint."""
    return pyq_analyze_handler(request)
```

- [ ] **Step 2: Verify import**

```bash
python -c "import functions_py.main; print('main ok')"
```

Expected: `main ok`

- [ ] **Step 3: Commit**

```bash
git add functions_py/main.py
git commit -m "feat(functions_py): wire main.py entry point

Initializes firebase_admin once, sets global function options
(us-central1, 540s timeout, 512MB memory, permissive CORS for now).

Exports:
- pyq_analyze (HTTPS, consumes MINIMAX_API_KEY + TAVILY_API_KEY secrets)
- cleanup_old_trackers (hourly scheduled, imported from maintenance/)

Additional AI endpoints land here as features ship in later plans.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

# Phase 4 — Firebase Secrets

## Task 19: Set Firebase Secrets for Minimax + Tavily

**Files:** none (runtime config only)

- [ ] **Step 1: Get the Tavily API key**

User action:
1. Go to https://tavily.com
2. Sign up (free tier: 1000 searches/month)
3. Dashboard → API Keys → copy the key
4. Paste it in a scratch pad, not in git

Prompt the user for their Tavily key before proceeding.

- [ ] **Step 2: Set MINIMAX_API_KEY secret**

```bash
cd "C:/Devspace/flutterprojects/Academic Ally/academic_ally"
firebase functions:secrets:set MINIMAX_API_KEY --project academic-ally-app
```

Firebase CLI prompts: `Enter a value for MINIMAX_API_KEY:`
User pastes the Minimax API key.
Confirm creation.

- [ ] **Step 3: Set TAVILY_API_KEY secret**

```bash
firebase functions:secrets:set TAVILY_API_KEY --project academic-ally-app
```

Firebase CLI prompts: `Enter a value for TAVILY_API_KEY:`
User pastes the Tavily API key.
Confirm creation.

- [ ] **Step 4: Optionally set MINIMAX_MODEL**

If the default `MiniMax-M2` model name in `shared/minimax_llm.py` doesn't match what your Minimax account supports, set:

```bash
firebase functions:secrets:set MINIMAX_MODEL --project academic-ally-app
```

(Skip if the default is fine; we can always set it later when we find out the exact model string from your account.)

- [ ] **Step 5: Verify secrets are set**

```bash
firebase functions:secrets:access MINIMAX_API_KEY --project academic-ally-app 2>&1 | head -1
firebase functions:secrets:access TAVILY_API_KEY --project academic-ally-app 2>&1 | head -1
```

Expected: both return the key values (printed once to your terminal — you just created them so this is expected and safe).

- [ ] **Step 6: No commit needed**

Secrets live in Firebase, not in the repo.

---

# Phase 5 — Flutter client integration

## Task 20: Add `aiBackendBaseUrl` constant

**Files:**
- Modify: `academic_ally/lib/core/constants/app_constants.dart`

- [ ] **Step 1: Read current `app_constants.dart`**

```bash
cd "C:/Devspace/flutterprojects/Academic Ally/academic_ally"
cat lib/core/constants/app_constants.dart
```

(Verify the current content matches what the CLAUDE.md describes. The file defines an `AppConstants` class.)

- [ ] **Step 2: Add the new constant**

Inside the `AppConstants` class (after `cloudFunctionsBaseUrl`), add:

```dart
  // Python AI backend base URL (Firebase Functions Gen 2 / us-central1)
  // Each AI endpoint is a top-level function under this origin, e.g.
  //   POST {aiBackendBaseUrl}/pyq_analyze
  static const String aiBackendBaseUrl =
      'https://us-central1-academic-ally-app.cloudfunctions.net';
```

- [ ] **Step 3: Run analyzer**

```bash
flutter analyze lib/core/constants/app_constants.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/core/constants/app_constants.dart
git commit -m "feat(app): add aiBackendBaseUrl constant

Points to the Cloud Functions origin where Python AI endpoints
deploy. AgentAIService prepends this to endpoint paths like
'/pyq_analyze'.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 21: Implement `AgentAIService`

**Files:**
- Create: `academic_ally/lib/core/services/ai/agent_ai_service.dart`

This is a long file because it has to implement all 8 methods on AIService. For Phase 4b, only `analyzePyq` is fully wired; the other 7 throw "not yet implemented in Phase 4b" errors that map cleanly to feature-specific UI fallbacks.

- [ ] **Step 1: Implement `agent_ai_service.dart`**

File: `lib/core/services/ai/agent_ai_service.dart`

```dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/ai_models.dart';
import 'ai_service.dart';

/// AIService backed by the Python Firebase Cloud Functions multi-agent
/// backend. Phase 4b only implements [analyzePyq] end-to-end; the other
/// methods throw [UnimplementedError] until their crews are ported in
/// subsequent plans.
class AgentAIService implements AIService {
  AgentAIService({http.Client? httpClient, Uuid? uuid})
      : _http = httpClient ?? http.Client(),
        _uuid = uuid ?? const Uuid();

  final http.Client _http;
  final Uuid _uuid;

  // ---------------------------------------------------------------------------
  // PYQ Analyzer (Phase 4b — fully wired)
  // ---------------------------------------------------------------------------

  @override
  Future<PyqAnalysis> analyzePyq({
    required String university,
    required String course,
    required String branch,
    required String sem,
    required String subject,
    required List<String> pyqResourceIds,
  }) async {
    final runId = _uuid.v4();
    final idToken = await _freshIdToken();

    final uri = Uri.parse('${AppConstants.aiBackendBaseUrl}/pyq_analyze');
    final response = await _http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'run_id': runId,
            'university': university,
            'course': course,
            'branch': branch,
            'sem': sem,
            'subject': subject,
            'pyq_resource_ids': pyqResourceIds,
            'force_refresh': false,
          }),
        )
        .timeout(const Duration(seconds: 200));

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(response);
      throw AgentBackendException(
        statusCode: response.statusCode,
        message: msg,
        runId: runId,
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return _parsePyqAnalysisResponse(body);
  }

  /// Expose the runId that the current analyzePyq call is using, so the UI
  /// can subscribe to `AnalysisRuns/{runId}` before/during the HTTP call.
  ///
  /// This is a convenience — the UI can also generate its own UUID and
  /// pass it to [analyzePyqWithRunId] if it wants to subscribe strictly
  /// before the HTTP call starts.
  Future<PyqAnalysisWithRunId> analyzePyqWithRunId({
    required String runId,
    required String university,
    required String course,
    required String branch,
    required String sem,
    required String subject,
    required List<String> pyqResourceIds,
  }) async {
    final idToken = await _freshIdToken();
    final uri = Uri.parse('${AppConstants.aiBackendBaseUrl}/pyq_analyze');
    final response = await _http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'run_id': runId,
            'university': university,
            'course': course,
            'branch': branch,
            'sem': sem,
            'subject': subject,
            'pyq_resource_ids': pyqResourceIds,
            'force_refresh': false,
          }),
        )
        .timeout(const Duration(seconds: 200));
    if (response.statusCode != 200) {
      throw AgentBackendException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response),
        runId: runId,
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final analysis = _parsePyqAnalysisResponse(body);
    return PyqAnalysisWithRunId(analysis: analysis, runId: runId);
  }

  PyqAnalysis _parsePyqAnalysisResponse(Map<String, dynamic> body) {
    final predicted = (body['predictedQuestions'] as List<dynamic>)
        .map(
          (e) => PredictedQuestion.fromMap(e as Map<String, dynamic>),
        )
        .toList();
    final weights = (body['topicWeights'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    return PyqAnalysis(
      subject: body['subject'] as String,
      topicWeights: weights,
      predictedQuestions: predicted,
      sourceResourceIds: List<String>.from(
        body['sourceResourceIds'] ?? const [],
      ),
      lastAnalyzed: DateTime.now(),
    );
  }

  Future<String> _freshIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Must be signed in to call the AI backend.');
    }
    final token = await user.getIdToken(false);
    if (token == null) {
      throw StateError('Could not obtain ID token.');
    }
    return token;
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['error'] as String?) ?? 'Unknown error';
    } catch (_) {
      return 'Server error (${response.statusCode})';
    }
  }

  // ---------------------------------------------------------------------------
  // Remaining 7 AIService methods — not yet implemented in Phase 4b
  // ---------------------------------------------------------------------------

  @override
  Future<List<Misconception>> tagMisconceptions({
    required String subject,
    required String topic,
    required String questionText,
    required String userAnswer,
    required String correctAnswer,
  }) =>
      throw UnimplementedError(
        'tagMisconceptions: AgentAIService Phase 4b only wires PYQ Analyzer. '
        'This method ports in the next plan.',
      );

  @override
  Future<MasteryScore> updateMastery({
    required String uid,
    required String nodeId,
    required bool wasCorrect,
  }) =>
      throw UnimplementedError(
        'updateMastery: Phase 4b PYQ-only; port next.',
      );

  @override
  Future<StudyPlan> generateStudyPlan({
    required String uid,
    required DateTime examDate,
    required List<String> subjects,
    required String branch,
    required String sem,
    List<String> weakTopics = const [],
    int dailyStudyMinutes = 120,
  }) =>
      throw UnimplementedError('generateStudyPlan: Phase 4b PYQ-only.');

  @override
  Future<DoubtSolution> solveDoubtFromImage({
    required String uid,
    required String imageUrl,
    String? subjectHint,
  }) =>
      throw UnimplementedError('solveDoubtFromImage: Phase 4b PYQ-only.');

  @override
  Future<ProjectGuidance> getProjectGuidance({
    required String uid,
    required String projectId,
    required ProjectPhase phase,
    required Map<String, dynamic> projectContext,
    String? userQuery,
  }) =>
      throw UnimplementedError('getProjectGuidance: Phase 4b PYQ-only.');

  @override
  Future<Map<String, dynamic>> generateUIResponse({
    required String prompt,
    required Map<String, dynamic> context,
  }) =>
      throw UnimplementedError('generateUIResponse: Phase 4b PYQ-only.');

  @override
  Future<String> chatAboutPdf({
    required String uid,
    required String pdfUrl,
    required String question,
    List<Map<String, String>> priorTurns = const [],
  }) =>
      throw UnimplementedError('chatAboutPdf: Phase 4b PYQ-only.');
}

class PyqAnalysisWithRunId {
  final PyqAnalysis analysis;
  final String runId;
  const PyqAnalysisWithRunId({required this.analysis, required this.runId});
}

class AgentBackendException implements Exception {
  final int statusCode;
  final String message;
  final String runId;
  const AgentBackendException({
    required this.statusCode,
    required this.message,
    required this.runId,
  });
  @override
  String toString() => 'AgentBackendException($statusCode): $message';
}
```

- [ ] **Step 2: Run analyzer**

```bash
flutter analyze lib/core/services/ai/agent_ai_service.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/core/services/ai/agent_ai_service.dart
git commit -m "feat(flutter): add AgentAIService implementing AIService

Phase 4b swaps MockAIService for this when the Python backend is
live. Only analyzePyq is fully wired in this plan; the other 7 methods
throw UnimplementedError with clear Phase-4b-only messages.

analyzePyq generates a UUID runId client-side, POSTs to
{aiBackendBaseUrl}/pyq_analyze with Firebase ID token + curriculum
data, and parses the camelCase JSON back into a PyqAnalysis model.

analyzePyqWithRunId is a convenience for the UI layer so it can
subscribe to AnalysisRuns/{runId} BEFORE triggering the HTTP call
(avoids a race where agents complete before the subscription lands).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 22: Swap `aiServiceProvider` to `AgentAIService`

**Files:**
- Modify: `academic_ally/lib/core/providers/ai_provider.dart`

- [ ] **Step 1: Read current `ai_provider.dart`**

```bash
cat lib/core/providers/ai_provider.dart
```

Should currently return `MockAIService()`.

- [ ] **Step 2: Replace the content**

File: `lib/core/providers/ai_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai/agent_ai_service.dart';
import '../services/ai/ai_service.dart';

/// Single provider every AI-powered feature reads through.
///
/// Phase 4b: returns [AgentAIService] which calls the Python Firebase
/// Function backend. Only [AIService.analyzePyq] is fully wired; other
/// methods throw UnimplementedError until their crews ship in later
/// plans.
///
/// To fall back to the mock during local dev (e.g., when the backend
/// is unreachable), swap `AgentAIService()` for `MockAIService()`
/// temporarily.
final aiServiceProvider = Provider<AIService>((ref) {
  return AgentAIService();
});
```

- [ ] **Step 3: Run analyzer on the whole lib**

```bash
flutter analyze lib/
```

Expected: `No issues found!` (but may show info about unused MockAIService import in other files — that's fine).

- [ ] **Step 4: Commit**

```bash
git add lib/core/providers/ai_provider.dart
git commit -m "feat(flutter): swap aiServiceProvider from MockAIService to AgentAIService

Phase 4b — real AI backend now powers PYQ Analyzer. Other 5 AI
features (Knowledge Map, Study Planner, Gen UI, Snap-a-Doubt,
Project Copilot) will throw UnimplementedError if invoked until
their crews are ported in subsequent plans.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 23: Create the AnalysisRun progress stream provider

**Files:**
- Create: `academic_ally/lib/features/pyq_analyzer/providers/analysis_run_provider.dart`

- [ ] **Step 1: Implement the provider**

File: `lib/features/pyq_analyzer/providers/analysis_run_provider.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live snapshot of an AnalysisRuns/{runId} document. Drives the
/// progressive loading UI (agent checkmarks).
class AnalysisRun {
  final String runId;
  final String status; // 'running' | 'complete' | 'failed' | 'timeout'
  final String subject;
  final Map<String, String> agents;
  final String? errorMessage;

  const AnalysisRun({
    required this.runId,
    required this.status,
    required this.subject,
    required this.agents,
    this.errorMessage,
  });

  factory AnalysisRun.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    final rawAgents = (data['agents'] as Map<String, dynamic>?) ?? const {};
    return AnalysisRun(
      runId: doc.id,
      status: data['status'] as String? ?? 'running',
      subject: data['subject'] as String? ?? '',
      agents: rawAgents.map((k, v) => MapEntry(k, v as String)),
      errorMessage: data['errorMessage'] as String?,
    );
  }

  bool get isRunning => status == 'running';
  bool get isComplete => status == 'complete';
  bool get isFailed => status == 'failed' || status == 'timeout';

  /// Returns true if the named agent has been marked 'done'.
  bool isDone(String agentName) => agents[agentName] == 'done';

  /// Returns true if the named agent has been marked 'failed'.
  bool isFailedAgent(String agentName) => agents[agentName] == 'failed';
}

/// Streams an AnalysisRuns/{runId} doc in real time. The param is the
/// runId string. Returns null while the doc doesn't exist yet.
final analysisRunProvider =
    StreamProvider.family<AnalysisRun?, String>((ref, runId) {
  return FirebaseFirestore.instance
      .doc('AnalysisRuns/$runId')
      .snapshots()
      .map((doc) => doc.exists ? AnalysisRun.fromFirestore(doc) : null);
});
```

- [ ] **Step 2: Run analyzer**

```bash
flutter analyze lib/features/pyq_analyzer/providers/analysis_run_provider.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/pyq_analyzer/providers/analysis_run_provider.dart
git commit -m "feat(pyq): add AnalysisRun stream provider

Streams AnalysisRuns/{runId} docs in real time from Firestore. Drives
the progressive loading UI — as the backend updates agent statuses,
the AnalysisRun object re-emits and the UI re-renders checkmarks.

AnalysisRun.isDone(name) and .isFailedAgent(name) are convenience
getters for per-agent render logic.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 24: Update `pyq_analyzer_provider.dart` to use runId

**Files:**
- Modify: `academic_ally/lib/features/pyq_analyzer/providers/pyq_analyzer_provider.dart`

- [ ] **Step 1: Read the existing provider**

```bash
cat lib/features/pyq_analyzer/providers/pyq_analyzer_provider.dart
```

You'll see `PyqAnalyzerNotifier.runAnalysis` currently calls `AIService.analyzePyq(...)` with a signature that doesn't expose the runId. We need a parallel path that does.

- [ ] **Step 2: Modify the notifier to expose runId during a run**

Add state to track current runId. Replace the class with:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/providers/ai_provider.dart';
import '../../../core/services/ai/agent_ai_service.dart';
import '../../../models/ai_models.dart';
import '../../auth/providers/auth_provider.dart';

/// Selected subject for PYQ analysis UI.
class SelectedPyqSubjectNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? subject) => state = subject;
}

final selectedPyqSubjectProvider =
    NotifierProvider<SelectedPyqSubjectNotifier, String?>(
  SelectedPyqSubjectNotifier.new,
);

typedef PyqKey = ({
  String university,
  String course,
  String branch,
  String sem,
  String subject,
});

/// Streams the cached PyqAnalysis doc for a curriculum/subject.
final cachedPyqAnalysisProvider =
    StreamProvider.family<PyqAnalysis?, PyqKey>((ref, key) {
  return FirebaseFirestore.instance
      .doc(FirestorePaths.pyqAnalysis(
        key.university,
        key.course,
        key.branch,
        key.sem,
        key.subject,
      ))
      .snapshots()
      .map((doc) => doc.exists ? PyqAnalysis.fromFirestore(doc) : null);
});

/// State for an in-flight analyzer run — exposes runId to the UI so it
/// can subscribe to AnalysisRuns/{runId} for the progress tracker.
class PyqRunState {
  final String? runId;
  final bool isLoading;
  final Object? error;

  const PyqRunState({this.runId, this.isLoading = false, this.error});

  PyqRunState copyWith({String? runId, bool? isLoading, Object? error}) =>
      PyqRunState(
        runId: runId ?? this.runId,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );

  static const initial = PyqRunState();
}

class PyqAnalyzerNotifier extends Notifier<PyqRunState> {
  @override
  PyqRunState build() => PyqRunState.initial;

  Future<void> runAnalysis({
    required String university,
    required String course,
    required String branch,
    required String sem,
    required String subject,
  }) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      state = state.copyWith(error: StateError('Must be signed in.'));
      return;
    }
    final runId = const Uuid().v4();
    state = PyqRunState(runId: runId, isLoading: true);
    try {
      final pyqIds = await _fetchPyqResourceIds(
        university: university,
        course: course,
        branch: branch,
        sem: sem,
        subject: subject,
      );

      final service = ref.read(aiServiceProvider);
      if (service is AgentAIService) {
        await service.analyzePyqWithRunId(
          runId: runId,
          university: university,
          course: course,
          branch: branch,
          sem: sem,
          subject: subject,
          pyqResourceIds: pyqIds,
        );
      } else {
        // Mock or other impl — doesn't know about runIds. Fall back to
        // the standard AIService contract.
        await service.analyzePyq(
          university: university,
          course: course,
          branch: branch,
          sem: sem,
          subject: subject,
          pyqResourceIds: pyqIds,
        );
      }
      state = PyqRunState(runId: runId, isLoading: false);
    } catch (exc) {
      state = PyqRunState(runId: runId, isLoading: false, error: exc);
    }
  }

  void reset() {
    state = PyqRunState.initial;
  }

  Future<List<String>> _fetchPyqResourceIds({
    required String university,
    required String course,
    required String branch,
    required String sem,
    required String subject,
  }) async {
    try {
      final path = FirestorePaths.resources(
        university,
        course,
        branch,
        sem,
        AppConstants.questionPapers,
        subject,
      );
      final snap = await FirebaseFirestore.instance
          .collection(path)
          .limit(20)
          .get()
          .timeout(const Duration(seconds: 8));
      return snap.docs.map((d) => d.id).toList();
    } catch (_) {
      return const [];
    }
  }
}

final pyqAnalyzerProvider =
    NotifierProvider<PyqAnalyzerNotifier, PyqRunState>(
  PyqAnalyzerNotifier.new,
);
```

- [ ] **Step 3: Run analyzer**

```bash
flutter analyze lib/features/pyq_analyzer/
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/pyq_analyzer/providers/pyq_analyzer_provider.dart
git commit -m "refactor(pyq): expose runId during analysis for progress UI

Previously the provider used AsyncNotifier<void> which didn't expose
which run was in flight. Replaced with PyqRunState (runId + isLoading
+ error) so the screen can subscribe to AnalysisRuns/{runId} during
the run.

When aiServiceProvider returns an AgentAIService, we call the
runId-aware analyzePyqWithRunId(). For any other impl (e.g., mock
during local fallback), we fall back to the standard AIService
contract — runId still generated but progress doc never populates.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 25: Wire progress UI into PYQ screen

**Files:**
- Modify: `academic_ally/lib/features/pyq_analyzer/screens/pyq_analyzer_screen.dart`

This is the biggest Flutter change. The existing screen calls `pyqAnalyzerProvider` and renders its loading state. We add a progress panel that shows per-agent checkmarks while `runId != null` and `isLoading == true`.

- [ ] **Step 1: Read the current screen**

```bash
wc -l lib/features/pyq_analyzer/screens/pyq_analyzer_screen.dart
```

(Roughly 450 lines. Full content is in the existing codebase.)

- [ ] **Step 2: Add import for AnalysisRun provider**

Edit `pyq_analyzer_screen.dart`, add at the top with other imports:

```dart
import '../providers/analysis_run_provider.dart';
```

- [ ] **Step 3: Replace the `_runningState()` method**

Find the existing method (around line 270):

```dart
  Widget _runningState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 18),
          Text(
            'Analyzing past papers…',
            style:
                GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
```

Replace with a runId-aware version:

```dart
  Widget _runningState(WidgetRef ref, String? runId) {
    if (runId == null) {
      // Brief window before the run state settles.
      return const Center(child: CircularProgressIndicator());
    }
    final runAsync = ref.watch(analysisRunProvider(runId));
    return runAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: CircularProgressIndicator()),
      data: (run) {
        if (run == null) {
          // Doc hasn't been written yet; show spinner with subject.
          return const Center(child: CircularProgressIndicator());
        }
        return _ProgressPanel(run: run);
      },
    );
  }
```

- [ ] **Step 4: Update call site to pass `ref` + `runId`**

Find where `_runningState()` was called (inside the `Consumer` builder, right after `if (runner.isLoading) return _runningState();`). Replace that line with:

```dart
                        if (runner.isLoading) return _runningState(ref, runner.runId);
```

Also update the `runner` variable declaration nearby — it was `ref.watch(pyqAnalyzerProvider)` which previously returned `AsyncValue<void>` but now returns `PyqRunState`. So:

```dart
                    final runner = ref.watch(pyqAnalyzerProvider);
```

becomes effectively the same variable but now typed `PyqRunState`. The `runner.isLoading` stays. The `runner.hasError` becomes `runner.error != null`. Verify usage patterns throughout the file and update any `runner.error.toString()` to `runner.error?.toString() ?? ""`.

Search the file for `runner.hasError` and `runner.isLoading` and `runner.error` — all should now work with the new typed `PyqRunState`.

- [ ] **Step 5: Add the `_ProgressPanel` widget at the end of the file**

Append to the end of `pyq_analyzer_screen.dart`:

```dart
class _ProgressPanel extends StatelessWidget {
  final AnalysisRun run;

  const _ProgressPanel({required this.run});

  static const _steps = [
    ('syllabus', 'Mapping out the syllabus'),
    ('webResearch', 'Searching the web for past paper patterns'),
    ('pattern', 'Analyzing exam patterns'),
    ('predictor', 'Predicting likely questions'),
    ('formatter', 'Finalizing your analysis'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Analyzing ${run.subject}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF161719),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '6 AI agents collaborating…',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          for (final (key, label) in _steps)
            _ProgressRow(
              label: label,
              isDone: run.isDone(key),
              isFailed: run.isFailedAgent(key),
              isActive: !run.isDone(key) &&
                  !run.isFailedAgent(key) &&
                  run.isRunning,
            ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isFailed;
  final bool isActive;

  const _ProgressRow({
    required this.label,
    required this.isDone,
    required this.isFailed,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    Widget icon;
    if (isDone) {
      icon = const Icon(Icons.check_circle,
          color: Color(0xFF4CAF50), size: 20);
    } else if (isFailed) {
      icon = const Icon(Icons.cancel,
          color: Color(0xFFFF0101), size: 20);
    } else if (isActive) {
      icon = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      icon = Icon(
        Icons.radio_button_unchecked,
        color: Colors.grey[400],
        size: 20,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 24, child: Center(child: icon)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDone
                    ? Colors.grey[700]
                    : isFailed
                        ? const Color(0xFFFF0101)
                        : isActive
                            ? Colors.black87
                            : Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Run analyzer**

```bash
flutter analyze lib/features/pyq_analyzer/
```

Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/features/pyq_analyzer/screens/pyq_analyzer_screen.dart
git commit -m "feat(pyq): wire progressive agent-checkmark UI

Replaces the plain spinner with _ProgressPanel that subscribes to
analysisRunProvider(runId) and renders 5 checkmarks (syllabus, web,
pattern, predictor, formatter). Each row shows check/cross/spinner/
bullet based on agent status. Runs for ~60-90s during a live crew
execution — matches the 'watch the AI think' demo narrative.

_runningState is now ref+runId aware. Screen pulls runId from the
new PyqRunState returned by pyqAnalyzerProvider.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

# Phase 6 — Deploy and verify

## Task 26: Local smoke test (before deploying)

**Files:** none

- [ ] **Step 1: Ensure secrets are set locally for dev**

For local dev smoke test, create a `.env` file in `functions_py/` (already in .gitignore):

```
MINIMAX_API_KEY=<paste your minimax key here>
TAVILY_API_KEY=<paste your tavily key here>
MINIMAX_MODEL=MiniMax-M2
```

**Do not commit this file.** Verify `.env` is ignored:

```bash
cd "C:/Devspace/flutterprojects/Academic Ally/academic_ally"
git check-ignore functions_py/.env
```

Expected output: `functions_py/.env` (meaning it's ignored).

If not ignored, add `.env` to `functions_py/.gitignore` and commit.

- [ ] **Step 2: Add `.env` loader to test harness**

Create a one-off smoke test at `functions_py/smoke_test_pyq.py`:

```python
"""Local smoke test — invokes the PYQ crew end-to-end.

Requires a .env in functions_py/ with MINIMAX_API_KEY, TAVILY_API_KEY.

Run:
    cd academic_ally
    .\functions_py\venv\Scripts\Activate.ps1
    python functions_py/smoke_test_pyq.py
"""
import json
import os
import sys
from pathlib import Path

# Load .env
try:
    from dotenv import load_dotenv

    load_dotenv(Path(__file__).parent / ".env")
except Exception:
    print("WARN: python-dotenv not installed; expecting env vars elsewhere")

# Init firebase_admin so downstream imports work (we skip Firestore writes)
# by setting a dummy credential path. In practice, local smoke test writes
# to the REAL Firestore via Application Default Credentials if you've run
# `firebase login` + `gcloud auth application-default login`.
import firebase_admin
if not firebase_admin._apps:
    firebase_admin.initialize_app()

# Ensure the parent dir is on sys.path (like conftest does for tests)
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from functions_py.features.pyq_analyzer.crew import run_pyq_analysis
from functions_py.features.pyq_analyzer.schema import PyqAnalyzeRequest
from functions_py.shared.progress import init_tracker
from functions_py.features.pyq_analyzer.agents import TRACKER_AGENT_NAMES


def main() -> None:
    req = PyqAnalyzeRequest(
        run_id="smoke-test-local",
        university="JNTUH",
        course="BTECH",
        branch="CSE",
        sem="3",
        subject="Database Management Systems",
        pyq_resource_ids=[],
        force_refresh=True,
    )

    # Init tracker so the step_callback has a doc to write to
    init_tracker(
        run_id=req.run_id,
        subject=req.subject,
        agent_names=TRACKER_AGENT_NAMES,
    )

    print(f"Running PYQ crew for {req.subject}...")
    output = run_pyq_analysis(req)

    print("\n=== RESULT ===\n")
    print(json.dumps(output.to_firestore_dict(), indent=2, default=str))


if __name__ == "__main__":
    main()
```

- [ ] **Step 3: Authenticate for local Firestore writes**

```bash
gcloud auth application-default login
```

(If gcloud isn't installed: https://cloud.google.com/sdk/docs/install. Alternatively, stub out the tracker writes for this one smoke test.)

- [ ] **Step 4: Run the smoke test**

```bash
cd "C:/Devspace/flutterprojects/Academic Ally/academic_ally"
.\functions_py\venv\Scripts\Activate.ps1
python functions_py/smoke_test_pyq.py
```

Expected: Lots of CrewAI verbose log output (agents thinking, delegating). After 60-120s, final JSON printed with:
- `subject: "Database Management Systems"`
- `topicWeights` — a map with 5-6 DBMS topics and decimals summing to ~1.0
- `predictedQuestions` — at least 3 entries, each with question/topic/expectedMarks/likelihood

If output is weird (wrong subject, all weights equal, no predictions), something's broken. Inspect the verbose CrewAI logs for which agent went wrong.

- [ ] **Step 5: Commit the smoke test harness**

```bash
git add functions_py/smoke_test_pyq.py
git commit -m "chore(functions_py): add local smoke test script for PYQ crew

Runs run_pyq_analysis end-to-end against real Minimax + Tavily APIs,
reads keys from functions_py/.env (gitignored). Useful for verifying
agents before deploy. Writes to real Firestore via Application Default
Credentials — requires 'gcloud auth application-default login'.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 27: Deploy the Python codebase

**Files:** none (pure Firebase CLI)

- [ ] **Step 1: Deactivate the local venv**

Firebase expects to build its own Python env in the cloud. Make sure we're not deploying with local venv files:

```bash
deactivate 2>/dev/null || true
```

- [ ] **Step 2: Deploy only the AI codebase**

```bash
cd "C:/Devspace/flutterprojects/Academic Ally/academic_ally"
firebase deploy --only functions:ai --project academic-ally-app
```

Expected behavior:
1. CLI uploads `functions_py/` to Firebase
2. Firebase builds a container image with Python 3.12 + requirements.txt
3. Deploys `pyq_analyze` (HTTPS) and `cleanup_old_trackers` (scheduled)
4. Shows final URLs, e.g.:
   ```
   Function URL (pyq_analyze(us-central1)):
     https://us-central1-academic-ally-app.cloudfunctions.net/pyq_analyze
   ```

First deploy takes 3-6 minutes. Subsequent deploys are faster.

Common failures:
- `Error: Your project...` → check `firebase login`
- `Module not found...` → check `requirements.txt`
- `Python 3.12 not supported...` → change runtime in `firebase.json` to `python311`

- [ ] **Step 3: Verify deployed URL**

```bash
firebase functions:list --project academic-ally-app 2>&1 | grep -i pyq
```

Expected: `pyq_analyze(us-central1) https-trigger`

- [ ] **Step 4: Hit the endpoint with an unauthenticated curl (should get 401)**

```bash
curl -X POST https://us-central1-academic-ally-app.cloudfunctions.net/pyq_analyze \
  -H "Content-Type: application/json" \
  -d '{"run_id":"test","university":"JNTUH","course":"BTECH","branch":"CSE","sem":"3","subject":"DBMS"}'
```

Expected: HTTP 401 with JSON `{"error": "Your session has expired. Please log in again."}`

This confirms the endpoint is live AND auth is enforced.

- [ ] **Step 5: No commit — deploy leaves no files changed**

Skip commit. Next tasks touch files again.

---

## Task 28: End-to-end verification through Flutter (3 subjects)

**Files:** none

- [ ] **Step 1: Build the APK**

Tell the user (do NOT run the build yourself per project convention):

```
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

Install on demo device.

- [ ] **Step 2: Run verification for Subject 1 — DBMS**

Manual steps:
1. Log in (or use existing session)
2. Home screen → AI Tools → PYQ Analyzer
3. Subject picker defaults to the first curriculum subject. If not DBMS, switch.
4. Tap "Run Analysis" (first run, so cache miss expected)
5. Watch the progress panel: 5 agents should check off in order over ~60-90s
6. Once complete, verify:
   - Topic weights show 5-6 DBMS topics, weights sum to ~100%
   - At least 3 predicted questions shown
   - Question text feels plausible (style matches JNTUH papers)
   - Final answer area populated

- [ ] **Step 3: Run verification for Subject 2 — Data Structures**

Switch university/course/branch/sem/subject to a different combination (e.g., OU BE CSE Sem 3 Data Structures) via the user's profile or test account. Run analysis. Verify:
- Trees, Graphs, Hashing show up in topic weights
- Questions mention traversals / complexity

- [ ] **Step 4: Run verification for Subject 3 — Computer Networks**

Switch to JNTUH BTECH IT Sem 5 Computer Networks. Run analysis. Verify:
- OSI/TCP/IP dominate topic weights
- Questions reference layers

- [ ] **Step 5: Inspect one Firestore cache doc manually**

In Firebase Console → Firestore → navigate to one of:
- `PyqAnalysis/JNTUH/BTECH/CSE/3/Database Management Systems`
- `PyqAnalysis/OU/BE/CSE/3/Data Structures`
- `PyqAnalysis/JNTUH/BTECH/IT/5/Computer Networks`

Check:
- `topicWeights` values sum to ~1.0
- `predictedQuestions` has 5+ entries, each with all required fields
- `lastAnalyzed` timestamp is recent
- No hallucinated data

- [ ] **Step 6: Verify cache hit behavior**

Re-run analysis for DBMS (same subject that already ran once). Should:
- Progress panel barely appears (sub-1s)
- Results come back instantly
- Same topic weights and predicted questions as before

This confirms caching is working.

- [ ] **Step 7: No commit for verification — just observe**

If anything is wrong, go back to the relevant earlier task, fix, re-deploy, re-test.

---

## Task 29: Error-path verification

**Files:** none (just runtime checks)

- [ ] **Step 1: Verify 401 on unauthenticated request**

Already done in Task 27 Step 4. Check the app handles it — not just the curl.

In the Flutter app, if you could force an expired token (e.g., by waiting an hour or manually clearing credentials), invoking PYQ Analyzer should show: "Your session has expired. Please log in again." Skip this step if token manipulation is cumbersome — 401 has already been proven at the HTTP layer.

- [ ] **Step 2: Verify graceful failure on bad Minimax key**

```bash
cd "C:/Devspace/flutterprojects/Academic Ally/academic_ally"
firebase functions:secrets:set MINIMAX_API_KEY --project academic-ally-app
# Paste an obviously-invalid value: INVALID_TEST_KEY
```

Redeploy briefly (it'll pick up the new secret without code change):
```bash
firebase deploy --only functions:ai:pyq_analyze --project academic-ally-app
```

Run PYQ Analyzer from the app for a subject. Expected:
- Progress panel starts
- Some agent fails (likely Syllabus Researcher on first Minimax call)
- App shows a friendly "We couldn't complete the analysis this time. Tap to try again." error
- No stack trace visible to the user
- No infinite spinner

- [ ] **Step 3: Restore the real Minimax key**

```bash
firebase functions:secrets:set MINIMAX_API_KEY --project academic-ally-app
# Paste the real key again
firebase deploy --only functions:ai:pyq_analyze --project academic-ally-app
```

Run PYQ again to confirm the real key flow is restored.

- [ ] **Step 4: No commit — behavior verification only**

---

## Task 30: Pre-submission dress rehearsal

**Files:** none

- [ ] **Step 1: Final deploy — everything**

```bash
firebase deploy --project academic-ally-app
```

Deploys both codebases (Node.js stopBilling + Python AI) + storage rules. Should be fast since functions haven't changed since Task 29.

- [ ] **Step 2: Fresh APK build**

Ask user to:
```
flutter build apk --release
```

Install on demo phone.

- [ ] **Step 3: Full user-flow walkthrough**

1. Fresh install (wipe previous install for clean onboarding)
2. Open app → onboarding (4 slides + Skip)
3. Sign up with a fresh test account OR log in
4. Home screen loads → scroll → see AI Tools section
5. Tap "PYQ Analyzer"
6. Pick DBMS (or default subject)
7. Tap "Run Analysis"
8. Watch progress panel tick through 5 agents
9. Result screen shows topic weights + predicted questions
10. Re-tap to confirm cache hit path is snappy

- [ ] **Step 4: Screen recording for submission**

Use Android's built-in screen recorder (or `scrcpy --record`) during the walkthrough. Save the video for submission materials.

- [ ] **Step 5: Final commit**

```bash
git add -A
git status  # confirm nothing unexpected
git commit --allow-empty -m "chore(phase-4b): pre-submission dress rehearsal complete

All verification steps from Section 5 of the design spec passed:
- DBMS, Data Structures, Computer Networks all produce sensible analyses
- Cache hit behavior confirmed (sub-second re-request)
- Graceful failure on bad Minimax key (friendly error, no stack trace)
- Demo flow recorded for submission

Phase 4b (PYQ Analyzer with multi-agent backend) is done.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

# Out-of-scope (for later plans)

These are explicitly NOT in this plan and will be separate plans later:

1. **Porting the other 5 AI features** (Knowledge Map, Study Planner, Gen UI, Snap-a-Doubt, Project Copilot) — each gets its own crew + endpoint + plan
2. **Cloudflare R2 wiring** for PDF storage (separate Phase 4 task)
3. **Strict Firestore rules deployment** (separate Phase 4 task)
4. **Automated test suite** beyond the ~17 unit tests in this plan (deferred to Appendix A of the spec / Phase 5+)
5. **PDF retrieval agent tool** (added when R2 lands, will be a small additional task)
6. **Streaming UX (Server-Sent Events)** — current progress UX uses Firestore polling which is sufficient

---

# Self-review

After completing this plan, verify:

1. ✅ Every section of the spec has a corresponding task
2. ✅ No placeholder steps, no "TBD" or "implement similar to task X"
3. ✅ Type names consistent: PyqAnalyzeRequest, PyqAnalysisOutput, PyqRunState, AnalysisRun, AgentAIService — all used consistently
4. ✅ File paths absolute and exact in every task
5. ✅ Each step shows the actual code / exact commands, no hand-waving
6. ✅ Tests written for the 4 shared modules that need them (errors, auth, cache, progress) — CrewAI-specific behavior is manually verified per Section 5
7. ✅ Commit at the end of each task

Plan complete.
