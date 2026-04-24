"""Progress tracker for the AnalysisRuns Firestore collection.

Each run gets a doc at ``AnalysisRuns/{runId}`` that tracks per-agent
status. Flutter subscribes to this doc in real time to render the
progressive loading UI.

Trackers are transient — a separate scheduled function (cleanup.py)
deletes docs older than 1 hour.
"""
from typing import List

from firebase_admin import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP


def _tracker_path(run_id: str) -> str:
    return f"AnalysisRuns/{run_id}"


def init_tracker(*, run_id: str, subject: str, agent_names: List[str]) -> None:
    """Create the initial tracker doc with all agents as 'pending'."""
    client = firestore.client()
    agents = {name: "pending" for name in agent_names}
    client.document(_tracker_path(run_id)).set(
        {
            "runId": run_id,
            "subject": subject,
            "status": "running",
            "agents": agents,
            "createdAt": SERVER_TIMESTAMP,
        }
    )


def update_agent_status(run_id: str, agent_name: str, status: str) -> None:
    """Update a single agent's status in the tracker.

    Uses dotted-path update so we only write one field, not the whole map.
    """
    client = firestore.client()
    client.document(_tracker_path(run_id)).update(
        {f"agents.{agent_name}": status}
    )


def mark_complete(run_id: str) -> None:
    """Mark the whole run complete."""
    client = firestore.client()
    client.document(_tracker_path(run_id)).update(
        {"status": "complete", "completedAt": SERVER_TIMESTAMP}
    )


def mark_failed(run_id: str, failing_agent: str, error_message: str) -> None:
    """Mark the run as failed, attributing the failure to an agent."""
    client = firestore.client()
    client.document(_tracker_path(run_id)).update(
        {
            "status": "failed",
            "errorMessage": error_message,
            f"agents.{failing_agent}": "failed",
            "completedAt": SERVER_TIMESTAMP,
        }
    )


def make_crewai_step_callback(run_id: str, agent_name_map: dict):
    """Factory for a CrewAI-compatible ``step_callback``.

    CrewAI fires ``step_callback`` after each agent step. We inspect the
    step's agent role and update the tracker. ``agent_name_map`` maps
    CrewAI role strings (e.g., "Syllabus Researcher") to tracker agent
    names (e.g., "syllabus").
    """
    _seen_done = set()

    def _callback(step_output) -> None:
        role = getattr(step_output, "agent_role", None) or getattr(step_output, "role", None)
        if not role:
            return
        tracker_name = agent_name_map.get(role)
        if not tracker_name or tracker_name in _seen_done:
            return
        update_agent_status(run_id, tracker_name, "done")
        _seen_done.add(tracker_name)

    return _callback
