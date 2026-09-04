"""HTTP route for Study Planner."""
import logging
import traceback

from fastapi import APIRouter, Depends, HTTPException
from firebase_admin import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.deps import get_uid
from app.errors import AgentFailureError, error_detail
from app.shared.progress import init_tracker, mark_complete, mark_failed

from .agents import TRACKER_AGENT_NAMES
from .crew import run_study_plan_generation
from .schema import StudyPlanRequest


logger = logging.getLogger(__name__)
router = APIRouter(tags=["study_planner"])


def _persist_plan(uid: str, plan_id: str, payload: dict) -> None:
    """Write the generated plan to Users/{uid}/StudyPlans/{plan_id}.

    Flutter's userStudyPlansProvider streams this collection so the UI
    will pick the new doc up automatically.
    """
    client = firestore.client()
    doc = {
        **payload,
        "createdAt": SERVER_TIMESTAMP,
    }
    client.document(f"Users/{uid}/StudyPlans/{plan_id}").set(doc)


@router.post("/generate_study_plan")
async def generate_study_plan(
    req: StudyPlanRequest, uid: str = Depends(get_uid)
) -> dict:
    """Run the 4-agent Study Planner crew and persist the plan."""
    if req.uid != uid:
        # Caller can only create plans for themselves (admin bypass uses
        # the supplied uid, so they can act on behalf of any user).
        logger.warning(
            "uid mismatch: token uid=%s body uid=%s — using token uid", uid, req.uid
        )

    logger.info(
        "generate_study_plan uid=%s subjects=%s run_id=%s",
        uid,
        req.subjects,
        req.run_id,
    )

    init_tracker(
        run_id=req.run_id,
        subject=", ".join(req.subjects),
        agent_names=TRACKER_AGENT_NAMES,
    )

    try:
        output = await run_study_plan_generation(req)
    except Exception as exc:
        tb = traceback.format_exc()
        logger.exception("study plan generation failed")
        mark_failed(req.run_id, failing_agent="crew", error_message=str(exc)[:500])
        status_code = 503 if isinstance(exc, AgentFailureError) else 500
        raise HTTPException(
            status_code=status_code,
            detail=error_detail(exc, tb),
        )

    payload = output.to_firestore_dict()
    _persist_plan(uid, output.plan_id, payload)
    mark_complete(req.run_id)

    # Return the plan_id so the Flutter caller can navigate to the detail
    # screen. The full plan is in Firestore, picked up by the live stream.
    return {"plan_id": output.plan_id, **payload}
