"""Typed exceptions for the AI backend, with user-facing message mapping.

Internal exceptions carry technical details for logging. ``user_facing_message``
translates them into plain-English strings safe to return in HTTP responses.
"""


class AIBackendError(Exception):
    """Base class for all AI backend errors."""


class AuthError(AIBackendError):
    """Firebase ID token verification failed."""


class RateLimitError(AIBackendError):
    """Upstream LLM or search provider returned 429."""


class TimeoutError(AIBackendError):
    """Overall workflow exceeded its time budget."""


class AgentFailureError(AIBackendError):
    """A worker agent failed after exhausting retries."""


class ValidationError(AIBackendError):
    """Client sent an invalid payload."""


_MESSAGES = {
    AuthError: "Your session has expired. Please log in again.",
    RateLimitError: "AI service is busy. Please try again in a moment.",
    TimeoutError: "Analysis took too long. Try again in a moment.",
    AgentFailureError: "We couldn't complete the analysis this time. Tap to try again.",
    ValidationError: "Request is missing required information.",
}


def user_facing_message(err: Exception) -> str:
    """Translate an internal exception into a plain-English message."""
    for cls, msg in _MESSAGES.items():
        if isinstance(err, cls):
            return msg
    return "Something went wrong. Please try again."
