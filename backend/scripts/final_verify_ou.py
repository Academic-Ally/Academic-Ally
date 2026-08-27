"""Final verification for the OU/B.E upload run.

For every (branch, sem) we expected to upload:
  1. Count PDFs on drive (top-level + nested subfolders mapped to same target)
  2. Count blobs in Firebase Storage at Resources/OU/BE/{branch}/{sem}/
  3. Count Firestore docs at Universities/OU/BE/{branch}/{sem}/.../ with storageId
  4. Flag mismatches

Run from backend/:
    uv run python scripts/final_verify_ou.py
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

UNIVERSITY = "OU"
COURSE = "BE"
DRIVE_ROOT = Path("E:/Academic Ally Complete Drive/NOTES/OU/B.E")

BRANCH_MAP = {
    "CIVIL": "CIVIL",
    "CSE": "CSE",
    "CSE AIML": "CSE AIML",
    "CSE IoT": "CSE IOT",
    "ECE": "ECE",
    "EEE": "EEE",
    "IT": "IT",
    "MECH": "MECH",
}
IGNORE_DIRS = {"desktop.ini", ".DS_Store", "Thumbs.db"}


def count_drive_pdfs():
    """Returns dict {(fs_branch, sem) -> pdf_count} across top + nested."""
    counts = defaultdict(int)
    for drive_branch, fs_branch in BRANCH_MAP.items():
        bdir = DRIVE_ROOT / drive_branch
        if not bdir.is_dir():
            continue
        # Top-level sem folders
        for sub in bdir.iterdir():
            if not sub.is_dir() or sub.name in IGNORE_DIRS:
                continue
            if sub.name.isdigit():
                n = sum(1 for p in sub.rglob("*.pdf"))
                counts[(fs_branch, sub.name)] += n
        # Nested same-name folder, sems inside
        nested = bdir / drive_branch
        if nested.is_dir():
            for sub in nested.iterdir():
                if not sub.is_dir() or sub.name in IGNORE_DIRS:
                    continue
                if sub.name.isdigit():
                    n = sum(1 for p in sub.rglob("*.pdf"))
                    counts[(fs_branch, sub.name)] += n
    return counts


def count_storage_blobs():
    """Returns dict {(branch, sem) -> blob_count} under Resources/OU/BE/..."""
    bucket = storage.bucket()
    counts = defaultdict(int)
    prefix = f"Resources/{UNIVERSITY}/{COURSE}/"
    for blob in bucket.list_blobs(prefix=prefix):
        parts = blob.name.split("/")
        # Resources / OU / BE / {branch} / {sem} / {category} / {subject} / {filename}
        if len(parts) < 5:
            continue
        branch, sem = parts[3], parts[4]
        counts[(branch, sem)] += 1
    return counts


def count_firestore_docs():
    """Returns dict {(branch, sem) -> doc_count} where storageId non-empty."""
    db = firestore.client()
    counts = defaultdict(int)
    uni_ref = db.document(f"Universities/{UNIVERSITY}")
    for course_col in uni_ref.collections():
        if course_col.id != COURSE:
            continue
        for branch_ref in course_col.list_documents():
            branch = branch_ref.id
            for sem_col in branch_ref.collections():
                sem = sem_col.id
                for type_ref in sem_col.list_documents():
                    rtype = type_ref.id
                    if rtype == "SubjectsList":
                        continue
                    for subject_col in type_ref.collections():
                        for doc in subject_col.stream():
                            data = doc.to_dict() or {}
                            sid = data.get("storageId")
                            if sid:
                                counts[(branch, sem)] += 1
    return counts


def main():
    print("=" * 75)
    print(f"FINAL VERIFICATION — {UNIVERSITY}/{COURSE}")
    print("=" * 75)

    print("[1/3] Counting drive PDFs (top + nested) ...")
    drive = count_drive_pdfs()
    print(f"  -> {len(drive)} (branch, sem) on drive, {sum(drive.values())} total PDFs")

    print("[2/3] Counting Storage blobs under Resources/OU/BE/ ...")
    storage_counts = count_storage_blobs()
    print(f"  -> {len(storage_counts)} (branch, sem) in Storage, {sum(storage_counts.values())} total blobs")

    print("[3/3] Counting Firestore docs with non-empty storageId ...")
    fs_counts = count_firestore_docs()
    print(f"  -> {len(fs_counts)} (branch, sem) in Firestore, {sum(fs_counts.values())} total docs")

    print()
    print("=" * 75)
    print("PER-COMBO COMPARISON")
    print("=" * 75)
    all_keys = sorted(set(drive) | set(storage_counts) | set(fs_counts))
    print(f"  {'branch':12s}  {'sem':>3s}  {'drive':>5s}  {'storage':>7s}  {'firestore':>9s}  status")
    print("  " + "-" * 65)
    gaps = []
    parity_issues = []
    for key in all_keys:
        branch, sem = key
        d = drive.get(key, 0)
        s = storage_counts.get(key, 0)
        f = fs_counts.get(key, 0)
        if d == 0 and s == 0 and f == 0:
            continue  # don't print fully empty combos
        if d == s == f:
            status = "OK"
        elif s > d:
            status = "STORAGE > DRIVE (?)"
            parity_issues.append(key)
        elif s < d:
            status = f"GAP: {d - s} missing"
            gaps.append((key, d, s, f))
        elif s != f:
            status = f"STORAGE/FS mismatch ({s - f})"
            parity_issues.append(key)
        else:
            status = "?"
        print(f"  {branch:12s}  {sem:>3s}  {d:>5d}  {s:>7d}  {f:>9d}  {status}")

    print()
    print("=" * 75)
    print("VERDICT")
    print("=" * 75)
    if not gaps and not parity_issues:
        print("  ALL OK — every (branch, sem) has drive == storage == firestore counts.")
    else:
        if gaps:
            print(f"  {len(gaps)} combo(s) with missing uploads:")
            for (branch, sem), d, s, f in gaps:
                print(f"    {branch}/sem {sem}: drive={d}, storage={s}  -> {d-s} PDFs missing")
        if parity_issues:
            print(f"  {len(parity_issues)} combo(s) with Storage/Firestore parity issues:")
            for branch, sem in parity_issues:
                d = drive.get((branch, sem), 0)
                s = storage_counts.get((branch, sem), 0)
                f = fs_counts.get((branch, sem), 0)
                print(f"    {branch}/sem {sem}: drive={d}, storage={s}, firestore={f}")


if __name__ == "__main__":
    main()
