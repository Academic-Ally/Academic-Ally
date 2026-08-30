"""HTTP route for Snap-a-Doubt."""
import logging
import traceback

from fastapi import APIRouter, Depends, HTTPException
from firebase_admin import firestore, storage
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.deps import get_uid
from app.errors import AgentFailureError, ValidationError, user_facing_message
from app.shared.progress import init_tracker, mark_complete, mark_failed

from .agents import TRACKER_AGENT_NAMES
from .crew import run_snap_doubt
from .schema import SnapDoubtRequest


logger = logging.getLogger(__name__)
router = APIRouter(tags=["snap_doubt"])


def _public_image_url(storage_id: str) -> str:
    """Generate a download URL for the image so the Flutter UI can render it.

    Uses Firebase Storage's per-file public URL with token. Note: this
    requires the file to have been uploaded with a generated download
    token (Firebase SDKs do this by default). For demo phase the
    storage rules already allow auth'd reads, so this works.
    """
    bucket = storage.bucket()
    blob = bucket.blob(storage_id)
    # Firebase-style URL format. The Flutter SDK generates download
    # tokens automatically on upload, so this resolves on the client side.
    return (
        f"https://firebasestorage.googleapis.com/v0/b/{bucket.name}/o/"
        f"{storage_id.replace('/', '%2F')}?alt=media"
    )


def _persist_doubt(uid: str, doubt_id: str, payload: dict) -> None:
    """Write the solution to Users/{uid}/DoubtHistory/{doubt_id}.

    Mirrors the path the existing Flutter doubtHistoryProvider streams.
    """
    client = firestore.client()
    doc = {**payload, "createdAt": SERVER_TIMESTAMP}
    client.document(f"Users/{uid}/DoubtHistory/{doubt_id}").set(doc)


@router.post("/solve_doubt")
async def solve_doubt(
    req: SnapDoubtRequest, uid: str = Depends(get_uid)
) -> dict:
    """Run the Snap-a-Doubt agentic crew + persist the solution."""
    if req.uid != uid:
        logger.warning(
            "uid mismatch: token uid=%s body uid=%s — using token uid",
            uid, req.uid,
        )

    logger.info(
        "solve_doubt uid=%s subject=%s doubt_id=%s run_id=%s",
        uid, req.subject, req.doubt_id, req.run_id,
    )

    init_tracker(
        run_id=req.run_id,
        subject=req.subject,
        agent_names=TRACKER_AGENT_NAMES,
    )

    try:
        output = await run_snap_doubt(req)
    except ValidationError as exc:
        # User-fixable: e.g. blank image. Don't 500 — return a 400 with a
        # friendly message so Flutter can show a retake prompt.
        mark_failed(req.run_id, failing_agent="vision", error_message=str(exc))
        raise HTTPException(
            status_code=400,
            detail={"error": str(exc)},
        )
    except Exception as exc:
        tb = traceback.format_exc()
        logger.exception("solve_doubt failed")
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

    image_url = _public_image_url(req.storage_id)
    payload = output.to_firestore_dict(image_url=image_url)
    _persist_doubt(uid, req.doubt_id, payload)
    mark_complete(req.run_id)

    return {"doubt_id": req.doubt_id, **payload}
