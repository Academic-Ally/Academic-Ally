"""HTTP route for Adversarial Examiner."""
import logging
import traceback

from fastapi import APIRouter, Depends, HTTPException

from app.deps import get_uid
from app.errors import AgentFailureError, user_facing_message
from app.shared.cache import read_cache, write_cache
from app.shared.demo_fallback import (
    adversarial_demo,
    animate_demo_progress,
    is_demo_curriculum,
)
from app.shared.progress import init_tracker, mark_complete, mark_failed

from .agents import TRACKER_AGENT_NAMES
from .crew import run_adversarial_exam_generation
from .schema import AdversarialRequest


logger = logging.getLogger(__name__)
router = APIRouter(tags=["adversarial_examiner"])


def _cache_path(req: AdversarialRequest) -> str:
    """Build a Firestore-valid document path (even segment count).

    Path: ``AdversarialExams/{uni}/{course}/{branch}/{sem}/{doc_id}``
    where ``doc_id`` packs subject + focus + count into a single segment.
    """
    focus = "all" if not req.focus_topics else "+".join(sorted(req.focus_topics))
    # Slashes inside subject names would break the path; underscore-fence
    # the variable parts.
    safe_subject = req.subject.replace("/", "_")
    doc_id = f"{safe_subject}__{focus}__q{req.question_count}"
    return (
        f"AdversarialExams/{req.university}/{req.course}/{req.branch}/"
        f"{req.sem}/{doc_id}"
    )


@router.post("/generate_adversarial_exam")
async def generate_adversarial_exam(
    req: AdversarialRequest, uid: str = Depends(get_uid)
) -> dict:
    """Run the 4-agent Adversarial Examiner crew."""
    logger.info(
        "adversarial uid=%s subject=%s run_id=%s",
        uid, req.subject, req.run_id,
    )

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

    if is_demo_curriculum(req.branch, req.sem):
        logger.warning(
            "Adversarial demo fallback active for branch=%s sem=%s",
            req.branch,
            req.sem,
        )
        await animate_demo_progress(req.run_id, TRACKER_AGENT_NAMES)
        doc = adversarial_demo(req.subject, req.question_count)
        write_cache(cache_key, doc)
        mark_complete(req.run_id)
        return doc

    try:
        output = await run_adversarial_exam_generation(req)
    except Exception as exc:
        tb = traceback.format_exc()
        logger.exception("adversarial exam generation failed")
        mark_failed(req.run_id, failing_agent="crew", error_message=str(exc)[:500])
        status_code = 503 if isinstance(exc, AgentFailureError) else 500
        raise HTTPException(
            status_code=status_code,
            detail={
                "error": user_facing_message(exc),
                "debug_error": str(exc)[:2000],
                "debug_traceback": tb[-2000:],
            },
        )

    doc = output.to_firestore_dict()
    write_cache(cache_key, doc)
    mark_complete(req.run_id)
    return doc
