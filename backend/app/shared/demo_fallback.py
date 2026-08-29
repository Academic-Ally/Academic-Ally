"""Deterministic demo responses when the Gemini account is unavailable.

The fallback is intentionally narrow: it applies only to the IT branch in
semesters 1 and 2.  It keeps the major-project demo usable without silently
turning the rest of the production application into mock mode.
"""

import asyncio
from datetime import datetime, timedelta, timezone
from typing import Iterable
from uuid import uuid4

from app.settings import settings
from app.shared.progress import update_agent_status


def is_demo_curriculum(branch: str, sem: str) -> bool:
    """Return whether this request is in the explicitly supported demo scope."""
    if not settings.demo_fallback_enabled:
        return False
    normalized_branch = "".join(ch for ch in branch.casefold() if ch.isalnum())
    normalized_sem = "".join(ch for ch in str(sem) if ch.isdigit())
    return (normalized_branch == "it" or "informationtechnology" in normalized_branch) and normalized_sem in {
        "1",
        "2",
    }


async def animate_demo_progress(run_id: str, agent_names: Iterable[str]) -> None:
    """Advance the existing Firestore tracker so the UI retains its agent flow."""
    for agent_name in agent_names:
        await asyncio.sleep(0.35)
        update_agent_status(run_id, agent_name, "done")


def pyq_demo(subject: str, source_resource_ids: list[str]) -> dict:
    return {
        "subject": subject,
        "topicWeights": {
            "Core concepts and definitions": 0.28,
            "Problem-solving methods": 0.24,
            "Worked examples": 0.20,
            "Applications": 0.16,
            "Short-answer fundamentals": 0.12,
        },
        "predictedQuestions": [
            {
                "question": f"Explain the fundamental concepts of {subject} with a suitable example.",
                "topic": "Core concepts and definitions",
                "expectedMarks": 10,
                "likelihood": 0.84,
                "sourcePaperIds": source_resource_ids[:2],
            },
            {
                "question": f"Solve a representative problem from {subject} and justify each step.",
                "topic": "Problem-solving methods",
                "expectedMarks": 10,
                "likelihood": 0.76,
                "sourcePaperIds": source_resource_ids[:2],
            },
            {
                "question": f"Compare two important approaches used in {subject}.",
                "topic": "Applications",
                "expectedMarks": 5,
                "likelihood": 0.69,
                "sourcePaperIds": source_resource_ids[:1],
            },
            {
                "question": f"Write short notes on any two key topics from {subject}.",
                "topic": "Short-answer fundamentals",
                "expectedMarks": 5,
                "likelihood": 0.63,
                "sourcePaperIds": source_resource_ids[:1],
            },
            {
                "question": f"Describe a practical application of {subject} and its limitations.",
                "topic": "Worked examples",
                "expectedMarks": 10,
                "likelihood": 0.58,
                "sourcePaperIds": source_resource_ids[:1],
            },
        ],
        "sourceResourceIds": source_resource_ids,
        "demoFallback": True,
    }


