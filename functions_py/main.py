"""Firebase Functions Gen 2 entry point for the Python AI backend.

Exports every HTTPS + scheduled function Firebase deploys to this
codebase. Each feature lives in its own module; main.py just re-exports
the right symbols.
"""
import firebase_admin
from firebase_functions import https_fn, options

if not firebase_admin._apps:
    firebase_admin.initialize_app()


options.set_global_options(
    region="us-central1",
    timeout_sec=540,
    memory=options.MemoryOption.MB_512,
)


from functions_py.features.pyq_analyzer.handler import pyq_analyze_handler  # noqa: E402
from functions_py.features.maintenance.cleanup import cleanup_old_trackers  # noqa: E402,F401


@https_fn.on_request(
    secrets=["GEMINI_API_KEY", "TAVILY_API_KEY"],
    timeout_sec=540,
    cors=options.CorsOptions(
        cors_origins=["*"],
        cors_methods=["POST", "OPTIONS"],
    ),
)
def pyq_analyze(request: https_fn.Request) -> https_fn.Response:
    """POST /pyq_analyze — PYQ Analyzer endpoint."""
    return pyq_analyze_handler(request)
