"""CrewAI task definitions for Study Planner.

Tasks are chained — each task's ``context`` includes prior tasks so the
next agent sees accumulated findings. The Schedule Planner final task
emits the structured plan via output_pydantic.

All RAG-derived data is pre-fetched server-side and injected into task
descriptions (no agent makes a tool call). See ``crew.py``.
"""
from crewai import Task

from .schema import StudyPlanOutput


def build_study_planner_tasks(
    agents: dict,
    *,
    subjects_context: str,
    mastery_snapshot: str,
    effort_snapshot: str,
):
    """Build the 4 ordered tasks.

    Args:
        agents: Output of build_study_planner_agents().
        subjects_context: Markdown block — per-subject topic weights and
            highlights, materialized from cached PYQ analyses + RAG hits.
        mastery_snapshot: Pre-fetched MasteryScores summary string.
        effort_snapshot: Per-subject Notes density (chunk counts) for
            effort estimation.
    """
    rank_topic_importance = Task(
        description=(
            "For each subject in {subjects}, identify the top 5-7 topics "
            "ranked by exam weight (% of paper marks).\n\n"
            "PRE-FETCHED PER-SUBJECT CONTEXT (do NOT call any tools — "
            "reason from this data):\n"
            "----- BEGIN SUBJECTS CONTEXT -----\n"
            f"{subjects_context}\n"
            "----- END SUBJECTS CONTEXT -----\n\n"
            "Output: Markdown sections — one per subject — each listing "
            "5-7 topics with weight % and a 1-line justification. "
            "Where the context cites a source (filename + page), include "
            "it inline."
        ),
        expected_output=(
            "Markdown sections — one per subject — each listing 5-7 topics "
            "with weight % and source citations where available."
        ),
        agent=agents["topic_importance_analyzer"],
    )

    read_mastery = Task(
        description=(
            "The student's current per-topic mastery scores are pre-fetched "
            "below. Combine these with the user-supplied weak topics to "
            "produce a ranked list of the student's WEAKEST topics across "
            "all requested subjects.\n\n"
            "MASTERY SNAPSHOT (pre-fetched, do not call any tools):\n"
            "----- BEGIN MASTERY -----\n"
            f"{mastery_snapshot}\n"
            "----- END MASTERY -----\n\n"
            "User-supplied weak topics: {weak_topics}\n\n"
            "Output: a single ranked list of weak topics across subjects, "
            "lowest-mastery first. For each, note the subject and the "
            "current mastery score (or 'no data, defaulted to 0.5')."
        ),
        expected_output=(
            "A ranked Markdown list of weak topics with subject + mastery score."
        ),
        agent=agents["mastery_reader"],
    )

    estimate_effort = Task(
        description=(
            "Estimate study time required per top-priority topic.\n\n"
            "PER-SUBJECT NOTES DENSITY (pre-fetched, do not call any tools):\n"
            "----- BEGIN EFFORT SNAPSHOT -----\n"
            f"{effort_snapshot}\n"
            "----- END EFFORT SNAPSHOT -----\n\n"
            "For each top topic identified by the previous tasks, estimate "
            "minutes-to-mastery based on:\n"
            "- Subject's overall Notes density (more chunks = more material)\n"
            "- Topic's likely share of that material\n"
            "- Topic's complexity (math derivations = longer; "
            "  definitions = shorter)\n\n"
            "A subject with 200+ chunks needs noticeably more total time "
            "than one with 30 chunks. Be honest. A 30-page topic does not "
            "get studied in 45 minutes.\n\n"
            "**IMPORTANT — no internal jargon in your output**: never "
            "mention 'chunks', 'mastery score 0.5', or any internal-looking "
            "numbers. Translate to natural language: 'extensive notes "
            "coverage', 'moderate coverage', 'limited material', "
            "'no prior practice data', etc."
        ),
        expected_output=(
            "Markdown table or list — per topic — with estimated minutes "
            "and a one-line natural-language basis (no internal jargon)."
        ),
        agent=agents["effort_estimator"],
        context=[rank_topic_importance, read_mastery],
    )

    plan_schedule = Task(
        description=(
            "Build the final study plan.\n\n"
            "**DATE ANCHORS (these are absolute — do not invent dates):**\n"
            "- Today is **{today_iso}** — the FIRST day of the plan.\n"
            "- Exam is on **{exam_date_iso}** — the LAST day of the plan.\n"
            "- Total days available: **{days_until_exam}** (inclusive).\n"
            "- Every `date` field in your output MUST be an ISO date "
            "  starting from {today_iso}, incrementing by one day per "
            "  StudyDay, ending on {exam_date_iso}. The year is part of "
            "  the date — do NOT use a different year.\n\n"
            "Constraints:\n"
            "- Daily budget: {daily_study_minutes} minutes (HARD limit).\n"
            "- Each day has 2-4 study tasks (45-90 min each is ideal).\n"
            "- Priority = topic importance × topic weakness. High-importance "
            "  + weak topics get the most time AND earlier days.\n"
            "- Avoid scheduling the same subject for >2 consecutive days.\n"
            "- Reserve the LAST 2 days for revision-heavy tasks across all "
            "  subjects (no new topics).\n\n"
            "**Rationale field — student-facing language only**: write "
            "natural sentences a student understands. Examples of good "
            "rationale:\n"
            "  - 'Frequently tested topic; start strong.'\n"
            "  - 'You haven't practised this yet — build a foundation.'\n"
            "  - 'Quick revision before the exam.'\n"
            "  - 'High-mark area worth extra time.'\n"
            "Examples of BAD rationale (do NOT use):\n"
            "  - 'High weight (estimated 222/260 chunks)…' ← internal jargon\n"
            "  - 'mastery defaulted to 0.5'                ← exposes internals\n"
            "  - any numeric chunk counts or score values\n\n"
            "Final output is a JSON object matching this Pydantic schema:\n"
            "```\n"
            "{\n"
            "  \"plan_id\": str (use the run_id passed in),\n"
            "  \"exam_date\": ISO datetime (use {exam_date_iso}T00:00:00),\n"
            "  \"subjects\": [...],\n"
            "  \"days\": [\n"
            "    {\"date\": ISO datetime, \"tasks\": [\n"
            "      {\"subject\": str, \"topic\": str, "
            "\"duration_minutes\": int (10-240), \"rationale\": str, "
            "\"completed\": false}, ...\n"
            "    ]}, ...\n"
            "  ],\n"
            "  \"overall_strategy\": \"1-3 sentence summary in plain English, "
            "  no internal jargon\"\n"
            "}\n"
            "```\n"
            "Use plan_id = '{run_id}'.\n"
            "Return ONLY the JSON. No commentary."
        ),
        expected_output=(
            "A single JSON object matching StudyPlanOutput schema. No "
            "code fences, no explanation."
        ),
        agent=agents["schedule_planner"],
        context=[rank_topic_importance, read_mastery, estimate_effort],
        output_pydantic=StudyPlanOutput,
    )

    return [rank_topic_importance, read_mastery, estimate_effort, plan_schedule]
