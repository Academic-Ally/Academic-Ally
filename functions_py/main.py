"""Firebase Functions Gen 2 entry point for the Python AI backend.

Exports every HTTPS + scheduled function Firebase deploys to this
codebase. Each feature lives in its own module; main.py just re-exports
the right symbols.
"""
import os
import sys
import tempfile

# CrewAI 1.x eagerly instantiates an EventListener at import time,
# which calls TokenManager() → _get_secure_storage_path() → Path(base).
# In the Firebase Functions deploy analyzer (and in some serverless
# cold-start contexts) the OS-specific base dir env var is missing,
# so Path(None) raises. Point them at a writable temp dir before any
# crewai import runs.
if sys.platform == "win32":
    os.environ.setdefault("LOCALAPPDATA", tempfile.gettempdir())
else:
    os.environ.setdefault("HOME", tempfile.gettempdir())
os.environ.setdefault("CREWAI_TRACING_ENABLED", "false")

import firebase_admin  # noqa: E402
from firebase_functions import https_fn, options  # noqa: E402

if not firebase_admin._apps:
    firebase_admin.initialize_app()


options.set_global_options(
    region="us-central1",
    timeout_sec=540,
    memory=options.MemoryOption.GB_1,
)


# Only import what Firebase's deploy-analyzer needs right now.
# The heavy crewai/handler import is deferred to first-request time so
# the analyzer's 10-second source-scan doesn't time out loading ML deps.
from features.maintenance.cleanup import cleanup_old_trackers  # noqa: E402,F401


@https_fn.on_request(
    secrets=["GEMINI_API_KEY", "TAVILY_API_KEY", "LLM_MODEL"],
    timeout_sec=540,
    cors=options.CorsOptions(
        cors_origins=["*"],
        cors_methods=["POST", "OPTIONS"],
    ),
)
def pyq_analyze(request: https_fn.Request) -> https_fn.Response:
    """POST /pyq_analyze — PYQ Analyzer endpoint."""
    from features.pyq_analyzer.handler import pyq_analyze_handler
    return pyq_analyze_handler(request)
