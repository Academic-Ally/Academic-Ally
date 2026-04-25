"""Pydantic schemas for Study Planner.

Output shape mirrors the existing Flutter StudyPlan model
(lib/models/ai_models.dart) exactly so the existing Flutter UI renders
without changes. Dates are ISO-8601 strings for JSON cleanliness;
Flutter parses them via DateTime.parse.
"""
from datetime import datetime
from typing import Dict, List

from pydantic import BaseModel, Field


class StudyPlanRequest(BaseModel):
    """Input from Flutter."""

    run_id: str = Field(..., description="Client UUID for progress tracking")
    uid: str = Field(..., description="Owner uid (writes go to Users/{uid}/StudyPlans)")
    university: str
    course: str
    branch: str
    sem: str
    subjects: List[str] = Field(..., min_length=1)
    exam_date: datetime = Field(..., description="Target exam date")
    daily_study_minutes: int = Field(120, ge=30, le=720)
    weak_topics: List[str] = Field(default_factory=list)
    force_refresh: bool = Field(False)


class StudyTaskOut(BaseModel):
    subject: str
    topic: str
    duration_minutes: int = Field(ge=10, le=240)
    rationale: str  # one-line explanation of WHY this topic now
    completed: bool = False


class StudyDayOut(BaseModel):
    date: datetime
    tasks: List[StudyTaskOut] = Field(..., min_length=1)


class StudyPlanOutput(BaseModel):
    """Final plan returned to Flutter + written to Firestore."""

    plan_id: str
    exam_date: datetime
    subjects: List[str]
    days: List[StudyDayOut] = Field(..., min_length=1)
    overall_strategy: str  # 1-3 sentence summary the student sees on the detail screen

    def to_firestore_dict(self) -> dict:
        """Render to the camelCase shape Flutter's StudyPlan.fromFirestore reads."""
        return {
            "examDate": self.exam_date,
            "subjects": self.subjects,
            "overallStrategy": self.overall_strategy,
            "days": [
                {
                    "date": day.date,
                    "tasks": [
                        {
                            "subject": t.subject,
                            "topic": t.topic,
                            "durationMinutes": t.duration_minutes,
                            "rationale": t.rationale,
                            "completed": t.completed,
                        }
                        for t in day.tasks
                    ],
                }
                for day in self.days
            ],
        }
