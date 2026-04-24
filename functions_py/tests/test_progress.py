"""Tests for shared.progress — AnalysisRuns tracker + step callback."""
from unittest.mock import MagicMock, patch

import pytest

from shared.progress import (
    init_tracker,
    update_agent_status,
    mark_complete,
    mark_failed,
)


def _mock_firestore():
    doc_ref = MagicMock()
    client = MagicMock()
    client.document.return_value = doc_ref
    return client, doc_ref


def test_init_tracker_writes_initial_doc():
    client, doc_ref = _mock_firestore()
    agents = ["syllabus", "web", "pattern", "predictor", "formatter"]
    with patch("shared.progress.firestore.client", return_value=client):
        init_tracker(run_id="abc123", subject="DBMS", agent_names=agents)
    client.document.assert_called_once_with("AnalysisRuns/abc123")
    doc_ref.set.assert_called_once()
    written = doc_ref.set.call_args[0][0]
    assert written["status"] == "running"
    assert written["subject"] == "DBMS"
    assert written["runId"] == "abc123"
    assert written["agents"] == {a: "pending" for a in agents}


def test_update_agent_status_writes_single_field():
    client, doc_ref = _mock_firestore()
    with patch("shared.progress.firestore.client", return_value=client):
        update_agent_status("abc123", "syllabus", "done")
    doc_ref.update.assert_called_once()
    updated = doc_ref.update.call_args[0][0]
    assert updated == {"agents.syllabus": "done"}


def test_mark_complete_updates_status():
    client, doc_ref = _mock_firestore()
    with patch("shared.progress.firestore.client", return_value=client):
        mark_complete("abc123")
    updated = doc_ref.update.call_args[0][0]
    assert updated["status"] == "complete"


def test_mark_failed_includes_message():
    client, doc_ref = _mock_firestore()
    with patch("shared.progress.firestore.client", return_value=client):
        mark_failed("abc123", "syllabus", "rate limit hit")
    updated = doc_ref.update.call_args[0][0]
    assert updated["status"] == "failed"
    assert updated["errorMessage"] == "rate limit hit"
    assert updated["agents.syllabus"] == "failed"
