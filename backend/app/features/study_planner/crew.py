"""Study Planner crew assembly + entry point.

Pre-fetch strategy: all RAG-derived data is materialized server-side
before the crew runs and injected into task prompts. Agents are
toolless — they reason from the injected text only.
"""
import asyncio
import logging
from datetime import datetime, timezone
from typing import Any

from firebase_admin import firestore

from app.errors import AgentFailureError
from app.shared.crew_factory import build_hierarchical_crew
from app.shared.progress import make_crewai_step_callback
from app.shared.rag.embedder import embed_one
from app.shared.rag.ingest import ingest_subject
from app.shared.rag.vector_store import is_ingested, make_subject_key, search

from .agents import AGENT_ROLE_TO_TRACKER, build_study_planner_agents
from .schema import StudyPlanOutput, StudyPlanRequest
from .tasks import build_study_planner_tasks


logger = logging.getLogger(__name__)


def _fetch_mastery_snapshot(uid: str) -> str:
    client = firestore.client()
    coll = client.collection(f"Users/{uid}/MasteryScores")
    docs = list(coll.stream())
    if not docs:
        return (
            "(no mastery data yet — student is new. Default all topics "
            "to mastery score 0.5 and rely on user-supplied weak topics.)"
        )
    lines = []
    for snap in docs:
        d = snap.to_dict() or {}
        lines.append(
            f"- nodeId={snap.id}: score={d.get('score', 0.5):.2f} "
            f"attempts={d.get('attempts', 0)}"
        )
    return "\n".join(lines)


def _fetch_cached_pyq(req: StudyPlanRequest, subject: str) -> dict | None:
    """Try to read PyqAnalysis/{path} for a subject. Returns None if missing."""
    path = (
        f"PyqAnalysis/{req.university}/{req.course}/{req.branch}/"
        f"{req.sem}/{subject}"
    )
    snap = firestore.client().document(path).get()
    return snap.to_dict() if snap.exists else None


def _count_chunks(subject_key: str, category: str | None = None) -> int:
    """Count RAG chunks for a subject, optionally filtered by category."""
    coll = firestore.client().collection(f"RagChunks/{subject_key}/chunks")
    if category:
        coll = coll.where("category", "==", category)
    # count() is a Firestore aggregation — cheap, no doc reads.
    try:
        agg = coll.count().get()
        return int(agg[0][0].value) if agg else 0
    except Exception:
        # Fallback: stream + len. Slower but always works.
        return sum(1 for _ in coll.stream())


async def _build_subjects_context(req: StudyPlanRequest) -> tuple[str, str]:
    """Materialize the per-subject RAG context + effort snapshot.

    Returns ``(subjects_context, effort_snapshot)`` ready to inject into
    task prompts.
    """
    subjects_blocks: list[str] = []
    effort_lines: list[str] = []

    for subject in req.subjects:
        key = make_subject_key(
            university=req.university,
            course=req.course,
            branch=req.branch,
            sem=req.sem,
            subject=subject,
        )

        # Ensure the index exists. Lazy-ingest on first request for this subject.
        if not is_ingested(key):
            logger.info("RAG missing for %s — ingesting", key)
            result = await ingest_subject(
                university=req.university,
                course=req.course,
                branch=req.branch,
                sem=req.sem,
                subject=subject,
            )
            logger.info(
                "ingest done for %s: %d resources, %d chunks, %d failures",
                subject, result.resources_ingested, result.chunks_added, len(result.failures),
            )

        # Pull cached PYQ analysis if it exists
        cached_pyq = _fetch_cached_pyq(req, subject)

        # Direct RAG hit for "important topics" — gives us actual indexed-paper
        # snippets even if PYQ hasn't been run yet.
        try:
            query_emb = await embed_one(
                f"{subject} important topics frequently asked exam questions"
            )
            top_chunks = search(subject_key=key, query_embedding=query_emb, top_k=4)
        except Exception as exc:
            logger.warning("subject context search failed for %s: %s", subject, exc)
            top_chunks = []

        # Effort proxy: total Notes chunks
        notes_chunks = _count_chunks(key, category="Notes")
        total_chunks = _count_chunks(key)
        effort_lines.append(
            f"- {subject}: total_chunks={total_chunks}, notes_chunks={notes_chunks}"
        )

        block = [f"## {subject}"]
        if cached_pyq and cached_pyq.get("topicWeights"):
            tw = cached_pyq["topicWeights"]
            block.append("Cached topic weights from PYQ Analyzer:")
            for topic, weight in sorted(tw.items(), key=lambda x: -x[1]):
                block.append(f"  - {topic}: {weight:.2f}")
        else:
            block.append("(no cached PYQ analysis — derive from indexed material below)")

        if top_chunks:
            block.append("\nTop indexed-document hits for 'important topics':")
            for i, chunk in enumerate(top_chunks, 1):
                fname = chunk.get("filename", "?")
                p_start = chunk.get("pageStart", "?")
                p_end = chunk.get("pageEnd", p_start)
                page_label = f"p.{p_start}" if p_start == p_end else f"pp.{p_start}-{p_end}"
                snippet = (chunk.get("text") or "")[:400].replace("\n", " ")
                block.append(f"  [{i}] {fname} ({page_label}): {snippet}…")
        else:
            block.append("(no indexed material returned for this subject)")

        subjects_blocks.append("\n".join(block))

    return "\n\n".join(subjects_blocks), "\n".join(effort_lines)


async def run_study_plan_generation(req: StudyPlanRequest) -> StudyPlanOutput:
    """Run the Study Planner workflow."""
    subjects_context, effort_snapshot = await _build_subjects_context(req)
    mastery_snapshot = _fetch_mastery_snapshot(req.uid)

    agents_dict = build_study_planner_agents()
    tasks = build_study_planner_tasks(
        agents_dict,
        subjects_context=subjects_context,
        mastery_snapshot=mastery_snapshot,
        effort_snapshot=effort_snapshot,
    )

    step_callback = make_crewai_step_callback(
        run_id=req.run_id,
        agent_name_map=AGENT_ROLE_TO_TRACKER,
    )

    crew = build_hierarchical_crew(
        agents=list(agents_dict.values()),
        tasks=tasks,
        step_callback=step_callback,
    )

    today = datetime.now(timezone.utc).date()
    inputs: dict[str, Any] = {
        "subjects": ", ".join(req.subjects),
        "weak_topics": ", ".join(req.weak_topics) if req.weak_topics else "(none)",
        "today_iso": today.isoformat(),
        "exam_date_iso": req.exam_date.date().isoformat(),
        "days_until_exam": max(1, (req.exam_date.date() - today).days),
        "daily_study_minutes": req.daily_study_minutes,
        "run_id": req.run_id,
    }

    try:
        result = await crew.akickoff(inputs=inputs)
    except Exception as exc:
        logger.exception("study planner crew failed")
        raise AgentFailureError(f"crew.akickoff failed: {exc}") from exc

    pydantic_output = getattr(result, "pydantic", None)
    if pydantic_output is None or not isinstance(pydantic_output, StudyPlanOutput):
        try:
            raw = getattr(result, "raw", str(result))
            pydantic_output = StudyPlanOutput.model_validate_json(raw)
        except Exception as exc:
            raise AgentFailureError(
                f"schedule planner did not produce valid JSON: {exc}"
            ) from exc
    return pydantic_output
