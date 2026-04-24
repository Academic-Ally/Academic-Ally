"""Firebase ID token verification helpers.

The verifier assumes ``firebase_admin`` has been initialized elsewhere
(main.py does this on module load). A fresh initialization per request
would be wasteful.
"""
from typing import Mapping

from firebase_admin import auth as firebase_auth

from .errors import AuthError


def verify_token(id_token: str) -> str:
    """Verify a Firebase ID token and return the authenticated user's uid.

    Raises ``AuthError`` if the token is invalid, expired, or revoked.
    """
    if not id_token:
        raise AuthError("missing token")
    try:
        decoded = firebase_auth.verify_id_token(id_token)
    except Exception as exc:
        raise AuthError(f"token verification failed: {exc}") from exc
    return decoded["uid"]


def extract_uid(headers: Mapping[str, str]) -> str:
    """Extract and verify the Firebase ID token from an Authorization header.

    Expected header format: ``Authorization: Bearer <id_token>``.
    """
    auth_header = headers.get("Authorization") or headers.get("authorization")
    if not auth_header:
        raise AuthError("missing Authorization header")
    if not auth_header.startswith("Bearer "):
        raise AuthError("Authorization header must use Bearer scheme")
    id_token = auth_header[len("Bearer "):].strip()
    return verify_token(id_token)
