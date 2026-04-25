"""Pydantic schemas for AllyBot chat-about-PDF.

Single-PDF chat: each request scoped to one specific resource (the PDF
the user is asking about). RAG search is filtered to that resource's
chunks via ``resource_id_filter`` in vector_store.search.
"""
from typing import List, Optional

from pydantic import BaseModel, Field


class ChatTurn(BaseModel):
    """One prior turn of the conversation. ``sender`` is 'user' or 'AllyBot'."""

    sender: str
    message: str


class ChatRequest(BaseModel):
    uid: str
    university: str = Field(..., min_length=1)
    course: str = Field(..., min_length=1)
    branch: str = Field(..., min_length=1)
    sem: str = Field(..., min_length=1)
    subject: str = Field(..., min_length=1)
    resource_id: str = Field(..., description="Firestore resource doc ID")
    question: str = Field(..., min_length=1)
    prior_turns: List[ChatTurn] = Field(
        default_factory=list,
        description="Most recent N turns of conversation history (oldest first).",
    )


class ChatCitation(BaseModel):
    page_start: int
    page_end: int


class ChatResponse(BaseModel):
    reply: str
    citations: List[ChatCitation] = Field(default_factory=list)
    grounded: bool = Field(
        ...,
        description=(
            "True if the answer is grounded in retrieved chunks; False "
            "if the model fell back to general knowledge or the PDF "
            "didn't have relevant context."
        ),
    )
