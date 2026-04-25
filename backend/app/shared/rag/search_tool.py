"""CrewAI BaseTool wrapping subject-scoped RAG search.

Every agent that needs grounded retrieval gets this tool. The tool is
constructed per-request with the subject context baked in, so agents
just call ``search_subject_documents(query=..., top_k=...)`` without
having to know which subject they're working on.

Tool description language is intentionally directive ("ALWAYS use this
first") to nudge the agent toward retrieval-first behavior.

Provides BOTH ``_run`` (sync) and ``_arun`` (async) so CrewAI can pick
the right path depending on whether the crew was kicked off via
``kickoff`` or ``akickoff``. The sync path bridges to async via a
worker thread (``asyncio.run`` cannot be called from within a running
event loop, which is exactly where CrewAI invokes tools during
``akickoff``).
"""
import asyncio
import concurrent.futures
import logging
from typing import List

from crewai.tools import BaseTool
from pydantic import BaseModel, Field, PrivateAttr

from .embedder import embed_one
from .vector_store import is_ingested, search


logger = logging.getLogger(__name__)


class SubjectSearchInput(BaseModel):
    query: str = Field(..., description="Natural-language search query")
    top_k: int = Field(5, description="Max results to return (1-10)")


class SubjectDocumentsSearchTool(BaseTool):
    """Search the subject's RAG-indexed notes + papers + syllabus."""

    name: str = "search_subject_documents"
    description: str = (
        "Search the subject's actual notes, past papers, syllabus, and "
        "question banks for grounded course content. ALWAYS use this FIRST "
        "for any factual claim about the subject — topic definitions, "
        "formulas, past question phrasings, examiner conventions, or "
        "anything that should be cited from official material. Returns "
        "the top matching chunks with filename + page numbers so you can "
        "cite specific sources. Only skip this tool for general advice or "
        "questions about your own role."
    )
    args_schema: type[BaseModel] = SubjectSearchInput

    _subject_key: str = PrivateAttr()

    def __init__(self, subject_key: str, **data):
        super().__init__(**data)
        self._subject_key = subject_key

    async def _arun(self, query: str, top_k: int = 5) -> str:
        """Native async entry point — used when CrewAI is in akickoff mode."""
        return await self._do_search_async(query, top_k)

    def _run(self, query: str, top_k: int = 5) -> str:
        """Sync entry point. Bridges to ``_do_search_async`` even when a
        loop is already running in the calling thread (CrewAI's case)."""
        return _run_async(self._do_search_async(query, top_k))

    async def _do_search_async(self, query: str, top_k: int) -> str:
        if not is_ingested(self._subject_key):
            return (
                "ERROR: this subject has not been indexed yet. "
                "Tell the user the subject's documents are not ready for "
                "search and proceed with general knowledge only."
            )

        try:
            embedding = await embed_one(query)
        except Exception as exc:
            logger.error("query embedding failed: %s", exc)
            return f"ERROR: search unavailable — embedding failed: {exc}"

        try:
            results = search(
                subject_key=self._subject_key,
                query_embedding=embedding,
                top_k=max(1, min(top_k, 10)),
            )
        except Exception as exc:
            logger.error("vector search failed: %s", exc)
            return f"ERROR: search unavailable — vector search failed: {exc}"

        if not results:
            return f"No matching documents for query: {query}"

        return _format_results(results, query)


def _format_results(results: List[dict], query: str) -> str:
    """Format chunks as a readable block for the agent.

    Each block includes ``resourceId`` — the stable Firestore ID of the
    source PDF — so callers that need to cite back to the original
    document can do so unambiguously (filenames have spaces, casing
    drift, and weird characters; IDs don't).
    """
    blocks: List[str] = [f"Search results for: {query}", ""]
    for i, r in enumerate(results, start=1):
        filename = r.get("filename", "(untitled)")
        category = r.get("category", "?")
        page_start = r.get("pageStart", "?")
        page_end = r.get("pageEnd", page_start)
        resource_id = r.get("resourceId", "?")
        page_label = (
            f"page {page_start}"
            if page_start == page_end
            else f"pages {page_start}-{page_end}"
        )
        text = (r.get("text") or "")[:1500]
        blocks.append(
            f"[{i}] FROM {filename} (resourceId={resource_id}, "
            f"{category}, {page_label}):\n{text}\n"
        )
    blocks.append(
        "\nUse this material to answer in your own words. When you cite "
        "a source, use the resourceId (NOT the filename) as the source "
        "identifier — IDs are stable, filenames are not."
    )
    return "\n".join(blocks)


def _run_async(coro):
    """Run an async coroutine from sync code, regardless of loop state.

    If we're already inside a running event loop (CrewAI's akickoff path),
    asyncio.run cannot be invoked directly — it would error with
    "asyncio.run() cannot be called from a running event loop". So we
    bounce the coroutine onto a worker thread that gets its own fresh
    event loop, and synchronously wait for the result.
    """
    try:
        asyncio.get_running_loop()
    except RuntimeError:
        # No loop running here — fast path
        return asyncio.run(coro)
    # Loop already running. Submit to a thread with its own asyncio.run.
    with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
        return executor.submit(asyncio.run, coro).result()


def get_subject_search_tool(subject_key: str) -> SubjectDocumentsSearchTool:
    """Factory: bind the search tool to a specific subject's RAG index."""
    return SubjectDocumentsSearchTool(subject_key=subject_key)
