"""Scheduled function that deletes stale AnalysisRuns tracker docs.

Trackers are transient — they only exist during a workflow run to
drive the progress UI. After the run completes, they're not needed.
We delete docs older than 1 hour to keep the collection small.
"""
import logging
from datetime import datetime, timedelta, timezone

from firebase_admin import firestore
from firebase_functions import scheduler_fn


logger = logging.getLogger(__name__)


@scheduler_fn.on_schedule(schedule="every 1 hours", region="us-central1")
def cleanup_old_trackers(event: scheduler_fn.ScheduledEvent) -> None:
    """Delete AnalysisRuns docs older than 1 hour."""
    client = firestore.client()
    cutoff = datetime.now(timezone.utc) - timedelta(hours=1)
    stale = (
        client.collection("AnalysisRuns")
        .where("createdAt", "<", cutoff)
        .limit(500)
        .stream()
    )
    deleted = 0
    for snap in stale:
        snap.reference.delete()
        deleted += 1
    logger.info("cleanup_old_trackers deleted %d stale tracker docs", deleted)
