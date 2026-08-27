"""Inspect the legacy/stray prefixes in Firebase Storage and check whether
any Firestore doc still references those blobs via storageId.

Prefixes audited:
  Universities/       (~82 MB, RN-era community uploads)
  OU/                 (~29 MB, stray legacy)
  JNTUH/              (~19 MB, stray legacy)
  2023-07-05T03:50:23_34529/  (~4 MB, dated dump)

For each: list a sample of blob names, and search Firestore broadly for
docs whose storageId is in that prefix.
"""
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.settings import settings  # noqa
if settings.google_application_credentials and not os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"):
    cred_path = settings.google_application_credentials
    if not os.path.isabs(cred_path):
        cred_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", cred_path))
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = cred_path

import firebase_admin  # noqa
from firebase_admin import firestore, storage  # noqa
if not firebase_admin._apps:
    firebase_admin.initialize_app(options={"storageBucket": settings.backend_storage_bucket})

bucket = storage.bucket()
db = firestore.client()

STRAY_PREFIXES = [
    "Universities/",
    "OU/",
    "JNTUH/",
    "2023-07-05T03:50:23_34529/",
]

print("Step 1 — Sample blob names per stray prefix")
print("=" * 70)
all_blob_names = {}
for prefix in STRAY_PREFIXES:
    blobs = list(bucket.list_blobs(prefix=prefix))
    all_blob_names[prefix] = {b.name for b in blobs}
    print(f"\n[{prefix}]  {len(blobs)} blob(s)")
    for b in blobs[:5]:
        print(f"  - {b.name}  ({(b.size or 0) / 1024:.1f} KB)")
    if len(blobs) > 5:
        print(f"  ... +{len(blobs) - 5} more")

print()
print("Step 2 — Search ALL Firestore docs for storageId pointing into these prefixes")
print("=" * 70)
# Walk every collection that might hold resource docs. The app's main
# resource tree is Universities/. SeekHub, Premium_Users, etc. don't carry
# storageId. So we focus on Universities/{uni}/{course}/{branch}/{sem}/{type}/{subject}/...

referenced_by_fs = {p: [] for p in STRAY_PREFIXES}

for uni_ref in db.collection("Universities").list_documents():
    for course_col in uni_ref.collections():
        for branch_ref in course_col.list_documents():
            for sem_col in branch_ref.collections():
                for type_ref in sem_col.list_documents():
                    if type_ref.id == "SubjectsList":
                        continue
                    for subject_col in type_ref.collections():
                        for doc in subject_col.stream():
                            sid = (doc.to_dict() or {}).get("storageId")
                            if not sid:
                                continue
                            for prefix in STRAY_PREFIXES:
                                if sid.startswith(prefix) and not sid.startswith("Resources/"):
                                    referenced_by_fs[prefix].append((doc.reference.path, sid))
                                    break

for prefix in STRAY_PREFIXES:
    refs = referenced_by_fs[prefix]
    blob_count = len(all_blob_names[prefix])
    print(f"\n[{prefix}]  blobs={blob_count}  firestore refs={len(refs)}")
    if refs:
        for path, sid in refs[:5]:
            print(f"  doc {path}")
            print(f"    storageId={sid}")
        if len(refs) > 5:
            print(f"  ... +{len(refs) - 5} more")

print()
print("Step 3 — Verdict")
print("=" * 70)
for prefix in STRAY_PREFIXES:
    refs = referenced_by_fs[prefix]
    blob_count = len(all_blob_names[prefix])
    if not refs:
        print(f"  {prefix:30s}  SAFE TO DELETE  ({blob_count} blobs, no Firestore refs)")
    else:
        print(f"  {prefix:30s}  KEEP            ({blob_count} blobs, referenced by {len(refs)} doc(s))")
