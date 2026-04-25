"""Adversarial Examiner crew assembly + entry point."""
import logging
from typing import Any

from app.errors import AgentFailureError
from app.shared.crew_factory import build_hierarchical_crew
from app.shared.progress import make_crewai_step_callback
from app.shared.rag.ingest import ingest_subject
from app.shared.rag.vector_store import is_ingested, make_subject_key

from .agents import AGENT_ROLE_TO_TRACKER, build_examiner_agents
from .schema import AdversarialExamOutput, AdversarialRequest
from .tasks import build_examiner_tasks


logger = logging.getLogger(__name__)


async def run_adversarial_exam_generation(
    req: AdversarialRequest,
) -> AdversarialExamOutput:
    """Run the Adversarial Examiner workflow."""
    subject_key = make_subject_key(
        university=req.university,
        course=req.course,
        branch=req.branch,
        sem=req.sem,
        subject=req.subject,
    )

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

    agents_dict = build_examiner_agents(subject_key)
    tasks = build_examiner_tasks(agents_dict)

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
        "focus_topics": ", ".join(req.focus_topics) if req.focus_topics else "(none)",
        "question_count": req.question_count,
    }

    try:
        result = await crew.akickoff(inputs=inputs)
    except Exception as exc:
        logger.exception("examiner crew failed")
        raise AgentFailureError(f"crew.akickoff failed: {exc}") from exc

    pydantic_output = getattr(result, "pydantic", None)
    if pydantic_output is None or not isinstance(pydantic_output, AdversarialExamOutput):
        try:
            raw = getattr(result, "raw", str(result))
            pydantic_output = AdversarialExamOutput.model_validate_json(raw)
        except Exception as exc:
            raise AgentFailureError(
                f"output formatter did not produce valid JSON: {exc}"
            ) from exc
    return pydantic_output
