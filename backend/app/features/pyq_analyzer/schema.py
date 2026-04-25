"""Pydantic schemas for PYQ Analyzer input + output.

Input matches what the Flutter client POSTs. Output matches the
existing ``PyqAnalysis`` Firestore doc shape so Flutter renders it
identically to the MockAIService output.
"""
from typing import Dict, List

from pydantic import BaseModel, Field


class PyqAnalyzeRequest(BaseModel):
    """Input from Flutter."""

    run_id: str = Field(..., description="Client-generated UUID for progress tracking")
    university: str = Field(..., min_length=1)
    course: str = Field(..., min_length=1)
    branch: str = Field(..., min_length=1)
    sem: str = Field(..., min_length=1)
    subject: str = Field(..., min_length=1)
    pyq_resource_ids: List[str] = Field(default_factory=list)
    force_refresh: bool = Field(False, description="Bypass cache if True")


class PredictedQuestion(BaseModel):
    """One predicted exam question."""

    question: str
    topic: str
    expected_marks: int = Field(ge=1, le=20)
    likelihood: float = Field(ge=0.0, le=1.0)
    source_paper_ids: List[str] = Field(default_factory=list)


class PyqAnalysisOutput(BaseModel):
    """Final output returned to Flutter + written to the cache."""

    subject: str
    topic_weights: Dict[str, float]
    predicted_questions: List[PredictedQuestion] = Field(..., min_length=3)
    source_resource_ids: List[str] = Field(default_factory=list)

    def to_firestore_dict(self) -> dict:
        """Render to the snake_case→camelCase shape Flutter expects."""
        return {
            "subject": self.subject,
            "topicWeights": self.topic_weights,
            "predictedQuestions": [
                {
                    "question": q.question,
                    "topic": q.topic,
                    "expectedMarks": q.expected_marks,
                    "likelihood": q.likelihood,
                    "sourcePaperIds": q.source_paper_ids,
                }
                for q in self.predicted_questions
            ],
            "sourceResourceIds": self.source_resource_ids,
        }
