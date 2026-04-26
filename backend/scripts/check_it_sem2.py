"""Targeted check: are there resources for IT branch, semester 2?

Checks Firestore Universities/ tree for any branch whose name looks like IT
(matches: IT, I.T., INFORMATION TECHNOLOGY, etc.), then for sem == "2",
counts resource docs and verifies each storageId points to a real
Storage blob.

Usage (from backend/):
    uv run python scripts/check_it_sem2.py
"""
import os
import sys
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

# Storage blob IDs (under Universities/uni/course/branch/{id})
print("[1/2] Listing Storage blobs ...", flush=True)
storage_ids = set()
for blob in bucket.list_blobs(prefix="Universities/"):
    parts = blob.name.split("/")
    if len(parts) == 5:
        storage_ids.add(parts[4])
print(f"      found {len(storage_ids)} blobs under expected layout", flush=True)

print("\n[2/2] Walking Firestore for IT-like branches ...", flush=True)


def looks_like_it(name: str) -> bool:
    n = name.strip().upper().replace(".", "").replace(" ", "")
    return n == "IT" or n == "INFORMATIONTECHNOLOGY"


found_any = False
for uni_ref in db.collection("Universities").list_documents():
    uni = uni_ref.id
    for course_col in uni_ref.collections():
        course = course_col.id
        for branch_ref in course_col.list_documents():
            branch = branch_ref.id
            if not looks_like_it(branch):
                continue
            print(f"\n--- Branch match: {uni}/{course}/{branch} ---", flush=True)
            for sem_col in branch_ref.collections():
                sem = sem_col.id
                if str(sem) != "2":
                    continue
                print(f"  Sem 2 found at {uni}/{course}/{branch}/{sem}")
                found_any = True
                for type_ref in sem_col.list_documents():
                    rtype = type_ref.id
                    if rtype == "SubjectsList":
                        continue
                    for subject_col in type_ref.collections():
                        subject = subject_col.id
                        live = 0
                        broken = 0
                        no_field = 0
                        for doc in subject_col.stream():
                            data = doc.to_dict() or {}
                            sid = data.get("storageId")
                            if not sid:
                                no_field += 1
                            elif sid in storage_ids:
                                live += 1
                            else:
                                broken += 1
                        if live or broken or no_field:
                            bits = []
                            if live:
                                bits.append(f"{live} LIVE")
                            if broken:
                                bits.append(f"{broken} broken (storageId not in Storage)")
                            if no_field:
                                bits.append(f"{no_field} no storageId field")
                            print(f"    {rtype}/{subject}: {', '.join(bits)}")

if not found_any:
    print("\nNo IT branch with sem 2 found in Firestore.")
else:
    print("\nDone. 'LIVE' = doc has storageId pointing to a real Storage blob (app will display it).")
