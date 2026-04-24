"""Firestore cache helpers for AI results.

All AI features write their final output to a canonical Firestore path
(e.g., PyqAnalysis/{uni}/{course}/{branch}/{sem}/{subject}). Subsequent
requests within the freshness window return the cached value without
running the workflow.
"""
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional

from firebase_admin import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP


def is_fresh(ts: Optional[datetime], hours: int) -> bool:
    """Return True if ``ts`` is within the last ``hours`` hours.

    Handles None (treats as stale) and naive datetimes (assumes UTC).
    """
    if ts is None:
        return False
    if ts.tzinfo is None:
        ts = ts.replace(tzinfo=timezone.utc)
    cutoff = datetime.now(timezone.utc) - timedelta(hours=hours)
    return ts >= cutoff


def read_cache(doc_path: str, freshness_hours: int = 24) -> Optional[Dict[str, Any]]:
    """Read a cached AI result if present and fresh.

    Returns the document data as a dict, or None if missing/stale.
    """
    client = firestore.client()
    snap = client.document(doc_path).get()
    if not snap.exists:
        return None
    data = snap.to_dict()
    if not is_fresh(data.get("lastAnalyzed"), freshness_hours):
        return None
    return data


def write_cache(doc_path: str, data: Dict[str, Any]) -> None:
    """Persist an AI result to the cache.

    Adds/overwrites ``lastAnalyzed`` with the server timestamp so
    downstream freshness checks work correctly.
    """
    client = firestore.client()
    payload = {**data, "lastAnalyzed": SERVER_TIMESTAMP}
    client.document(doc_path).set(payload)
