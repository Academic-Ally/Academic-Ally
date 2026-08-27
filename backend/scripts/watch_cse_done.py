"""Polls Firebase Storage every 10 min and exits when all 8 sems of
OU/BE/CSE are present under Resources/. Prints a status line each time a
new CSE sem first appears so the parent process gets progress events too.

Used as a background task: when it exits, the harness fires a completion
notification.
"""
import os
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.settings import settings  # noqa: E402

if settings.google_application_credentials and not os.environ.get(
    "GOOGLE_APPLICATION_CREDENTIALS"
):
    cred_path = settings.google_application_credentials
    if not os.path.isabs(cred_path):
        cred_path = os.path.abspath(
            os.path.join(os.path.dirname(__file__), "..", cred_path)
        )
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = cred_path

import firebase_admin  # noqa: E402
from firebase_admin import storage  # noqa: E402

if not firebase_admin._apps:
    firebase_admin.initialize_app(
        options={"storageBucket": settings.backend_storage_bucket}
    )

bucket = storage.bucket()
prefix = "Resources/OU/BE/CSE/"

seen = set()
while True:
    cur = set()
    files_per_sem = {}
    for blob in bucket.list_blobs(prefix=prefix):
        parts = blob.name.split("/")
        if len(parts) >= 5 and parts[4]:
            sem = parts[4]
            cur.add(sem)
            files_per_sem[sem] = files_per_sem.get(sem, 0) + 1

    new = cur - seen
    if new:
        for sem in sorted(new):
            print(
                f"[watch] CSE/sem {sem} now present "
                f"({files_per_sem.get(sem, 0)} files) — {len(cur)}/8 sems done",
                flush=True,
            )
        seen = cur

    if len(cur) >= 8:
        print(
            f"[watch] DONE — all 8 CSE sems present in bucket. "
            f"Files per sem: {sorted(files_per_sem.items())}",
            flush=True,
        )
        break

    time.sleep(600)  # 10 min
