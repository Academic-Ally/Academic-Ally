"""Progress tracker — Firestore when available, in-memory fallback.

Firestore is the canonical store: the Flutter app subscribes to
``AnalysisRuns/{runId}`` for the live agent-checkmark UI, so the
backend MUST write there for the progress widget to update.

The in-memory dict is a fallback for environments where Firebase Admin
isn't initialized.
"""
import logging
import threading
from datetime import datetime, timezone
from typing import Any, Dict, List

import firebase_admin
from firebase_admin import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP


logger = logging.getLogger(__name__)

_lock = threading.Lock()
_memory_runs: Dict[str, Dict[str, Any]] = {}


def _firestore_available() -> bool:
    return bool(firebase_admin._apps)


def _tracker_path(run_id: str) -> str:
    return f"AnalysisRuns/{run_id}"


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def init_tracker(*, run_id: str, subject: str, agent_names: List[str]) -> None:
    """Create the initial tracker entry with all agents marked 'pending'."""
    agents = {name: "pending" for name in agent_names}

    if _firestore_available():
        try:
            client = firestore.client()
            client.document(_tracker_path(run_id)).set(
                {
                    "runId": run_id,
                    "subject": subject,
                    "status": "running",
                    "agents": agents,
                    "createdAt": SERVER_TIMESTAMP,
                }
            )
            logger.info("[run %s] init (firestore) subject=%s agents=%s", run_id, subject, agent_names)
            return
        except Exception as exc:
            logger.warning("[run %s] firestore init failed: %s — using memory", run_id, exc)

    with _lock:
        _memory_runs[run_id] = {
            "runId": run_id,
            "subject": subject,
            "status": "running",
            "agents": agents,
            "createdAt": _now_iso(),
        }
    logger.info("[run %s] init (memory) subject=%s agents=%s", run_id, subject, agent_names)


def update_agent_status(run_id: str, agent_name: str, status: str) -> None:
    """Update a single agent's status."""
    if _firestore_available():
        try:
            client = firestore.client()
            client.document(_tracker_path(run_id)).update(
                {f"agents.{agent_name}": status}
            )
            logger.info("[run %s] agent %s -> %s (firestore)", run_id, agent_name, status)
            return
        except Exception as exc:
            logger.warning("[run %s] firestore update failed: %s — using memory", run_id, exc)

    with _lock:
        run = _memory_runs.get(run_id)
        if run is None:
            logger.warning("[run %s] update_agent_status: unknown run", run_id)
            return
        run["agents"][agent_name] = status
    logger.info("[run %s] agent %s -> %s (memory)", run_id, agent_name, status)


def mark_complete(run_id: str) -> None:
    """Mark the whole run complete."""
    if _firestore_available():
        try:
            client = firestore.client()
            client.document(_tracker_path(run_id)).update(
                {"status": "complete", "completedAt": SERVER_TIMESTAMP}
            )
            logger.info("[run %s] complete (firestore)", run_id)
            return
        except Exception as exc:
            logger.warning("[run %s] firestore complete failed: %s — using memory", run_id, exc)

    with _lock:
        run = _memory_runs.get(run_id)
        if run is None:
            logger.warning("[run %s] mark_complete: unknown run", run_id)
            return
        run["status"] = "complete"
        run["completedAt"] = _now_iso()
    logger.info("[run %s] complete (memory)", run_id)


def mark_failed(run_id: str, failing_agent: str, error_message: str) -> None:
    """Mark the run failed, attributing the failure to an agent."""
    if _firestore_available():
        try:
            client = firestore.client()
            client.document(_tracker_path(run_id)).update(
                {
                    "status": "failed",
                    "errorMessage": error_message,
                    f"agents.{failing_agent}": "failed",
                    "completedAt": SERVER_TIMESTAMP,
                }
            )
            logger.error("[run %s] FAILED at %s (firestore): %s", run_id, failing_agent, error_message)
            return
        except Exception as exc:
            logger.warning("[run %s] firestore mark_failed failed: %s — using memory", run_id, exc)

    with _lock:
        run = _memory_runs.get(run_id)
        if run is None:
            logger.warning("[run %s] mark_failed: unknown run", run_id)
            return
        run["status"] = "failed"
        run["errorMessage"] = error_message
        run["agents"][failing_agent] = "failed"
        run["completedAt"] = _now_iso()
    logger.error("[run %s] FAILED at %s (memory): %s", run_id, failing_agent, error_message)


def make_crewai_step_callback(run_id: str, agent_name_map: dict):
    """Factory for a CrewAI-compatible ``step_callback``.

    CrewAI fires this after each agent step. We inspect the step's agent
    role and update the tracker. ``agent_name_map`` maps CrewAI role
    strings (e.g., "Syllabus Researcher") to tracker agent names
    (e.g., "syllabus").
    """
    _seen_done: set[str] = set()

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
