"""Chat-about-PDF: single-LLM-call handler with RAG context.

Unlike the multi-agent features (PYQ / Examiner / Snap-a-Doubt), chat
needs sub-5s latency for every turn — agentic crews are too slow. So
this handler is a direct flow:

    1. Embed the user's question
    2. RAG search filtered to this PDF's chunks (resource_id filter)
    3. Build a system prompt with retrieved context
    4. Single litellm.acompletion call with chat history
    5. Return reply + citations
"""
import logging
import os
from typing import List

import litellm

from app.shared.llm import get_llm  # noqa: F401  (kept for parity)
from app.shared.rag.embedder import embed_one
from app.shared.rag.ingest import ingest_subject
from app.shared.rag.vector_store import is_ingested, make_subject_key, search

from .schema import ChatCitation, ChatRequest, ChatResponse


logger = logging.getLogger(__name__)


SYSTEM_PROMPT_TEMPLATE = """\
You are AllyBot, a focused study assistant for engineering students at
JNTUH/OU. You answer the student's questions about ONE specific PDF —
the rest of the conversation is set in that document's context.

You have access to the following retrieved excerpts from that PDF
(ranked by relevance to the student's latest question):

----- BEGIN PDF EXCERPTS -----
{context}
----- END PDF EXCERPTS -----

RULES:
- Ground every factual claim in the excerpts above. If the excerpts
  don't cover the question, say so honestly: "I couldn't find that in
  this document — let me give you a general answer." Then answer using
  general knowledge but flag it clearly.
- Cite specific page numbers using "(p.N)" or "(pp.N-M)" inline. Use
  ONLY the page spans shown in the excerpt headers — do not invent
  page numbers.
- Keep replies concise (2-5 short paragraphs at most). Use markdown
  bullet points if it helps clarity.
- If the student asks a multi-step problem, walk through it step by
  step.
- If the student is greeting / off-topic, respond briefly and steer
  back to the document.
"""


def _format_context(chunks: list[dict]) -> str:
    if not chunks:
        return "(No matching content found in this PDF.)"
    blocks: list[str] = []
    for i, c in enumerate(chunks, start=1):
        page_start = c.get("pageStart", "?")
        page_end = c.get("pageEnd", page_start)
        page_label = (
            f"p.{page_start}"
            if page_start == page_end
            else f"pp.{page_start}-{page_end}"
        )
        text = (c.get("text") or "")[:1200]
        blocks.append(f"[Excerpt {i} | {page_label}]\n{text}")
    return "\n\n".join(blocks)


def _to_litellm_messages(req: ChatRequest, system_prompt: str) -> list[dict]:
    messages: list[dict] = [{"role": "system", "content": system_prompt}]
    for turn in req.prior_turns[-10:]:  # last 10 turns to bound prompt size
        role = "user" if turn.sender == "user" else "assistant"
        messages.append({"role": role, "content": turn.message})
    messages.append({"role": "user", "content": req.question})
    return messages


async def run_chat_about_pdf(req: ChatRequest) -> ChatResponse:
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY not set; cannot run chat.")

    subject_key = make_subject_key(
        university=req.university,
        course=req.course,
        branch=req.branch,
        sem=req.sem,
        subject=req.subject,
    )

    # Lazy-ingest if subject hasn't been indexed yet.
    if not is_ingested(subject_key):
        logger.info("RAG missing for %s — ingesting", subject_key)
        result = await ingest_subject(
            university=req.university,
            course=req.course,
            branch=req.branch,
            sem=req.sem,
            subject=req.subject,
        )
        logger.info(
            "ingest done: %d resources, %d chunks, %d failures",
            result.resources_ingested, result.chunks_added, len(result.failures),
        )

    # 1. Embed question
    q_embedding = await embed_one(req.question)

    # 2. RAG search filtered to this specific PDF
    chunks = search(
        subject_key=subject_key,
        query_embedding=q_embedding,
        top_k=5,
        resource_id_filter=req.resource_id,
    )
    grounded = bool(chunks)

    context = _format_context(chunks)
    system_prompt = SYSTEM_PROMPT_TEMPLATE.format(context=context)
    messages = _to_litellm_messages(req, system_prompt)

    # 3. Single LLM call
    model = os.environ.get("LLM_MODEL", "gemini/gemini-2.5-flash-lite")
    response = await litellm.acompletion(
        model=model,
        api_key=api_key,
        messages=messages,
        temperature=0.4,
    )
    reply = response["choices"][0]["message"]["content"].strip()

    citations: List[ChatCitation] = [
        ChatCitation(
            page_start=c.get("pageStart", 1),
            page_end=c.get("pageEnd", c.get("pageStart", 1)),
        )
        for c in chunks
    ]

    return ChatResponse(reply=reply, citations=citations, grounded=grounded)
