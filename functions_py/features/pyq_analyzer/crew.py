"""PYQ Analyzer crew assembly and invocation.

``run_pyq_analysis`` is the single entry point — it builds the crew,
kicks off the workflow, and returns a validated PyqAnalysisOutput.
Exceptions bubble up to the HTTP handler for user-facing translation.
"""
import logging
from typing import Any

from shared.crew_factory import build_hierarchical_crew
from shared.errors import AgentFailureError
from shared.progress import make_crewai_step_callback

from .agents import AGENT_ROLE_TO_TRACKER, TRACKER_AGENT_NAMES, build_pyq_agents
from .schema import PyqAnalysisOutput, PyqAnalyzeRequest
from .tasks import build_pyq_tasks


logger = logging.getLogger(__name__)


def run_pyq_analysis(req: PyqAnalyzeRequest) -> PyqAnalysisOutput:
    """Run the PYQ Analyzer workflow.

    Assumes progress tracker already exists at AnalysisRuns/{req.run_id}.
    Updates the tracker as agents complete. Raises AgentFailureError on
    any unrecoverable crew failure.
    """
    agents_dict = build_pyq_agents()
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
        result = crew.kickoff(inputs=inputs)
    except Exception as exc:
        logger.exception("PYQ crew failed")
        raise AgentFailureError(f"crew.kickoff failed: {exc}") from exc

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
