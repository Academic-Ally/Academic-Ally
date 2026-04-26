"""One-off: enumerate the Universities/ tree and report which (uni, course,
branch, sem) combinations actually contain resource documents.

Usage (from backend/):
    uv run python scripts/list_resources.py
"""
import os
import sys
from collections import defaultdict
from pathlib import Path

# Bootstrap settings + firebase-admin the same way main.py does.
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

# Path: Universities/{uni}/{course}/{branch}/{sem}/{type}/{subject}/{docId}
# Alternating col/doc/col/doc...

counts = defaultdict(int)  # (uni, course, branch, sem) -> total resource docs
breakdown = defaultdict(lambda: defaultdict(int))  # (uni,course,branch,sem) -> {type: count}

print("Walking Universities/ ... (using list_documents to handle missing parents)")

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
                        try:
                            n = sum(1 for _ in subject_col.list_documents())
                        except Exception as e:
                            print(f"  err counting {uni}/{course}/{branch}/{sem}/{rtype}/{subject}: {e}")
                            continue
                        if n > 0:
                            counts[(uni, course, branch, sem)] += n
                            breakdown[(uni, course, branch, sem)][rtype] += n

if not counts:
    print("\nNo resource documents found anywhere under Universities/.")
    sys.exit(0)

print("\n=== Resource counts by (university, course, branch, sem) ===\n")
for key in sorted(counts.keys()):
    uni, course, branch, sem = key
    total = counts[key]
    types = breakdown[key]
    type_str = ", ".join(f"{t}: {n}" for t, n in sorted(types.items()))
    print(f"  {uni} / {course} / {branch} / sem {sem}  →  {total} resources  ({type_str})")

print(f"\nTotal (uni, course, branch, sem) combinations with resources: {len(counts)}")
print(f"Total resource documents: {sum(counts.values())}")
