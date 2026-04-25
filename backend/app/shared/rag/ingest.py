"""High-level RAG ingestion orchestrator.

Given a subject ``(university, course, branch, sem, subject)``, this:
1. Looks up resource docs in Firestore (Universities/.../{type}/{subject})
2. Filters out resources already ingested into the vector index
3. Downloads each PDF from Firebase Storage via firebase-admin
4. Chunks each PDF (page-tracked sliding window)
5. Embeds chunks in batches via Gemini text-embedding-004
6. Upserts to Firestore Vector Search
7. Updates the index status doc

Designed to be safe to call repeatedly — only new resources get
ingested. Uses Firebase Admin's storage client (no extra auth needed
beyond GOOGLE_APPLICATION_CREDENTIALS).
"""
import asyncio
import logging
from dataclasses import dataclass
from typing import List

from firebase_admin import firestore, storage

from .embedder import embed_batch
from .pdf_chunker import extract_and_chunk
from .vector_store import (
    already_ingested_resource_ids,
    make_subject_key,
    mark_resource_ingested,
    upsert_chunks,
)


logger = logging.getLogger(__name__)


# Categories we ingest. Lab subjects often have only Syllabus, but we
# index everything we find — agents can filter by category at query time.
INDEXABLE_CATEGORIES = ("Notes", "QuestionPapers", "Syllabus", "OtherResources")


@dataclass
class IngestResult:
    subject_key: str
    resources_seen: int
    resources_skipped: int  # already ingested
    resources_ingested: int
    chunks_added: int
    failures: List[str]


def _resource_collection_path(
    *, university: str, course: str, branch: str, sem: str, category: str, subject: str
) -> str:
    return f"Universities/{university}/{course}/{branch}/{sem}/{category}/{subject}"


def _list_resources_for_subject(
    *, university: str, course: str, branch: str, sem: str, subject: str
) -> List[dict]:
    """Pull all resource metadata docs across all categories for a subject."""
    client = firestore.client()
    out: List[dict] = []
    for category in INDEXABLE_CATEGORIES:
        path = _resource_collection_path(
            university=university,
            course=course,
            branch=branch,
            sem=sem,
            category=category,
            subject=subject,
        )
        snaps = client.collection(path).stream()
        for snap in snaps:
            data = snap.to_dict() or {}
            storage_id = data.get("storageId")
            if not storage_id:
                logger.warning("resource %s/%s missing storageId; skipping", path, snap.id)
                continue
            out.append(
                {
                    "resource_id": snap.id,
                    "category": category,
                    "storage_id": storage_id,
                    "name": data.get("name") or "untitled",
                }
            )
    return out


def _download_pdf(storage_id: str) -> bytes:
    """Download a PDF from Firebase Storage by its full path."""
    bucket = storage.bucket()
    blob = bucket.blob(storage_id)
    return blob.download_as_bytes()


async def _ingest_one_resource(
    *, subject_key: str, subject: str, resource: dict
) -> tuple[int, str | None]:
    """Ingest a single PDF resource.

    Returns ``(chunks_added, error_message_or_none)``.
    """
    try:
        pdf_bytes = _download_pdf(resource["storage_id"])
    except Exception as exc:
        return 0, f"download {resource['storage_id']}: {exc}"

    try:
        chunks = extract_and_chunk(pdf_bytes)
    except Exception as exc:
        return 0, f"chunk {resource['storage_id']}: {exc}"

    if not chunks:
        logger.warning("no chunks extracted from %s", resource["storage_id"])
        return 0, None

    try:
        embeddings = await embed_batch([c.text for c in chunks])
    except Exception as exc:
        return 0, f"embed {resource['storage_id']}: {exc}"

    docs = [
        {
            "subjectKey": subject_key,
            "subject": subject,
            "category": resource["category"],
            "resourceId": resource["resource_id"],
            "storageId": resource["storage_id"],
            "filename": resource["name"],
            "pageStart": chunk.page_start,
            "pageEnd": chunk.page_end,
            "chunkIndex": chunk.chunk_index,
            "text": chunk.text,
            "embedding": embedding,
        }
        for chunk, embedding in zip(chunks, embeddings)
    ]
    # Firestore batches max 500 ops; chunk into safe slices.
    for i in range(0, len(docs), 400):
        upsert_chunks(subject_key=subject_key, chunks=docs[i : i + 400])

    mark_resource_ingested(
        subject_key=subject_key,
        subject=subject,
        resource_id=resource["resource_id"],
        chunks_added=len(docs),
    )
    return len(docs), None


async def ingest_subject(
    *, university: str, course: str, branch: str, sem: str, subject: str
) -> IngestResult:
    """Ingest all not-yet-indexed PDFs for a subject. Idempotent."""
    subject_key = make_subject_key(
        university=university,
        course=course,
        branch=branch,
        sem=sem,
        subject=subject,
    )
    logger.info("ingest_subject start key=%s", subject_key)

    resources = _list_resources_for_subject(
        university=university,
        course=course,
        branch=branch,
        sem=sem,
        subject=subject,
    )
    already = already_ingested_resource_ids(subject_key)
    pending = [r for r in resources if r["resource_id"] not in already]

    failures: List[str] = []
    chunks_added_total = 0
    ingested_count = 0

    for resource in pending:
        added, err = await _ingest_one_resource(
            subject_key=subject_key, subject=subject, resource=resource
        )
        if err:
            failures.append(err)
            logger.error("ingest failure: %s", err)
            continue
        chunks_added_total += added
        ingested_count += 1
        logger.info(
            "ingested resource=%s chunks=%d (%s)",
            resource["resource_id"],
            added,
            resource["name"],
        )
        # Tiny pause between resources to be polite to Gemini RPM
        await asyncio.sleep(0.5)

    return IngestResult(
        subject_key=subject_key,
        resources_seen=len(resources),
        resources_skipped=len(resources) - len(pending),
        resources_ingested=ingested_count,
        chunks_added=chunks_added_total,
        failures=failures,
    )
