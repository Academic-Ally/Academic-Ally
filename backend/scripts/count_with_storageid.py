"""Audit: for every (uni, course, branch, sem, type) under Universities/,
count how many resource docs have a non-empty `storageId` (i.e. how many
the released APK will ACTUALLY render — the resourcesProvider filter
drops the rest).

Run from backend/:
    uv run python scripts/count_with_storageid.py
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
from firebase_admin import firestore  # noqa: E402

if not firebase_admin._apps:
    firebase_admin.initialize_app(
        options={"storageBucket": settings.backend_storage_bucket}
    )

db = firestore.client()

with_sid = defaultdict(int)        # (uni,course,branch,sem) -> docs with storageId
without_sid = defaultdict(int)     # ... -> docs missing storageId (legacy)
type_with_sid = defaultdict(lambda: defaultdict(int))  # ... -> {type: count}
subjects_with_sid = defaultdict(lambda: defaultdict(set))  # (key, type) -> {subjects}

print("Walking Universities/ and checking storageId on each doc ...")

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
                            if sid:
                                with_sid[key] += 1
                                type_with_sid[key][rtype] += 1
                                subjects_with_sid[(key, rtype)].add(subject)
                            else:
                                without_sid[key] += 1

print()
print("=" * 80)
print("RESOURCES THE APP WILL ACTUALLY SHOW (docs with non-empty storageId)")
print("=" * 80)
if not with_sid:
    print("  (none)")
else:
    for key in sorted(with_sid.keys()):
        uni, course, branch, sem = key
        total = with_sid[key]
        cats = type_with_sid[key]
        cat_str = ", ".join(f"{c}: {v}" for c, v in sorted(cats.items()))
        print(f"\n  {uni} / {course} / {branch} / sem {sem}  -- {total} docs ({cat_str})")
        for rtype in sorted(cats.keys()):
            subs = sorted(subjects_with_sid[(key, rtype)])
            print(f"      {rtype}: {len(subs)} subj -- {', '.join(subs)}")

print()
print("=" * 80)
print("SUMMARY")
print("=" * 80)
total_visible = sum(with_sid.values())
total_legacy = sum(without_sid.values())
print(f"  Visible-to-app docs (storageId present):  {total_visible}")
print(f"  Legacy docs (no storageId, filtered out): {total_legacy}")
print(f"  Distinct (uni,course,branch,sem) visible: {len(with_sid)}")
