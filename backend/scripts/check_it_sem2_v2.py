"""Corrected audit for IT branch sem 2.

Treats storageId as a full Storage path (matches what
PdfViewerScreen does: FirebaseStorage.instance.ref(storageId)).
Collects EVERY blob name in the bucket, then checks each Firestore
doc's storageId against that complete set.
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

print("[1/3] Listing ALL blobs in bucket (full paths) ...", flush=True)
all_blob_names = set()
total_bytes = 0
for blob in bucket.list_blobs():
    all_blob_names.add(blob.name)
    total_bytes += blob.size or 0
print(f"      total blobs: {len(all_blob_names)}, {total_bytes / 1024 / 1024:.1f} MB", flush=True)

# Show a few samples to learn the actual layout
print("\n[2/3] Sample of blob paths to learn layout:", flush=True)
sample_under_universities = sorted(
    [n for n in all_blob_names if n.startswith("Universities/")]
)[:30]
for s in sample_under_universities:
    print(f"  {s}")
print(f"  ... ({sum(1 for n in all_blob_names if n.startswith('Universities/'))} total under Universities/)")

print("\n[3/3] Walking IT/sem-2 in Firestore and probing each storageId ...", flush=True)


def looks_like_it(name: str) -> bool:
    n = name.strip().upper().replace(".", "").replace(" ", "")
    return n in {"IT", "INFORMATIONTECHNOLOGY"}


found_any = False
for uni_ref in db.collection("Universities").list_documents():
    uni = uni_ref.id
    for course_col in uni_ref.collections():
        course = course_col.id
        for branch_ref in course_col.list_documents():
            branch = branch_ref.id
            if not looks_like_it(branch):
                continue
            for sem_col in branch_ref.collections():
                sem = sem_col.id
                if str(sem) != "2":
                    continue
                found_any = True
                print(f"\n=== {uni}/{course}/{branch}/sem {sem} ===")
                for type_ref in sem_col.list_documents():
                    rtype = type_ref.id
                    if rtype == "SubjectsList":
                        continue
                    for subject_col in type_ref.collections():
                        subject = subject_col.id
                        live = 0
                        broken = []
                        no_field = 0
                        sample_storage_id = None
                        for doc in subject_col.stream():
                            data = doc.to_dict() or {}
                            sid = data.get("storageId")
                            if not sid:
                                no_field += 1
                            else:
                                if sample_storage_id is None:
                                    sample_storage_id = sid
                                if sid in all_blob_names:
                                    live += 1
                                else:
                                    broken.append(sid)
                        if live or broken or no_field:
                            print(f"  {rtype}/{subject}:")
                            print(f"    LIVE   = {live}")
                            print(f"    broken = {len(broken)}")
                            print(f"    no storageId field = {no_field}")
                            if sample_storage_id:
                                print(f"    sample storageId: {sample_storage_id!r}")
                            if broken[:1]:
                                print(f"    sample BROKEN storageId: {broken[0]!r}")

if not found_any:
    print("No IT/sem-2 found in Firestore.")
