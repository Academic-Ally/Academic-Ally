"""Pydantic schemas for Snap-a-Doubt.

Output shape mirrors the existing Flutter DoubtSolution model
(lib/models/ai_models.dart) exactly so the existing UI renders
without changes.
"""
from typing import List, Optional

from pydantic import BaseModel, Field


class SnapDoubtRequest(BaseModel):
    """Input from Flutter."""

    run_id: str = Field(..., description="Client UUID for progress tracking")
    uid: str = Field(..., description="Owner uid (writes go to Users/{uid}/DoubtHistory)")
    doubt_id: str = Field(
        ..., description="Client-generated doubt ID; matches the storage path"
    )
    storage_id: str = Field(
        ..., description="Firebase Storage path, e.g. 'Doubts/{uid}/{doubt_id}.jpg'"
    )
    university: str = Field(..., min_length=1)
    course: str = Field(..., min_length=1)
    branch: str = Field(..., min_length=1)
    sem: str = Field(..., min_length=1)
    subject: str = Field(..., min_length=1, description="Subject the doubt belongs to")


class CitationOut(BaseModel):
    """Structured citation tied to a step.

    The agent fills only ``resource_id`` (from the `[CITE:resource_id:page]`
    marker) and the page span. The post-crew resolver fills ``filename``,
    ``storage_id``, and ``category`` from the Firestore resource doc.
    """

    resource_id: str  # required; this is the source-of-truth for resolution
    page_start: int = Field(ge=1)
    page_end: int = Field(ge=1)
    filename: str = ""  # filled by backend resolver
    storage_id: Optional[str] = None
    category: Optional[str] = None  # Notes / QuestionPapers / etc.


class SolutionStepOut(BaseModel):
    index: int = Field(ge=1, le=20)
    description: str
    latex: Optional[str] = None
    citations: List[CitationOut] = Field(default_factory=list)


class DoubtSolutionOutput(BaseModel):
    """Final structured solution returned to Flutter + written to Firestore."""

    extracted_question: str = Field(..., min_length=1)
    subject: str
    topic: str = Field(..., description="Specific topic within the subject")
    steps: List[SolutionStepOut] = Field(..., min_length=1)
    final_answer: str

    def to_firestore_dict(self, *, image_url: str) -> dict:
        """Render to the camelCase shape Flutter's DoubtSolution.fromFirestore reads."""
        return {
            "imageUrl": image_url,
            "extractedQuestion": self.extracted_question,
            "subject": self.subject,
            "topic": self.topic,
            "steps": [
                {
                    "index": s.index,
                    "description": s.description,
                    **({"latex": s.latex} if s.latex else {}),
                    "citations": [
                        {
                            "filename": c.filename,
                            "pageStart": c.page_start,
                            "pageEnd": c.page_end,
                            **({"storageId": c.storage_id} if c.storage_id else {}),
                            **({"resourceId": c.resource_id} if c.resource_id else {}),
                            **({"category": c.category} if c.category else {}),
                        }
                        for c in s.citations
                    ],
                }
                for s in self.steps
            ],
            "finalAnswer": self.final_answer,
        }