def adversarial_demo(subject: str, question_count: int) -> dict:
    templates = [
        (
            "Concept boundary",
            f"In {subject}, identify the condition under which a commonly used rule no longer applies.",
            "missing assumption",
            "Applying the rule without checking its required conditions.",
            "State the assumptions first, test each one, and only then apply the rule.",
        ),
        (
            "Similar concepts",
            f"Differentiate between two closely related concepts in {subject} using one example each.",
            "similar concepts mixed",
            "Giving definitions that sound alike without explaining the operational difference.",
            "Compare purpose, inputs, outputs, and one concrete example side by side.",
        ),
        (
            "Edge cases",
            f"What happens to a standard {subject} solution when its boundary input is zero or empty?",
            "edge case",
            "Solving only the normal case and ignoring the boundary input.",
            "Trace the method with the boundary value before generalising the result.",
        ),
        (
            "Reasoning",
            f"A student reaches the correct final answer in {subject} using an invalid intermediate step. Is the solution acceptable? Explain.",
            "tricky wording",
            "Accepting the final value without validating the reasoning.",
            "Verify every transformation; a coincidentally correct result is not a valid solution.",
        ),
        (
            "Application choice",
            f"Choose the most suitable method for a practical {subject} problem and defend your choice.",
            "common confusion",
            "Selecting a familiar method without matching it to the problem constraints.",
            "List the constraints, compare candidate methods, then justify the best fit.",
        ),
        (
            "Error analysis",
            f"Find and correct the hidden error in a typical worked example from {subject}.",
            "common confusion",
            "Repeating the procedure mechanically without checking units or assumptions.",
            "Recalculate step by step and validate units, signs, and boundary conditions.",
        ),
    ]
    questions = []
    for index in range(question_count):
        topic, question, trap, mistake, approach = templates[index % len(templates)]
        questions.append(
            {
                "topic": topic,
                "question": question,
                "trapType": trap,
                "commonMistake": mistake,
                "correctApproach": approach,
                "expectedMarks": 5 if index % 2 else 10,
                "difficulty": "hard" if index % 3 else "medium",
                "sourcePaperIds": [],
            }
        )
    return {
        "subject": subject,
        "overallFocus": (
            f"A demo-mode diagnostic quiz for common reasoning traps in {subject}."
        ),
        "questions": questions,
        "demoFallback": True,
    }


def study_plan_demo(
    subjects: list[str], exam_date: datetime, daily_study_minutes: int
) -> tuple[str, dict]:
    plan_id = f"demo-{uuid4()}"
    now = datetime.now(timezone.utc)
    target = exam_date if exam_date.tzinfo else exam_date.replace(tzinfo=timezone.utc)
    available_days = max(1, min(7, (target.date() - now.date()).days + 1))
    per_subject = max(20, min(90, daily_study_minutes // max(1, len(subjects))))
    days = []
    for offset in range(available_days):
        revision = offset >= max(0, available_days - 2)
        tasks = []
        for subject in subjects:
            topic = (
                "Revision and self-test"
                if revision
                else [
                    "Core concepts",
                    "Important worked problems",
                    "Frequently tested applications",
                ][offset % 3]
            )
            tasks.append(
                {
                    "subject": subject,
                    "topic": topic,
                    "durationMinutes": per_subject,
                    "rationale": (
                        "Consolidate recall before the exam."
                        if revision
                        else "Build understanding before moving to exam-style practice."
                    ),
                    "completed": False,
                }
            )
        days.append(
            {
                "date": now + timedelta(days=offset),
                "tasks": tasks,
            }
        )
    payload = {
        "examDate": target,
        "subjects": subjects,
        "overallStrategy": (
            "Demo mode: study core ideas first, practise representative problems, "
            "and reserve the final sessions for revision and self-testing."
        ),
        "days": days,
        "demoFallback": True,
    }
    return plan_id, payload


def snap_doubt_demo(subject: str, image_url: str) -> dict:
    return {
        "imageUrl": image_url,
        "extractedQuestion": (
            f"Demo question detected from the uploaded image for {subject}."
        ),
        "subject": subject,
        "topic": "Guided problem solving",
        "steps": [
            {
                "index": 1,
                "description": "Identify the known values and the quantity the question asks for.",
                "citations": [],
            },
            {
                "index": 2,
                "description": f"Select the relevant principle from {subject} and state its assumptions.",
                "citations": [],
            },
            {
                "index": 3,
                "description": "Substitute the values carefully and simplify one step at a time.",
                "citations": [],
            },
            {
                "index": 4,
                "description": "Check the result against units, signs, and the original question.",
                "citations": [],
            },
        ],
        "finalAnswer": (
            "Demo mode completed the structured solution flow. Use the shown method "
            "to verify the final value from the uploaded problem."
        ),
        "demoFallback": True,
    }


def chat_demo(subject: str, question: str) -> dict:
    return {
        "reply": (
            f"Demo mode answer for {subject}: start by identifying the central concept "
            f"behind “{question.strip()}”. Define it in your own words, connect it to a "
            "worked example from the open PDF, and then check the assumptions and units. "
            "This keeps the explanation exam-ready even while live AI quota is unavailable."
        ),
        "grounded": False,
        "citations": [],
        "demoFallback": True,
    }
