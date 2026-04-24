"""Tests for shared.errors — typed exception hierarchy + user-facing mapping."""
import pytest

from shared.errors import (
    AIBackendError,
    AuthError,
    RateLimitError,
    TimeoutError as BackendTimeout,
    AgentFailureError,
    user_facing_message,
)


def test_auth_error_maps_to_friendly_message():
    err = AuthError("invalid token")
    assert user_facing_message(err) == "Your session has expired. Please log in again."


def test_rate_limit_error_maps_to_friendly_message():
    err = RateLimitError("minimax 429")
    assert user_facing_message(err) == "AI service is busy. Please try again in a moment."


def test_timeout_error_maps_to_friendly_message():
    err = BackendTimeout("exceeded 180s")
    assert user_facing_message(err) == "Analysis took too long. Try again in a moment."


def test_agent_failure_maps_to_friendly_message():
    err = AgentFailureError("syllabus agent failed")
    assert user_facing_message(err) == "We couldn't complete the analysis this time. Tap to try again."


def test_generic_error_maps_to_catchall():
    err = Exception("something unexpected")
    assert user_facing_message(err) == "Something went wrong. Please try again."
