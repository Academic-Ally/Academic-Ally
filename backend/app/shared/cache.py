"""Cache for AI results — Firestore when available, in-memory fallback.

Firestore is the canonical store: the Flutter app subscribes to
``PyqAnalysis/{path}`` and renders the result from there, so the
backend MUST write there for the UI to update.

The in-memory dict is a fallback for environments where Firebase Admin
isn't initialized (e.g., curl-only smoke tests without service-account
credentials).
"""
import logging
import threading
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional

import firebase_admin
from firebase_admin import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP


logger = logging.getLogger(__name__)

_lock = threading.Lock()
_memory_store: Dict[str, Dict[str, Any]] = {}


def _firestore_available() -> bool:
    return bool(firebase_admin._apps)


def is_fresh(ts: Optional[datetime], hours: int) -> bool:
    """Return True if ``ts`` is within the last ``hours`` hours."""
    if ts is None:
        return False
    if ts.tzinfo is None:
        ts = ts.replace(tzinfo=timezone.utc)
    cutoff = datetime.now(timezone.utc) - timedelta(hours=hours)
    return ts >= cutoff


def read_cache(doc_path: str, freshness_hours: int = 24) -> Optional[Dict[str, Any]]:
    """Read a cached AI result if present and fresh."""
    if _firestore_available():
        try:
            client = firestore.client()
            snap = client.document(doc_path).get()
            if not snap.exists:
                return None
            data = snap.to_dict()
            if not is_fresh(data.get("lastAnalyzed"), freshness_hours):
                return None
            logger.info("cache hit (firestore): %s", doc_path)
            return data
        except Exception as exc:
            logger.warning("firestore read failed for %s: %s", doc_path, exc)

    with _lock:
        entry = _memory_store.get(doc_path)
        if entry is None:
            return None
        if not is_fresh(entry.get("lastAnalyzed"), freshness_hours):
            _memory_store.pop(doc_path, None)
            return None
        logger.info("cache hit (memory): %s", doc_path)
        return dict(entry)


def write_cache(doc_path: str, data: Dict[str, Any]) -> None:
    """Persist an AI result. Writes to both Firestore (if available) and memory."""
    if _firestore_available():
        try:
            client = firestore.client()
            payload = {**data, "lastAnalyzed": SERVER_TIMESTAMP}
            client.document(doc_path).set(payload)
            logger.info("cache wrote (firestore): %s", doc_path)
            return
        except Exception as exc:
            logger.warning("firestore write failed for %s: %s — falling back to memory", doc_path, exc)

    payload = {**data, "lastAnalyzed": datetime.now(timezone.utc)}
    with _lock:
        _memory_store[doc_path] = payload
    logger.info("cache wrote (memory): %s", doc_path)
