"""Snap-a-Doubt crew assembly + entry point.

Flow:
1. Lazy-ingest the subject's RAG index if missing.
2. Run the vision pre-step (NOT a CrewAI agent — direct Gemini multimodal
   call). On success, mark ``vision`` tracker done.
3. If vision returned NO_QUESTION_DETECTED, raise a typed error so the
   route can return a friendly message instead of running the crew.
4. Run the 4-agent crew (retriever → solver → validator → formatter).
5. Resolve each citation's filename → Firestore resource doc → storageId
   so the Flutter UI can open the cited PDF at the cited page.
"""
import logging
from typing import Any

from firebase_admin import firestore

from app.errors import AgentFailureError, ValidationError
from app.shared.crew_factory import build_hierarchical_crew
from app.shared.progress import make_crewai_step_callback, update_agent_status
from app.shared.rag.ingest import ingest_subject
from app.shared.rag.vector_store import is_ingested, make_subject_key

from .agents import AGENT_ROLE_TO_TRACKER, build_snap_doubt_agents
from .schema import DoubtSolutionOutput, SnapDoubtRequest
from .tasks import build_snap_doubt_tasks
from .vision import extract_question_from_image


logger = logging.getLogger(__name__)


def _build_resource_index_by_id(req: SnapDoubtRequest) -> dict[str, dict]:
    """Return a {resource_id: resource_doc_dict} map for the subject.

    Walks all categories (Notes / QuestionPapers / Syllabus / OtherResources)
    under ``Universities/{uni}/{course}/{branch}/{sem}/{type}/{subject}``.
    Keyed by the Firestore document ID (which is what we hand the agent
    as ``resourceId`` in the search results).
    """
    client = firestore.client()
    out: dict[str, dict] = {}
    for category in ("Notes", "QuestionPapers", "Syllabus", "OtherResources"):
        path = (
            f"Universities/{req.university}/{req.course}/{req.branch}/"
            f"{req.sem}/{category}/{req.subject}"
        )
        for snap in client.collection(path).stream():
            data = snap.to_dict() or {}
            storage_id = data.get("storageId")
            if not storage_id:
                continue
            out[snap.id] = {
                "storage_id": storage_id,
                "category": category,
                "name": data.get("name") or "",
            }
    return out


def _resolve_citations(
    output: DoubtSolutionOutput, req: SnapDoubtRequest
) -> DoubtSolutionOutput:
    """Populate ``filename`` / ``storage_id`` / ``category`` on each citation.

    The agent emits citations with only ``resource_id`` set (from the
    ``[CITE:resource_id:page]`` markers). We look those IDs up against
    the subject's resource collection and fill in display + click
    metadata. Citations whose ID doesn't match keep null storage_id so
    the Flutter UI renders them as plain (non-clickable) chips.
    """
    index = _build_resource_index_by_id(req)
    if not index:
        logger.warning(
            "no resource docs found for subject=%s — all citations stay unresolved",
            req.subject,
        )
        return output

    matched = 0
    unmatched = 0
    for step in output.steps:
        for citation in step.citations:
            hit = index.get(citation.resource_id)
            if hit is None:
                unmatched += 1
                logger.warning(
                    "citation resourceId=%s not found in subject=%s index",
                    citation.resource_id, req.subject,
                )
                # Best-effort display label since we don't know the file
                if not citation.filename:
                    citation.filename = "(unknown source)"
                continue
            citation.storage_id = hit["storage_id"]
            citation.category = hit["category"]
            citation.filename = hit["name"] or citation.filename
            matched += 1
    logger.info(
        "citation resolution: %d matched, %d unmatched", matched, unmatched
    )
    return output


async def run_snap_doubt(req: SnapDoubtRequest) -> DoubtSolutionOutput:
    """Run the Snap-a-Doubt workflow."""
    subject_key = make_subject_key(
        university=req.university,
        course=req.course,
        branch=req.branch,
        sem=req.sem,
        subject=req.subject,
    )

    # 1. Lazy-ingest if subject's notes haven't been RAG-indexed yet.
    if not is_ingested(subject_key):
        logger.info("RAG missing for %s — ingesting", subject_key)
        result = await ingest_subject(
            university=req.university,
            course=req.course,
            branch=req.branch,
            sem=req.sem,
            subject=req.subject,
        )
        logger.info(
            "ingest done: %d resources, %d chunks, %d failures",
            result.resources_ingested, result.chunks_added, len(result.failures),
        )

    # 2. Vision pre-step. Mark tracker after success.
    try:
        extracted = await extract_question_from_image(req.storage_id)
    except Exception as exc:
        logger.exception("vision extraction failed")
        raise AgentFailureError(f"vision step failed: {exc}") from exc

    if extracted.strip().upper().startswith("NO_QUESTION_DETECTED"):
        raise ValidationError(
            "Couldn't read a question from the image. Please retake the "
            "photo with better lighting and focus."
        )

    update_agent_status(req.run_id, "vision", "done")

    # 3. Build + run the crew.
    agents_dict = build_snap_doubt_agents(subject_key)
    tasks = build_snap_doubt_tasks(agents_dict)

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
        "extracted_question": extracted,
        "run_id": req.run_id,
    }

    try:
        result = await crew.akickoff(inputs=inputs)
    except Exception as exc:
        logger.exception("snap doubt crew failed")
        raise AgentFailureError(f"crew.akickoff failed: {exc}") from exc

    pydantic_output = getattr(result, "pydantic", None)
    if pydantic_output is None or not isinstance(pydantic_output, DoubtSolutionOutput):
        try:
            raw = getattr(result, "raw", str(result))
            pydantic_output = DoubtSolutionOutput.model_validate_json(raw)
        except Exception as exc:
            raise AgentFailureError(
                f"output formatter did not produce valid JSON: {exc}"
            ) from exc

    # 5. Resolve each citation's filename → Firestore resource doc → storageId.
    pydantic_output = _resolve_citations(pydantic_output, req)
    return pydantic_output
