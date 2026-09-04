"""Failed AI requests must never leak internals unless EXPOSE_DEBUG_ERRORS is on."""
import os

os.environ.setdefault("GEMINI_API_KEY", "test")
os.environ.setdefault("TAVILY_API_KEY", "test")
os.environ.setdefault("BACKEND_ADMIN_KEY", "test-admin")

from fastapi.testclient import TestClient  # noqa: E402

from app.errors import AgentFailureError, error_detail  # noqa: E402
from app.settings import settings  # noqa: E402


def test_error_detail_hides_internals_by_default(monkeypatch):
    monkeypatch.setattr(settings, "expose_debug_errors", False)
    detail = error_detail(AgentFailureError("gemini exploded"), "Traceback: boom")
    assert detail == {"error": "We couldn't complete the analysis this time. Tap to try again."}


def test_error_detail_exposes_internals_when_enabled(monkeypatch):
    monkeypatch.setattr(settings, "expose_debug_errors", True)
    detail = error_detail(AgentFailureError("gemini exploded"), "Traceback: boom")
    assert detail["debug_error"] == "gemini exploded"
    assert detail["debug_traceback"] == "Traceback: boom"


def test_study_plan_route_returns_clean_error_body(monkeypatch):
    """End-to-end through FastAPI: a crew failure yields 503 + plain message only."""
    from app.features.study_planner import routes as sp_routes
    from app.main import app

    monkeypatch.setattr(settings, "expose_debug_errors", False)
    monkeypatch.setattr(sp_routes, "init_tracker", lambda **kw: None)
    monkeypatch.setattr(sp_routes, "mark_failed", lambda *a, **kw: None)

    async def _boom(req):
        raise AgentFailureError("gemini exploded")

    monkeypatch.setattr(sp_routes, "run_study_plan_generation", _boom)

    client = TestClient(app)
    resp = client.post(
        "/generate_study_plan",
        headers={"Authorization": f"Admin {settings.backend_admin_key}:test-uid"},
        json={
            "run_id": "run-1",
            "uid": "test-uid",
            "university": "OU",
            "course": "BE",
            "branch": "IT",
            "sem": "1",
            "subjects": ["Physics"],
            "exam_date": "2026-10-01T00:00:00Z",
        },
    )
    assert resp.status_code == 503
    body = resp.json()["detail"]
    assert body == {"error": "We couldn't complete the analysis this time. Tap to try again."}
    assert "debug_traceback" not in resp.text
