"""CrewAI agent definitions for Study Planner.

Four specialist agents. The manager is auto-provisioned by
``Process.hierarchical``. Agents are intentionally TOOLLESS — RAG
context is pre-fetched server-side per subject and injected into
their task prompts. This avoids CrewAI's "duplicate tool name" issue
that arises when binding the same search tool to N subjects, and
removes per-step tool latency.
"""
from crewai import Agent

from app.shared.llm import get_llm


AGENT_ROLE_TO_TRACKER = {
    "Topic Importance Analyzer": "importance",
    "Mastery Reader": "mastery",
    "Effort Estimator": "effort",
    "Schedule Planner": "scheduler",
}

TRACKER_AGENT_NAMES = list(AGENT_ROLE_TO_TRACKER.values())


def build_study_planner_agents():
    """Return the 4 specialist agents."""
    llm = get_llm(temperature=0.3)

    topic_importance_analyzer = Agent(
        role="Topic Importance Analyzer",
        goal=(
            "For each subject in the plan, identify which topics deserve "
            "the most study time, ranked by their weight in past exam papers."
        ),
        backstory=(
            "You are a JNTUH/OU exam strategist. The relevant per-subject "
            "topic weights and indexed-paper highlights are pre-fetched "
            "for you and injected into your task. Do NOT call any tools — "
            "reason from the injected data. You think in terms of marks "
            "per topic, not topics in isolation."
        ),
        llm=llm,
        tools=[],
        allow_delegation=False,
        verbose=True,
    )

    mastery_reader = Agent(
        role="Mastery Reader",
        goal=(
            "Identify the student's weakest topics across the requested "
            "subjects, using their MasteryScores plus any user-supplied "
            "weak-topic hints."
        ),
        backstory=(
            "You read the student's per-topic mastery profile (pre-fetched "
            "and injected into your task). For new users with empty "
            "MasteryScores, you default everyone to 0.5 and lean on the "
            "user-supplied weakTopics list. You never fabricate mastery — "
            "if data is missing, you say so."
        ),
        llm=llm,
        tools=[],
        allow_delegation=False,
        verbose=True,
    )

    effort_estimator = Agent(
        role="Effort Estimator",
        goal=(
            "Estimate the realistic study time required per topic, based "
            "on the topic's depth in the indexed notes."
        ),
        backstory=(
            "You read the per-subject Notes density numbers (chunk counts "
            "per subject) pre-injected into your task. A subject with "
            "200+ chunks needs substantially more time than one with 30 "
            "chunks. Calibrate honestly — students lose trust if the plan "
            "is unrealistic. Do not call any tools."
        ),
        llm=llm,
        tools=[],
        allow_delegation=False,
        verbose=True,
    )

    schedule_planner = Agent(
        role="Schedule Planner",
        goal=(
            "Allocate the student's available daily minutes across topics "
            "and days, prioritizing topics where weight × (1 - mastery) is "
            "highest. Output a per-day plan with rationale."
        ),
        backstory=(
            "You are a study coach who treats time as scarce capital. You "
            "respect prerequisites (basics before advanced), avoid stacking "
            "the same subject all day, and write rationale strings the "
            "student can act on like 'Topic X is high-weight (28%) and your "
            "mastery is only 0.3 — top priority this week'. You never "
            "exceed the user's daily minute budget. You produce one plan "
            "spanning today through the exam date."
        ),
        llm=llm,
        tools=[],
        allow_delegation=False,
        verbose=True,
    )

    return {
        "topic_importance_analyzer": topic_importance_analyzer,
        "mastery_reader": mastery_reader,
        "effort_estimator": effort_estimator,
        "schedule_planner": schedule_planner,
    }
