"""For the 5 combos with gaps, list every PDF on disk under that sem and
its relative path — then mark which ones uploaded and which didn't.
"""
import os
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.settings import settings  # noqa
if settings.google_application_credentials and not os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"):
    cred_path = settings.google_application_credentials
    if not os.path.isabs(cred_path):
        cred_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", cred_path))
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = cred_path

import firebase_admin  # noqa
from firebase_admin import storage  # noqa
if not firebase_admin._apps:
    firebase_admin.initialize_app(options={"storageBucket": settings.backend_storage_bucket})

DRIVE_ROOT = Path("E:/Academic Ally Complete Drive/NOTES/OU/B.E")
BRANCH_MAP = {
    "CIVIL": "CIVIL", "CSE": "CSE", "CSE AIML": "CSE AIML", "CSE IoT": "CSE IOT",
    "ECE": "ECE", "EEE": "EEE", "IT": "IT", "MECH": "MECH",
}
INVERSE_BRANCH_MAP = {v: k for k, v in BRANCH_MAP.items()}

# (fs_branch, sem)
GAP_COMBOS = [
    ("CSE", "6"),
    ("IT", "3"),
    ("IT", "4"),
    ("IT", "6"),
    ("IT", "7"),
]

bucket = storage.bucket()

for fs_branch, sem in GAP_COMBOS:
    drive_branch = INVERSE_BRANCH_MAP[fs_branch]
    sem_path = DRIVE_ROOT / drive_branch / sem
    print()
    print("=" * 75)
    print(f"{fs_branch} / sem {sem}   drive folder: {sem_path}")
    print("=" * 75)

    # All PDFs on disk under sem_path
    drive_files = []
    for pdf in sem_path.rglob("*.pdf"):
        rel = pdf.relative_to(sem_path).as_posix()
        drive_files.append((pdf.name, rel))
    print(f"  Drive: {len(drive_files)} PDFs under {sem_path.name}/")

    # Which filenames are present in Storage for this (branch, sem)?
    prefix = f"Resources/OU/BE/{fs_branch}/{sem}/"
    uploaded_names = set()
    for blob in bucket.list_blobs(prefix=prefix):
        uploaded_names.add(blob.name.split("/")[-1])
    print(f"  Storage: {len(uploaded_names)} blobs under {prefix}")

    # Missing = drive files whose filename is not in uploaded_names
    # (note: this is fuzzy — could give false matches if filenames repeat,
    # but for first-pass triage it's good enough)
    missing = [(name, rel) for name, rel in drive_files if name not in uploaded_names]
    print(f"  Drive-only filenames (NOT uploaded): {len(missing)}")
    for name, rel in missing[:40]:
        print(f"    {rel}")
    if len(missing) > 40:
        print(f"    ... and {len(missing) - 40} more")
