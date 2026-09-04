"""HTTP routes for the PYQ Analyzer feature."""
import logging
import traceback

from fastapi import APIRouter, Depends, HTTPException

from app.deps import get_uid
from app.errors import AgentFailureError, error_detail
from app.shared.cache import read_cache, write_cache
from app.shared.progress import init_tracker, mark_complete, mark_failed

from .agents import TRACKER_AGENT_NAMES
from .crew import run_pyq_analysis
from .schema import PyqAnalyzeRequest


logger = logging.getLogger(__name__)
router = APIRouter(tags=["pyq"])


def _cache_path(req: PyqAnalyzeRequest) -> str:
    return f"PyqAnalysis/{req.university}/{req.course}/{req.branch}/{req.sem}/{req.subject}"


@router.post("/pyq_analyze")
async def pyq_analyze(req: PyqAnalyzeRequest, uid: str = Depends(get_uid)) -> dict:
    """Run the 5-agent PYQ Analyzer crew (or return a cached result)."""
    logger.info("pyq_analyze uid=%s subject=%s run_id=%s", uid, req.subject, req.run_id)

    cache_key = _cache_path(req)
    if not req.force_refresh:
        cached = read_cache(cache_key, freshness_hours=24)
        if cached is not None:
            return cached

    init_tracker(
        run_id=req.run_id,
        subject=req.subject,
        agent_names=TRACKER_AGENT_NAMES,
    )

    try:
        output = await run_pyq_analysis(req)
    except Exception as exc:
        tb = traceback.format_exc()
        logger.exception("pyq_analyze failed")
        mark_failed(req.run_id, failing_agent="crew", error_message=str(exc)[:500])
        status_code = 503 if isinstance(exc, AgentFailureError) else 500
        raise HTTPException(
            status_code=status_code,
            detail=error_detail(exc, tb),
        )

    doc = output.to_firestore_dict()
    doc["sourceResourceIds"] = req.pyq_resource_ids
    write_cache(cache_key, doc)
    mark_complete(req.run_id)
    return doc
