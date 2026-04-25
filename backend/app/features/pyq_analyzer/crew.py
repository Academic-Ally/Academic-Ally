"""PYQ Analyzer crew assembly and invocation.

``run_pyq_analysis`` is the single entry point. It builds the crew,
kicks it off via CrewAI's native async ``akickoff``, and returns a
validated ``PyqAnalysisOutput``. Exceptions bubble up to the route
handler for user-facing translation.
"""
import logging
from typing import Any

from app.errors import AgentFailureError
from app.shared.crew_factory import build_hierarchical_crew
from app.shared.progress import make_crewai_step_callback
from app.shared.rag.ingest import ingest_subject
from app.shared.rag.vector_store import is_ingested, make_subject_key

from .agents import AGENT_ROLE_TO_TRACKER, build_pyq_agents
from .schema import PyqAnalysisOutput, PyqAnalyzeRequest
from .tasks import build_pyq_tasks


logger = logging.getLogger(__name__)


async def run_pyq_analysis(req: PyqAnalyzeRequest) -> PyqAnalysisOutput:
    """Run the PYQ Analyzer workflow.

    Assumes a tracker entry already exists for ``req.run_id`` (the route
    handler calls ``init_tracker`` before invoking this). Updates the
    tracker as agents complete. Raises ``AgentFailureError`` on any
    unrecoverable crew failure.
    """
    subject_key = make_subject_key(
        university=req.university,
        course=req.course,
        branch=req.branch,
        sem=req.sem,
        subject=req.subject,
    )

    # Lazy ingestion: if this subject has never been indexed, do it now.
    # Subsequent requests find an already-warm index and skip this.
    if not is_ingested(subject_key):
        logger.info("RAG index missing for %s — ingesting now", subject_key)
        result = await ingest_subject(
            university=req.university,
            course=req.course,
            branch=req.branch,
            sem=req.sem,
            subject=req.subject,
        )
        logger.info(
            "ingest done: %d resources indexed (%d skipped, %d failures), %d chunks",
            result.resources_ingested,
            result.resources_skipped,
            len(result.failures),
            result.chunks_added,
        )

    agents_dict = build_pyq_agents(subject_key)
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
        result = await crew.akickoff(inputs=inputs)
    except Exception as exc:
        logger.exception("PYQ crew failed")
        raise AgentFailureError(f"crew.akickoff failed: {exc}") from exc

    pydantic_output = getattr(result, "pydantic", None)
    if pydantic_output is None or not isinstance(pydantic_output, PyqAnalysisOutput):
        try:
            raw = getattr(result, "raw", str(result))
            pydantic_output = PyqAnalysisOutput.model_validate_json(raw)
        except Exception as exc:
            raise AgentFailureError(
                f"output formatter did not produce valid JSON: {exc}"
            ) from exc
    return pydantic_output
