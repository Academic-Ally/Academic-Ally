"""Tests for shared.cache — Firestore cache helpers."""
from datetime import datetime, timedelta, timezone
from unittest.mock import MagicMock, patch

import pytest

from functions_py.shared.cache import read_cache, write_cache, is_fresh


def _mock_firestore():
    """Return (client_mock, doc_ref_mock, doc_snapshot_mock) for chaining."""
    snap = MagicMock()
    doc_ref = MagicMock()
    doc_ref.get.return_value = snap
    client = MagicMock()
    client.document.return_value = doc_ref
    return client, doc_ref, snap


def test_read_cache_returns_data_when_fresh():
    client, doc_ref, snap = _mock_firestore()
    snap.exists = True
    snap.to_dict.return_value = {
        "subject": "DBMS",
        "topicWeights": {"ER Model": 0.3},
        "lastAnalyzed": datetime.now(timezone.utc) - timedelta(hours=1),
    }
    with patch("functions_py.shared.cache.firestore.client", return_value=client):
        result = read_cache("PyqAnalysis/JNTUH/BTECH/CSE/3/DBMS", freshness_hours=24)
    assert result is not None
    assert result["subject"] == "DBMS"


def test_read_cache_returns_none_when_missing():
    client, doc_ref, snap = _mock_firestore()
    snap.exists = False
    with patch("functions_py.shared.cache.firestore.client", return_value=client):
        result = read_cache("PyqAnalysis/missing", freshness_hours=24)
    assert result is None


def test_read_cache_returns_none_when_stale():
    client, doc_ref, snap = _mock_firestore()
    snap.exists = True
    snap.to_dict.return_value = {
        "subject": "DBMS",
        "lastAnalyzed": datetime.now(timezone.utc) - timedelta(hours=48),
    }
    with patch("functions_py.shared.cache.firestore.client", return_value=client):
        result = read_cache("PyqAnalysis/stale", freshness_hours=24)
    assert result is None


def test_write_cache_sets_document():
    client, doc_ref, _ = _mock_firestore()
    data = {"subject": "DBMS", "topicWeights": {"ER": 0.3}}
    with patch("functions_py.shared.cache.firestore.client", return_value=client):
        write_cache("PyqAnalysis/JNTUH/BTECH/CSE/3/DBMS", data)
    client.document.assert_called_once()
    doc_ref.set.assert_called_once()
    written = doc_ref.set.call_args[0][0]
    assert written["subject"] == "DBMS"
    assert "lastAnalyzed" in written


def test_is_fresh_within_window():
    ts = datetime.now(timezone.utc) - timedelta(hours=12)
    assert is_fresh(ts, hours=24) is True


def test_is_fresh_outside_window():
    ts = datetime.now(timezone.utc) - timedelta(hours=48)
    assert is_fresh(ts, hours=24) is False


def test_is_fresh_handles_none():
    assert is_fresh(None, hours=24) is False
