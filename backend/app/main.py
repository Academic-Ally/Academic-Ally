"""FastAPI app factory for the local Academic Ally AI backend.

Runs the same agent crews as functions_py/ but as a regular HTTP
service. In-memory progress + cache, no Firestore. Auth via Firebase
ID token or admin-key bypass (see app/deps.py).
"""
import logging
import os
import sys
import tempfile

# CrewAI 1.x eagerly instantiates an EventListener at import time, which
# tries to read a secure-storage path derived from LOCALAPPDATA / HOME.
# In some cold-start environments those env vars are missing → Path(None)
# crashes. Set them defensively before any crewai import runs.
if sys.platform == "win32":
    os.environ.setdefault("LOCALAPPDATA", tempfile.gettempdir())
else:
    os.environ.setdefault("HOME", tempfile.gettempdir())
os.environ.setdefault("CREWAI_TRACING_ENABLED", "false")

from .settings import settings  # noqa: E402

import firebase_admin  # noqa: E402
from fastapi import FastAPI  # noqa: E402
from fastapi.middleware.cors import CORSMiddleware  # noqa: E402

from .firebase_init import init_firebase_admin  # noqa: E402
from .features.adversarial_examiner.routes import router as adversarial_router  # noqa: E402
from .features.chat_about_pdf.routes import router as chat_router  # noqa: E402
from .features.pyq_analyzer.routes import router as pyq_router  # noqa: E402
from .features.snap_doubt.routes import router as snap_doubt_router  # noqa: E402
from .features.study_planner.routes import router as study_planner_router  # noqa: E402


logging.basicConfig(
    level=getattr(logging, settings.log_level.upper(), logging.INFO),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)


# Initialise Firebase Admin SDK once at import time. The resolver
# accepts either FIREBASE_SERVICE_ACCOUNT_JSON (env-var-friendly for
# Railway / Render / Fly / Cloud Run) or GOOGLE_APPLICATION_CREDENTIALS
# (file path, local-dev friendly).
try:
    init_firebase_admin(storage_bucket=settings.backend_storage_bucket)
    logger.info(
        "firebase_admin initialized (bucket=%s)",
        settings.backend_storage_bucket,
    )
except Exception as exc:
    # Don't fail startup — Bearer token verification will produce a
    # clear error at request time. The Admin bypass scheme still works
    # without credentials configured.
    logger.warning("firebase_admin init failed: %s", exc)


app = FastAPI(
    title="Academic Ally AI Backend (local)",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(pyq_router)
app.include_router(study_planner_router)
app.include_router(adversarial_router)
app.include_router(snap_doubt_router)
app.include_router(chat_router)


@app.get("/health")
def health() -> dict:
    cred_source: str | None = None
    if settings.firebase_service_account_json:
        cred_source = "service_account_env"
    elif settings.google_application_credentials:
        cred_source = "credentials_file"
    return {
        "ok": True,
        "model": settings.llm_model,
        "has_gemini": bool(settings.gemini_api_key),
        "has_tavily": bool(settings.tavily_api_key),
        "has_admin_key": bool(settings.backend_admin_key),
        "firebase_credential_source": cred_source,
        "firebase_initialized": bool(firebase_admin._apps),
    }


@app.on_event("startup")
def _log_config() -> None:
    cred_source = (
        "service_account_env"
        if settings.firebase_service_account_json
        else ("credentials_file" if settings.google_application_credentials else "none")
    )
    logger.info(
        "startup ok | model=%s gemini=%s tavily=%s admin_key=%s firebase=%s",
        settings.llm_model,
        bool(settings.gemini_api_key),
        bool(settings.tavily_api_key),
        bool(settings.backend_admin_key),
        cred_source,
    )
