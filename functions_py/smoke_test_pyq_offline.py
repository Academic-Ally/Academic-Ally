"""Offline smoke test — runs the crew without Firestore dependencies.

Uses monkeypatching to stub out init_tracker / update_agent_status /
mark_complete / mark_failed so the crew can run without Google Application
Default Credentials. Only tests that Minimax + Tavily + CrewAI produce a
valid PyqAnalysisOutput.

Run:
    cd academic_ally
    source functions_py/venv/Scripts/activate
    python functions_py/smoke_test_pyq_offline.py
"""
import json
import sys
from pathlib import Path

from dotenv import load_dotenv

load_dotenv(Path(__file__).parent / ".env")

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

# Stub out Firestore-dependent progress helpers BEFORE importing crew
from functions_py.shared import progress  # noqa: E402

progress.init_tracker = lambda **kw: None
progress.update_agent_status = lambda *a, **kw: None
progress.mark_complete = lambda *a, **kw: None
progress.mark_failed = lambda *a, **kw: None
progress.make_crewai_step_callback = lambda *a, **kw: (lambda step_output: None)

from functions_py.features.pyq_analyzer.crew import run_pyq_analysis  # noqa: E402
from functions_py.features.pyq_analyzer.schema import PyqAnalyzeRequest  # noqa: E402


def main() -> None:
    req = PyqAnalyzeRequest(
        run_id="smoke-test-offline",
        university="JNTUH",
        course="BTECH",
        branch="CSE",
        sem="3",
        subject="Database Management Systems",
        pyq_resource_ids=[],
        force_refresh=True,
    )

    print(f"Running PYQ crew for {req.subject}...")
    print("(This takes 60-120s. Verbose CrewAI logs follow.)\n")
    output = run_pyq_analysis(req)

    print("\n=== RESULT ===\n")
    result_dict = output.to_firestore_dict()
    print(json.dumps(result_dict, indent=2, default=str))

    # Sanity checks
    print("\n=== SANITY ===")
    print(f"subject: {result_dict['subject']}")
    print(f"topic_weights count: {len(result_dict['topicWeights'])}")
    print(f"topic_weights sum: {sum(result_dict['topicWeights'].values()):.3f} (should be ~1.0)")
    print(f"predicted_questions count: {len(result_dict['predictedQuestions'])}")
    if result_dict['predictedQuestions']:
        q = result_dict['predictedQuestions'][0]
        print(f"first question likelihood: {q['likelihood']}")
        print(f"first question marks: {q['expectedMarks']}")


if __name__ == "__main__":
    main()
