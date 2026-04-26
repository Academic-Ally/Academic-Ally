"""Cross-reference Firebase Storage blobs with Firestore resource docs to
report which (uni, course, branch, sem) combinations actually have PDFs the
app can resolve.

Storage layout observed:
  Universities/{uni}/{course}/{branch}/{storageId}     (no sem in path)

Firestore layout:
  Universities/{uni}/{course}/{branch}/{sem}/{type}/{subject}/{docId}
  (each docId has a `storageId` field pointing into Storage)

Usage (from backend/):
    uv run python scripts/storage_audit.py
"""
import os
import sys
from collections import defaultdict
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
from firebase_admin import firestore, storage  # noqa: E402

if not firebase_admin._apps:
    firebase_admin.initialize_app(
        options={"storageBucket": settings.backend_storage_bucket}
    )

db = firestore.client()
bucket = storage.bucket()

# ---------------------------------------------------------------------------
# Pass 1 — index Storage
# ---------------------------------------------------------------------------
print(f"[1/2] Listing Storage bucket: {bucket.name}")
storage_ids = set()                       # all blob IDs found
storage_by_branch = defaultdict(int)      # (uni, course, branch) -> count
total_bytes = 0
total_blobs = 0
for blob in bucket.list_blobs(prefix="Universities/"):
    total_blobs += 1
    parts = blob.name.split("/")
    if len(parts) != 5:
        continue  # skip anything not matching Universities/uni/course/branch/id
    _, uni, course, branch, blob_id = parts
    storage_ids.add(blob_id)
    storage_by_branch[(uni, course, branch)] += 1
    total_bytes += blob.size or 0

print(f"      → {total_blobs} blobs, {total_bytes / 1024 / 1024:.1f} MB total")
print(f"      → {len(storage_ids)} distinct blob IDs under expected layout\n")

# ---------------------------------------------------------------------------
# Pass 2 — walk Firestore, count docs whose storageId exists in Storage
# ---------------------------------------------------------------------------
print("[2/2] Walking Firestore Universities/ tree ...\n")

with_blob = defaultdict(int)              # (uni, course, branch, sem) -> docs that point at real blob
without_blob = defaultdict(int)           # (uni, course, branch, sem) -> docs missing a blob (legacy/Drive)
no_storage_id_field = defaultdict(int)
type_breakdown = defaultdict(lambda: defaultdict(int))   # ... -> {type: count}
subjects_with_blob = defaultdict(set)     # ... -> set of subjects with at least 1 real PDF

for uni_ref in db.collection("Universities").list_documents():
    uni = uni_ref.id
    for course_col in uni_ref.collections():
        course = course_col.id
        for branch_ref in course_col.list_documents():
            branch = branch_ref.id
            for sem_col in branch_ref.collections():
                sem = sem_col.id
                for type_ref in sem_col.list_documents():
                    rtype = type_ref.id
                    if rtype == "SubjectsList":
                        continue
                    for subject_col in type_ref.collections():
                        subject = subject_col.id
                        for doc in subject_col.stream():
                            data = doc.to_dict() or {}
                            sid = data.get("storageId")
                            key = (uni, course, branch, sem)
                            if not sid:
                                no_storage_id_field[key] += 1
                            elif sid in storage_ids:
                                with_blob[key] += 1
                                type_breakdown[key][rtype] += 1
                                subjects_with_blob[key].add(subject)
                            else:
                                without_blob[key] += 1

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
print("=" * 70)
print("RESOURCES BACKED BY A REAL STORAGE BLOB (what the app actually shows)")
print("=" * 70)
if not with_blob:
    print("  (none)")
else:
    for key in sorted(with_blob.keys()):
        uni, course, branch, sem = key
        n = with_blob[key]
        cats = type_breakdown[key]
        cat_str = ", ".join(f"{c}: {v}" for c, v in sorted(cats.items()))
        subjects = sorted(subjects_with_blob[key])
        print(f"\n  {uni} / {course} / {branch} / sem {sem}")
        print(f"    → {n} resources  ({cat_str})")
        print(f"    → {len(subjects)} subject(s) with PDFs: {', '.join(subjects)}")

print("\n" + "=" * 70)
print("LEGACY / BROKEN — Firestore doc exists but storageId blob missing")
print("(these were RN-era Google Drive links; app filters them out)")
print("=" * 70)
total_legacy = sum(without_blob.values()) + sum(no_storage_id_field.values())
if total_legacy == 0:
    print("  (none)")
else:
    for key in sorted(set(without_blob.keys()) | set(no_storage_id_field.keys())):
        uni, course, branch, sem = key
        a = without_blob.get(key, 0)
        b = no_storage_id_field.get(key, 0)
        bits = []
        if a:
            bits.append(f"{a} with stale storageId")
        if b:
            bits.append(f"{b} with no storageId field")
        print(f"  {uni} / {course} / {branch} / sem {sem}  →  {' + '.join(bits)}")

print("\n" + "=" * 70)
print("STORAGE BLOBS BY BRANCH (raw, no sem info available from path)")
print("=" * 70)
for key in sorted(storage_by_branch.keys()):
    uni, course, branch = key
    print(f"  {uni} / {course} / {branch}  →  {storage_by_branch[key]} blobs")

print("\n" + "=" * 70)
print("SUMMARY")
print("=" * 70)
print(f"  Storage blobs (Universities/ prefix):        {total_blobs}")
print(f"  Distinct (uni,course,branch,sem) with PDFs:  {len(with_blob)}")
print(f"  Total resolvable resources:                  {sum(with_blob.values())}")
print(f"  Legacy/orphan resource docs:                 {total_legacy}")
