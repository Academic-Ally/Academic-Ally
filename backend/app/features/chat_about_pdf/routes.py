"""HTTP route for AllyBot's PDF chat."""
import logging
import traceback

from fastapi import APIRouter, Depends, HTTPException

from app.deps import get_uid
from app.errors import AgentFailureError, user_facing_message
from app.shared.demo_fallback import chat_demo, is_demo_curriculum

from .handler import run_chat_about_pdf
from .schema import ChatRequest


logger = logging.getLogger(__name__)
router = APIRouter(tags=["chat_about_pdf"])


@router.post("/chat_about_pdf")
async def chat_about_pdf(req: ChatRequest, uid: str = Depends(get_uid)) -> dict:
    """Single-turn PDF chat. Returns a reply + page citations."""
    if req.uid != uid:
        logger.warning(
            "uid mismatch: token uid=%s body uid=%s — using token uid",
            uid, req.uid,
        )
    logger.info(
        "chat_about_pdf uid=%s subject=%s resource_id=%s prior_turns=%d",
        uid, req.subject, req.resource_id, len(req.prior_turns),
    )

    if is_demo_curriculum(req.branch, req.sem):
        logger.warning(
            "Chat demo fallback active for branch=%s sem=%s", req.branch, req.sem
        )
        return chat_demo(req.subject, req.question)

    try:
        response = await run_chat_about_pdf(req)
    except Exception as exc:
        tb = traceback.format_exc()
        logger.exception("chat_about_pdf failed")
        status_code = 503 if isinstance(exc, AgentFailureError) else 500
        raise HTTPException(
            status_code=status_code,
            detail={
                "error": user_facing_message(exc),
                "debug_error": str(exc)[:2000],
                "debug_traceback": tb[-2000:],
            },
        )

    return {
        "reply": response.reply,
        "grounded": response.grounded,
        "citations": [
            {"pageStart": c.page_start, "pageEnd": c.page_end}
            for c in response.citations
        ],
    }
