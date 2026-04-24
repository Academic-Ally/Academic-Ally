"""Tests for shared.auth — Firebase ID token verifier."""
from unittest.mock import patch, MagicMock

import pytest

from shared.auth import verify_token, extract_uid
from shared.errors import AuthError


def test_verify_token_returns_uid_on_valid():
    with patch("shared.auth.firebase_auth") as mock_auth:
        mock_auth.verify_id_token.return_value = {"uid": "user-123", "email": "a@b.c"}
        uid = verify_token("valid-token")
        assert uid == "user-123"
        mock_auth.verify_id_token.assert_called_once_with("valid-token")


def test_verify_token_raises_auth_error_on_invalid():
    with patch("shared.auth.firebase_auth") as mock_auth:
        mock_auth.verify_id_token.side_effect = Exception("invalid signature")
        with pytest.raises(AuthError):
            verify_token("bad-token")


def test_extract_uid_reads_bearer_token():
    with patch("shared.auth.verify_token") as mock_verify:
        mock_verify.return_value = "user-xyz"
        headers = {"Authorization": "Bearer abc.def.ghi"}
        uid = extract_uid(headers)
        assert uid == "user-xyz"
        mock_verify.assert_called_once_with("abc.def.ghi")


def test_extract_uid_raises_when_header_missing():
    with pytest.raises(AuthError):
        extract_uid({})


def test_extract_uid_raises_when_header_malformed():
    with pytest.raises(AuthError):
        extract_uid({"Authorization": "NotBearer xyz"})
