"""Reusable CrewAI Crew factory.

All 6 AI features construct their crews through this factory so the
hierarchical-process + step-callback + max-iter wiring is consistent
and maintainable.
"""
from typing import List

from crewai import Agent, Crew, Process, Task

from .llm import get_llm


def build_hierarchical_crew(
    *,
    agents: List[Agent],
    tasks: List[Task],
    step_callback=None,
    max_iter: int = 8,
    max_rpm: int = 8,
    verbose: bool = True,
) -> Crew:
    """Build a CrewAI Crew with hierarchical process and sensible defaults.

    Args:
        agents: Worker agents (the manager is auto-injected by CrewAI).
        tasks: Ordered task list.
        step_callback: Optional callback fired after each agent step.
        max_iter: Max delegation iterations the manager can perform.
        max_rpm: Max LLM calls per minute across the whole crew.
        verbose: Log agent thinking for debugging.
    """
    manager_llm = get_llm(temperature=0.1)
    return Crew(
        agents=agents,
        tasks=tasks,
        process=Process.hierarchical,
        manager_llm=manager_llm,
        max_rpm=max_rpm,
        verbose=verbose,
        step_callback=step_callback,
        memory=True,
    )
