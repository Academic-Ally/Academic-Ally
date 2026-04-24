"""HTTP handler for POST /ai/pyq-analyze.

Wired up by main.py via firebase_functions.https_fn.on_request.
"""
import json
import logging

from firebase_functions import https_fn
from pydantic import ValidationError as PydanticValidationError

from shared.auth import extract_uid
from shared.cache import read_cache, write_cache
from shared.errors import (
    AgentFailureError,
    AuthError,
    ValidationError,
    user_facing_message,
)
from shared.progress import (
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

    try:
        uid = extract_uid(request.headers)
    except AuthError as exc:
        logger.warning("auth rejected: %s", exc)
        return https_fn.Response(
            json.dumps({"error": user_facing_message(exc)}),
            status=401,
            content_type="application/json",
        )

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

    if not req.force_refresh:
        cached = read_cache(cache_key, freshness_hours=24)
        if cached:
            logger.info("cache hit for %s", cache_key)
            return https_fn.Response(
                json.dumps(cached, default=str),
                status=200,
                content_type="application/json",
            )

    init_tracker(
        run_id=req.run_id,
        subject=req.subject,
        agent_names=TRACKER_AGENT_NAMES,
    )

    try:
        output = run_pyq_analysis(req)
    except Exception as exc:
        import traceback
        tb = traceback.format_exc()
        logger.exception("pyq analysis failed")
        mark_failed(req.run_id, failing_agent="crew", error_message=str(exc)[:500])
        status = 503 if isinstance(exc, AgentFailureError) else 500
        return https_fn.Response(
            json.dumps({
                "error": user_facing_message(exc),
                "debug_error": str(exc)[:2000],
                "debug_traceback": tb[-2000:],
            }),
            status=status,
            content_type="application/json",
        )

    firestore_doc = output.to_firestore_dict()
    firestore_doc["sourceResourceIds"] = req.pyq_resource_ids
    write_cache(cache_key, firestore_doc)
    mark_complete(req.run_id)

    return https_fn.Response(
        json.dumps(firestore_doc, default=str),
        status=200,
        content_type="application/json",
    )
