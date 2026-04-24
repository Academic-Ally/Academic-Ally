"""Local smoke test — invokes the PYQ crew end-to-end.

Requires a .env in functions_py/ with MINIMAX_API_KEY, TAVILY_API_KEY.

Run:
    cd academic_ally
    source functions_py/venv/Scripts/activate
    python functions_py/smoke_test_pyq.py
"""
import json
import sys
from pathlib import Path

try:
    from dotenv import load_dotenv

    load_dotenv(Path(__file__).parent / ".env")
except Exception:
    print("WARN: python-dotenv not installed; expecting env vars elsewhere")

import firebase_admin

if not firebase_admin._apps:
    firebase_admin.initialize_app()

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from functions_py.features.pyq_analyzer.agents import TRACKER_AGENT_NAMES
from functions_py.features.pyq_analyzer.crew import run_pyq_analysis
from functions_py.features.pyq_analyzer.schema import PyqAnalyzeRequest
from functions_py.shared.progress import init_tracker


def main() -> None:
    req = PyqAnalyzeRequest(
        run_id="smoke-test-local",
        university="JNTUH",
        course="BTECH",
        branch="CSE",
        sem="3",
        subject="Database Management Systems",
        pyq_resource_ids=[],
        force_refresh=True,
    )

    init_tracker(
        run_id=req.run_id,
        subject=req.subject,
        agent_names=TRACKER_AGENT_NAMES,
    )

    print(f"Running PYQ crew for {req.subject}...")
    output = run_pyq_analysis(req)

    print("\n=== RESULT ===\n")
    print(json.dumps(output.to_firestore_dict(), indent=2, default=str))


if __name__ == "__main__":
    main()
