"""Prove the deployed AI backend works end to end, exactly as the app uses it.

Mints a real Firebase ID token for a throwaway user, calls /generate_study_plan
on the deployed service, reports the outcome, then deletes the test user and
every document the run created. Costs one Gemini crew run (a few rupees).

Run from backend/ (needs service-account.json + the Android google-services.json):
    uv run python scripts/verify_prod_ai.py
    uv run python scripts/verify_prod_ai.py --base-url https://<other-host>

Exit code 0 = genuine AI output was produced; 1 = the backend failed.
"""
import argparse
import datetime as dt
import json
import os
import sys
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
os.environ.setdefault("GOOGLE_APPLICATION_CREDENTIALS", str(HERE / "service-account.json"))

import firebase_admin  # noqa: E402
from firebase_admin import auth, firestore  # noqa: E402

DEFAULT_BASE = "https://academic-ally-production-503f.up.railway.app"
TEST_UID = "verify-prod-ai-" + dt.date.today().isoformat()


def _post(url: str, body: dict, headers: dict | None = None, timeout: int = 600):
    req = urllib.request.Request(
        url, data=json.dumps(body).encode(), headers={"Content-Type": "application/json", **(headers or {})}
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, json.loads(r.read())
    except urllib.error.HTTPError as e:
        raw = e.read().decode(errors="replace")
        try:
            return e.code, json.loads(raw)
        except ValueError:
            return e.code, raw[:800]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base-url", default=DEFAULT_BASE)
    args = ap.parse_args()
    base = args.base_url.rstrip("/")

    firebase_admin.initialize_app()
    db = firestore.client()
    gs = json.load(open(HERE.parent / "android" / "app" / "google-services.json", encoding="utf-8"))
    web_key = gs["client"][0]["api_key"][0]["current_key"]

    # 0. health + stale-build detector
    with urllib.request.urlopen(f"{base}/health", timeout=60) as r:
        health = json.loads(r.read())
    print("health:", health)
    if "demo_fallback_enabled" in health:
        print("!! STALE BUILD: /health still has demo_fallback_enabled (removed in 6ab4eea). Redeploy from master.")

    # 1. real Firebase ID token for a throwaway user
    custom = auth.create_custom_token(TEST_UID).decode()
    st, tok = _post(
        f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key={web_key}",
        {"token": custom, "returnSecureToken": True},
    )
    if st != 200:
        print("could not mint ID token:", st, tok)
        return 1
    id_token = tok["idToken"]

    run_id = str(uuid.uuid4())
    body = {
        "run_id": run_id,
        "uid": TEST_UID,
        "university": "JNTUH",
        "course": "BTECH",
        "branch": "CSE",
        "sem": "3",
        "subjects": ["Computer Organization"],
        "exam_date": (dt.datetime.now(dt.timezone.utc) + dt.timedelta(days=21)).isoformat(),
        "daily_study_minutes": 120,
        "weak_topics": [],
        "force_refresh": True,
    }
    ok = False
    try:
        t0 = time.time()
        st, res = _post(f"{base}/generate_study_plan", body, {"Authorization": f"Bearer {id_token}"})
        print(f"/generate_study_plan -> HTTP {st} in {time.time() - t0:.0f}s")
        if st == 200 and isinstance(res, dict) and res.get("plan_id"):
            tasks = res.get("tasks") or res.get("daily_tasks") or []
            print("GENUINE OUTPUT: plan_id =", res["plan_id"], "| tasks =", len(tasks))
            print("strategy:", str(res.get("overall_strategy"))[:240])
            ok = True
        else:
            print("FAILED:", json.dumps(res, indent=1)[:1200] if isinstance(res, dict) else res)
        run = db.document(f"AnalysisRuns/{run_id}").get().to_dict() or {}
        print("AnalysisRuns status:", run.get("status"))
    finally:
        # 2. leave no trace
        for d in db.collection(f"Users/{TEST_UID}/StudyPlans").stream():
            d.reference.delete()
        db.document(f"AnalysisRuns/{run_id}").delete()
        for coll in db.document(f"Users/{TEST_UID}").collections():
            for d in coll.stream():
                d.reference.delete()
        db.document(f"Users/{TEST_UID}").delete()
        try:
            auth.delete_user(TEST_UID)
        except auth.UserNotFoundError:
            pass
        print("cleanup done: test user and its documents deleted")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
