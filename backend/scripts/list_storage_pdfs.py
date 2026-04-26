"""One-off: enumerate Firebase Storage and report which (uni, course, branch,
sem) combinations actually contain PDF files (not Firestore metadata, the
actual binaries the app downloads).

Usage (from backend/):
    uv run python scripts/list_storage_pdfs.py
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
from firebase_admin import storage  # noqa: E402

if not firebase_admin._apps:
    firebase_admin.initialize_app(
        options={"storageBucket": settings.backend_storage_bucket}
    )

bucket = storage.bucket()

# Expected Storage path:
#   Universities/{university}/{course}/{branch}/{sem}/{subject}/{category}/{filename}.pdf

counts = defaultdict(int)            # (uni, course, branch, sem) -> total pdfs
breakdown = defaultdict(lambda: defaultdict(int))  # ... -> {category: count}
subjects_by_combo = defaultdict(set)  # ... -> set of subjects

other_paths = []  # things that don't match the expected layout

print(f"Listing bucket: {bucket.name}")
print("Walking Universities/ ...\n")

total_blobs = 0
for blob in bucket.list_blobs(prefix="Universities/"):
    total_blobs += 1
    parts = blob.name.split("/")
    # Expect: ['Universities', uni, course, branch, sem, subject, category, filename]
    if len(parts) < 8 or not blob.name.lower().endswith(".pdf"):
        if len(parts) > 1 and not blob.name.endswith("/"):
            other_paths.append(blob.name)
        continue
    uni, course, branch, sem, subject, category = parts[1:7]
    key = (uni, course, branch, sem)
    counts[key] += 1
    breakdown[key][category] += 1
    subjects_by_combo[key].add(subject)

if not counts:
    print("\nNo PDFs found under Universities/ prefix.")
    if other_paths:
        print(f"\nFound {len(other_paths)} non-matching paths. Sample:")
        for p in other_paths[:10]:
            print(f"  {p}")
    sys.exit(0)

print("=== PDF counts in Firebase Storage by (university, course, branch, sem) ===\n")
for key in sorted(counts.keys()):
    uni, course, branch, sem = key
    total = counts[key]
    cats = breakdown[key]
    cat_str = ", ".join(f"{c}: {n}" for c, n in sorted(cats.items()))
    subjects = sorted(subjects_by_combo[key])
    print(f"  {uni} / {course} / {branch} / sem {sem}")
    print(f"    → {total} PDFs  ({cat_str})")
    print(f"    → {len(subjects)} subject(s): {', '.join(subjects)}")
    print()

print(f"Total (uni, course, branch, sem) combinations with PDFs: {len(counts)}")
print(f"Total PDF files: {sum(counts.values())}")
print(f"Total blobs scanned under Universities/: {total_blobs}")

if other_paths:
    print(f"\nNote: {len(other_paths)} object(s) under Universities/ didn't match the expected path layout. Sample:")
    for p in other_paths[:5]:
        print(f"  {p}")
