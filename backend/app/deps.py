"""FastAPI dependencies — auth in particular.

The ``get_uid`` dependency reads the ``Authorization`` header and
returns the caller's uid. Two schemes are accepted:

- ``Authorization: Bearer <firebase_id_token>`` — the production path.
  The Firebase Admin SDK verifies the token; on success we return the
  decoded ``uid``.
- ``Authorization: Admin <BACKEND_ADMIN_KEY>:<uid>`` — the dev bypass.
  If the supplied key matches ``settings.backend_admin_key`` (constant-
  time compare), we trust the supplied uid and skip Firebase verification.

The Admin scheme is intentionally simple — designed for curl/Postman
when signing in as a real Firebase user is friction. The admin key
should be a long random string treated like a secret.
"""
import hmac
import logging

from fastapi import Header, HTTPException
from firebase_admin import auth as firebase_auth

from .settings import settings


logger = logging.getLogger(__name__)


def _const_time_eq(a: str, b: str) -> bool:
    return hmac.compare_digest(a.encode("utf-8"), b.encode("utf-8"))


def get_uid(authorization: str | None = Header(default=None)) -> str:
    """Resolve the caller uid from the Authorization header."""
    if not authorization:
        raise HTTPException(status_code=401, detail={"error": "missing Authorization header"})

    scheme, _, value = authorization.partition(" ")
    scheme_lower = scheme.lower()

    if scheme_lower == "admin":
        key, _, uid = value.partition(":")
        if not key or not uid:
            raise HTTPException(
                status_code=401,
                detail={"error": "malformed Admin auth — expected 'Admin <key>:<uid>'"},
            )
        if not _const_time_eq(key, settings.backend_admin_key):
            raise HTTPException(status_code=401, detail={"error": "invalid admin key"})
        logger.warning("admin bypass accepted for uid=%s", uid)
        return uid

    if scheme_lower == "bearer":
        token = value.strip()
        if not token:
            raise HTTPException(status_code=401, detail={"error": "empty Bearer token"})
        try:
            decoded = firebase_auth.verify_id_token(token)
        except Exception as exc:
            raise HTTPException(
                status_code=401,
                detail={"error": f"invalid Firebase token: {exc}"},
            )
        return decoded["uid"]

    raise HTTPException(
        status_code=401,
        detail={"error": f"unsupported auth scheme: {scheme!r}"},
    )
