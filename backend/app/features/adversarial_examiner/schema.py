"""Pydantic schemas for Adversarial Examiner.

Generates a quiz of trap questions designed to expose blind spots — the
kinds of confusions Indian engineering students typically have on a
given subject. Single subject per request (unlike Study Planner).
"""
from typing import List

from pydantic import BaseModel, Field


class AdversarialRequest(BaseModel):
    """Input from Flutter."""

    run_id: str = Field(..., description="Client UUID for progress tracking")
    university: str = Field(..., min_length=1)
    course: str = Field(..., min_length=1)
    branch: str = Field(..., min_length=1)
    sem: str = Field(..., min_length=1)
    subject: str = Field(..., min_length=1)
    focus_topics: List[str] = Field(
        default_factory=list,
        description="Optional: narrow the quiz to these topics. Empty = whole subject.",
    )
    question_count: int = Field(6, ge=3, le=12)
    force_refresh: bool = Field(False)


class AdversarialQuestion(BaseModel):
    topic: str
    question: str
    trap_type: str = Field(
        ...,
        description=(
            "What kind of trap this is — e.g., 'common confusion', 'edge case', "
            "'missing assumption', 'similar concepts mixed', 'tricky wording'."
        ),
    )
    common_mistake: str = Field(
        ..., description="What students typically get wrong on this exact question."
    )
    correct_approach: str = Field(
        ..., description="The right way to think about / solve it."
    )
    expected_marks: int = Field(ge=2, le=20)
    difficulty: str = Field(..., description="medium | hard | very_hard")
    source_paper_ids: List[str] = Field(default_factory=list)


class AdversarialExamOutput(BaseModel):
    subject: str
    overall_focus: str = Field(
        ..., description="One-sentence summary of what this quiz tests."
    )
    questions: List[AdversarialQuestion] = Field(..., min_length=3)

    def to_firestore_dict(self) -> dict:
        """Render to camelCase shape Flutter parses."""
        return {
            "subject": self.subject,
            "overallFocus": self.overall_focus,
            "questions": [
                {
                    "topic": q.topic,
                    "question": q.question,
                    "trapType": q.trap_type,
                    "commonMistake": q.common_mistake,
                    "correctApproach": q.correct_approach,
                    "expectedMarks": q.expected_marks,
                    "difficulty": q.difficulty,
                    "sourcePaperIds": q.source_paper_ids,
                }
                for q in self.questions
            ],
        }
