"""Firebase Admin SDK initialisation, with deploy-target-friendly credentials.

Three sources, in priority order:

1. ``FIREBASE_SERVICE_ACCOUNT_JSON`` — the entire ``service-account.json``
   contents pasted as an env var (raw JSON or base64). This is the
   Railway / Render / Fly / Cloud Run friendly path: no file uploads
   required, just a string env var.

2. ``GOOGLE_APPLICATION_CREDENTIALS`` — a path to a JSON file on disk
   (``settings.google_application_credentials``). Local-dev path.

3. Ambient defaults — gcloud user creds, attached service account, etc.
   Used when no explicit credentials are configured.

Other Google libs (e.g. ``google.cloud.firestore_v1`` outside
firebase-admin) read ``GOOGLE_APPLICATION_CREDENTIALS`` from os.environ.
The path-mode flow continues to push it into env. The JSON-mode flow
writes the credentials out to a managed temp file and points the env
var at that file, so non-firebase-admin Google clients still resolve
the same identity.
"""
from __future__ import annotations

import base64
import json
import logging
import os
import tempfile
from typing import Any

import firebase_admin
from firebase_admin import credentials


logger = logging.getLogger(__name__)


def _parse_service_account_blob(raw: str) -> dict[str, Any]:
    """Accept raw JSON or base64-encoded JSON, return the parsed dict."""
    raw = raw.strip()
    if not raw:
        raise ValueError("FIREBASE_SERVICE_ACCOUNT_JSON is empty.")

    # Raw JSON path
    try:
        data = json.loads(raw)
        if isinstance(data, dict) and data.get("type") == "service_account":
            return data
    except json.JSONDecodeError:
        pass

    # Base64-encoded JSON path
    try:
        decoded = base64.b64decode(raw, validate=False).decode("utf-8")
        data = json.loads(decoded)
        if isinstance(data, dict) and data.get("type") == "service_account":
            return data
    except Exception:
        pass

    raise ValueError(
        "FIREBASE_SERVICE_ACCOUNT_JSON could not be parsed as either raw "
        "JSON or base64-encoded JSON. Paste the full service-account.json "
        "content (or its base64 form) into the env var."
    )


def _materialise_temp_credential_file(sa_dict: dict[str, Any]) -> str:
    """Write the credential JSON to a temp file and point env at it.

    Some Google libs (notably the raw google.cloud.* clients used outside
    firebase-admin) read GOOGLE_APPLICATION_CREDENTIALS from process env.
    We don't use any in this codebase today, but writing the file is
    cheap insurance.
    """
    tmp = tempfile.NamedTemporaryFile(
        mode="w",
        prefix="firebase-sa-",
        suffix=".json",
        delete=False,
        encoding="utf-8",
    )
    json.dump(sa_dict, tmp)
    tmp.close()
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = tmp.name
    return tmp.name


def init_firebase_admin(*, storage_bucket: str | None = None) -> firebase_admin.App:
    """Initialise firebase_admin with whichever credential source is configured.

    Idempotent — if an app is already initialised, returns it.
    """
    if firebase_admin._apps:
        return firebase_admin.get_app()

    # Lazy-import settings so this module can be loaded before pydantic
    # finishes resolving env vars.
    from .settings import settings

    cred: credentials.Base | None = None

    sa_raw = settings.firebase_service_account_json
    if sa_raw:
        try:
            sa_dict = _parse_service_account_blob(sa_raw)
        except ValueError as exc:
            logger.error("invalid FIREBASE_SERVICE_ACCOUNT_JSON: %s", exc)
            raise

        # firebase-admin's Certificate accepts a dict directly.
        cred = credentials.Certificate(sa_dict)
        # Keep GOOGLE_APPLICATION_CREDENTIALS pointed at a real file for
        # any non-firebase-admin Google client that may need it.
        path = _materialise_temp_credential_file(sa_dict)
        logger.info(
            "firebase_admin: using FIREBASE_SERVICE_ACCOUNT_JSON env var "
            "(materialised to %s)",
            path,
        )
    elif settings.google_application_credentials:
        cred_path = settings.google_application_credentials
        if not os.path.isabs(cred_path):
            # Resolve relative to backend/ root.
            cred_path = os.path.abspath(
                os.path.join(os.path.dirname(__file__), "..", cred_path)
            )
        if not os.path.exists(cred_path):
            raise FileNotFoundError(
                f"GOOGLE_APPLICATION_CREDENTIALS points at a missing file: "
                f"{cred_path}"
            )
        os.environ.setdefault("GOOGLE_APPLICATION_CREDENTIALS", cred_path)
        cred = credentials.Certificate(cred_path)
        logger.info("firebase_admin: using credential file %s", cred_path)
    else:
        logger.info(
            "firebase_admin: no explicit credential configured — "
            "falling back to ambient default (gcloud / attached SA)"
        )

    options: dict[str, Any] = {}
    if storage_bucket:
        options["storageBucket"] = storage_bucket

    init_kwargs: dict[str, Any] = {}
    if cred is not None:
        init_kwargs["credential"] = cred
    if options:
        init_kwargs["options"] = options

    return firebase_admin.initialize_app(**init_kwargs)
