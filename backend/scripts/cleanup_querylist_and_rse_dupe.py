"""Cleanup tasks after the OU bulk upload:

1. Delete orphan Storage blobs at:
     Resources/OU/BE/IT/8/{Notes,OtherResources,QuestionPapers,Syllabus}/Road Safety Engineering (1)/*
   These got uploaded under the typo subject name during the bulk run.
   The canonical name "Road Safety Engineering" now holds the same files.

2. Delete corresponding Firestore docs under:
     Universities/OU/BE/IT/8/{cat}/Road Safety Engineering (1)/*

3. Update QueryList/OU/BE/SubjectsListDetail.list:
     a) CIVIL/sem 6: "Professional Practice and Ethics" -> "Professional Practice & Ethics"
        (match drive/Storage path which uses ampersand)
     b) IT/sem 7: remove "Cryptography and Network Security" entry
        (those notes are at IT/sem 8 where they belong; the sem 7 entry is stray)
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

# ---------------------------------------------------------------------------
# 1. Delete orphan Storage blobs for RSE(1)
# ---------------------------------------------------------------------------
print("=" * 70)
print("[1] Storage cleanup — Road Safety Engineering (1) orphan blobs")
print("=" * 70)
orphan_prefix = "Resources/OU/BE/IT/8/"
orphan_subject = "Road Safety Engineering (1)"
deleted_blobs = 0
for blob in bucket.list_blobs(prefix=orphan_prefix):
    parts = blob.name.split("/")
    # Resources/OU/BE/IT/8/{category}/{subject}/{filename}
    if len(parts) >= 7 and parts[6] == orphan_subject:
        print(f"  delete: {blob.name}")
        blob.delete()
        deleted_blobs += 1
print(f"  -> {deleted_blobs} blob(s) deleted")

# ---------------------------------------------------------------------------
# 2. Delete corresponding Firestore docs
# ---------------------------------------------------------------------------
print()
print("=" * 70)
print("[2] Firestore cleanup — Road Safety Engineering (1) docs")
print("=" * 70)
deleted_docs = 0
for category in ("Notes", "OtherResources", "QuestionPapers", "Syllabus"):
    coll_path = (
        f"Universities/OU/BE/IT/8/{category}/{orphan_subject}"
    )
    for doc in db.collection(coll_path).stream():
        print(f"  delete: {coll_path}/{doc.id}")
        doc.reference.delete()
        deleted_docs += 1
print(f"  -> {deleted_docs} doc(s) deleted")

# ---------------------------------------------------------------------------
# 3. Update QueryList
# ---------------------------------------------------------------------------
print()
print("=" * 70)
print("[3] QueryList edits — OU/BE/SubjectsListDetail")
print("=" * 70)
ql_ref = db.document("QueryList/OU/BE/SubjectsListDetail")
ql_snap = ql_ref.get()
items = (ql_snap.to_dict() or {}).get("list", [])
print(f"  Loaded {len(items)} entries")

before_count = len(items)
edits = 0

new_items = []
for item in items:
    if not isinstance(item, dict):
        new_items.append(item)
        continue
    b = str(item.get("branch", "")).strip()
    s = str(item.get("sem", "")).strip()
    name = item.get("subject") or item.get("subjectName") or ""

    # 3a: CIVIL/sem 6 rename
    if b == "CIVIL" and s == "6" and name == "Professional Practice and Ethics":
        new_item = dict(item)
        if "subject" in new_item:
            new_item["subject"] = "Professional Practice & Ethics"
        if "subjectName" in new_item:
            new_item["subjectName"] = "Professional Practice & Ethics"
        new_items.append(new_item)
        edits += 1
        print(f"  EDIT: CIVIL/sem 6  '{name}' -> 'Professional Practice & Ethics'")
        continue

    # 3b: IT/sem 7 — remove the stray Cryptography entry
    if b == "IT" and s == "7" and name == "Cryptography and Network Security":
        print(f"  REMOVE: IT/sem 7  '{name}'  (content is at IT/sem 8)")
        edits += 1
        continue  # don't append

    new_items.append(item)

after_count = len(new_items)
print(f"  Edits applied: {edits}")
print(f"  Entry count: {before_count} -> {after_count}")

if edits:
    ql_ref.update({"list": new_items})
    print("  -> QueryList updated.")
else:
    print("  -> No changes needed.")

print()
print("=" * 70)
print("CLEANUP COMPLETE")
print("=" * 70)
print(f"  Blobs deleted:    {deleted_blobs}")
print(f"  Firestore docs:   {deleted_docs}")
print(f"  QueryList edits:  {edits}")
