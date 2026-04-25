"""Firestore Vector Search wrapper for RAG chunks.

Layout:
- ``RagChunks/{subjectKey}/chunks/{auto-id}`` — one chunk per doc, with a
  ``Vector`` ``embedding`` field for similarity search.
- ``RagIndex/{subjectKey}`` — index status doc tracking which source
  resources have been ingested (so re-runs are idempotent).

Subject keys are flat strings derived from
``{uni}_{course}_{branch}_{sem}_{subject}`` with spaces collapsed to
underscores so they're safe as Firestore document IDs.
"""
import logging
import re
from typing import Any, Dict, List, Optional

from firebase_admin import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP
from google.cloud.firestore_v1.base_vector_query import DistanceMeasure
from google.cloud.firestore_v1.vector import Vector


logger = logging.getLogger(__name__)


def make_subject_key(
    *, university: str, course: str, branch: str, sem: str, subject: str
) -> str:
    """Build a Firestore-safe key for a subject's RAG collection."""
    parts = [university, course, branch, str(sem), subject]
    raw = "_".join(parts)
    # Replace anything not alphanumeric / underscore / dash with underscore
    return re.sub(r"[^A-Za-z0-9_-]+", "_", raw).strip("_")


def _chunks_collection(subject_key: str):
    return firestore.client().collection(f"RagChunks/{subject_key}/chunks")


def _index_doc(subject_key: str):
    return firestore.client().document(f"RagIndex/{subject_key}")


def get_index_status(subject_key: str) -> Optional[Dict[str, Any]]:
    """Return the index doc for a subject, or None if never ingested."""
    snap = _index_doc(subject_key).get()
    return snap.to_dict() if snap.exists else None


def is_ingested(subject_key: str) -> bool:
    """True if at least one resource has been ingested for this subject."""
    status = get_index_status(subject_key)
    return bool(status and status.get("totalChunks", 0) > 0)


def already_ingested_resource_ids(subject_key: str) -> set[str]:
    """Set of resource IDs already chunked + embedded into this subject's index."""
    status = get_index_status(subject_key)
    if not status:
        return set()
    return set(status.get("ingestedResourceIds", []))


def upsert_chunks(
    *,
    subject_key: str,
    chunks: List[Dict[str, Any]],
) -> None:
    """Write a batch of chunk docs.

    Each ``chunks`` item must contain at least ``text``, ``embedding``,
    plus the metadata fields (resourceId, storageId, filename, etc.).
    """
    if not chunks:
        return
    coll = _chunks_collection(subject_key)
    batch = firestore.client().batch()
    for chunk in chunks:
        # Convert raw embedding list to a Vector field for find_nearest.
        embedding = chunk.pop("embedding")
        doc_ref = coll.document()
        batch.set(
            doc_ref,
            {
                **chunk,
                "embedding": Vector(embedding),
                "createdAt": SERVER_TIMESTAMP,
            },
        )
    batch.commit()


def mark_resource_ingested(
    *,
    subject_key: str,
    subject: str,
    resource_id: str,
    chunks_added: int,
) -> None:
    """Update the index doc after a single resource is fully ingested."""
    doc = _index_doc(subject_key)
    doc.set(
        {
            "subjectKey": subject_key,
            "subject": subject,
            "ingestedResourceIds": firestore.ArrayUnion([resource_id]),
            "totalChunks": firestore.Increment(chunks_added),
            "lastIngestedAt": SERVER_TIMESTAMP,
        },
        merge=True,
    )


def search(
    *,
    subject_key: str,
    query_embedding: List[float],
    top_k: int = 5,
    resource_id_filter: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """k-NN search inside one subject's chunk collection.

    Args:
        subject_key: Output of ``make_subject_key(...)``.
        query_embedding: 768-dim vector to search against.
        top_k: Max results to return.
        resource_id_filter: If provided, restrict the search to chunks of
            a single source PDF (e.g. for AllyBot chat scoped to one
            document).

    Requires a vector index on the ``chunks`` collection group:
        gcloud firestore indexes composite create \\
          --collection-group=chunks --query-scope=COLLECTION \\
          --field-config=field-path=embedding,\\
            vector-config='{"dimension":"768","flat":"{}"}'

    Returns dicts ready to surface to agents/UI: text, page span,
    filename, category, score-equivalent (distance).
    """
    coll = _chunks_collection(subject_key)
    if resource_id_filter:
        coll = coll.where("resourceId", "==", resource_id_filter)
    vector_query = coll.find_nearest(
        vector_field="embedding",
        query_vector=Vector(query_embedding),
        distance_measure=DistanceMeasure.COSINE,
        limit=top_k,
        distance_result_field="vector_distance",
    )
    docs = vector_query.get()
    results: List[Dict[str, Any]] = []
    for snap in docs:
        data = snap.to_dict() or {}
        # Don't surface the raw embedding to callers; keep payload light.
        data.pop("embedding", None)
        data["id"] = snap.id
        results.append(data)
    return results
