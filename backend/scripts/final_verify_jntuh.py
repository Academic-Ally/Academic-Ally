"""Final verification for JNTUH/BTECH — mirrors final_verify_ou.py.
Counts drive PDFs (top + nested) vs Storage blobs vs Firestore docs per
(branch, sem).
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
from firebase_admin import firestore, storage  # noqa
if not firebase_admin._apps:
    firebase_admin.initialize_app(options={"storageBucket": settings.backend_storage_bucket})

UNIVERSITY = "JNTUH"
COURSE = "BTECH"
DRIVE_ROOT = Path("E:/Academic Ally Complete Drive/NOTES/JNTUH/BTECH")
BRANCHES = [
    "AER", "CIVIL", "CSE",
    "CSE(AI and ML)", "CSE(Cyber Security)", "CSE(Data Science)", "CSE(IOT)",
    "CSE(Non-Autonomous)", "ECE", "EEE", "IT", "MECH",
]
IGNORE = {"desktop.ini", ".DS_Store", "Thumbs.db"}


def count_drive_pdfs():
    counts = defaultdict(int)
    for branch in BRANCHES:
        bdir = DRIVE_ROOT / branch
        if not bdir.is_dir():
            continue
        # Top-level
        for sub in bdir.iterdir():
            if not sub.is_dir() or sub.name in IGNORE:
                continue
            if sub.name.isdigit():
                n = sum(1 for _ in sub.rglob("*.pdf"))
                counts[(branch, sub.name)] += n
        # Nested
        nested = bdir / branch
        if nested.is_dir():
            for sub in nested.iterdir():
                if not sub.is_dir() or sub.name in IGNORE:
                    continue
                if sub.name.isdigit():
                    n = sum(1 for _ in sub.rglob("*.pdf"))
                    counts[(branch, sub.name)] += n
    return counts


def count_storage_blobs():
    bucket = storage.bucket()
    counts = defaultdict(int)
    prefix = f"Resources/{UNIVERSITY}/{COURSE}/"
    for blob in bucket.list_blobs(prefix=prefix):
        parts = blob.name.split("/")
        if len(parts) < 5:
            continue
        branch, sem = parts[3], parts[4]
        counts[(branch, sem)] += 1
    return counts


def count_firestore_docs():
    db = firestore.client()
    counts = defaultdict(int)
    uni_ref = db.document(f"Universities/{UNIVERSITY}")
    for course_col in uni_ref.collections():
        if course_col.id != COURSE:
            continue
        for branch_ref in course_col.list_documents():
            for sem_col in branch_ref.collections():
                for type_ref in sem_col.list_documents():
                    if type_ref.id == "SubjectsList":
                        continue
                    for subject_col in type_ref.collections():
                        for doc in subject_col.stream():
                            sid = (doc.to_dict() or {}).get("storageId")
                            if sid:
                                counts[(branch_ref.id, sem_col.id)] += 1
    return counts


def main():
    print("=" * 75)
    print(f"FINAL VERIFICATION — {UNIVERSITY}/{COURSE}")
    print("=" * 75)

    print("[1/3] Counting drive PDFs ...", flush=True)
    drive = count_drive_pdfs()
    print(f"  -> {len(drive)} combos, {sum(drive.values())} PDFs")

    print("[2/3] Counting Storage blobs ...", flush=True)
    sc = count_storage_blobs()
    print(f"  -> {len(sc)} combos, {sum(sc.values())} blobs")

    print("[3/3] Counting Firestore docs ...", flush=True)
    fc = count_firestore_docs()
    print(f"  -> {len(fc)} combos, {sum(fc.values())} docs")

    print()
    print("=" * 75)
    print("PER-COMBO COMPARISON")
    print("=" * 75)
    all_keys = sorted(set(drive) | set(sc) | set(fc))
    print(f"  {'branch':25s}  {'sem':>3s}  {'drive':>5s}  {'storage':>7s}  {'firestore':>9s}  status")
    gaps = []
    parity = []
    for key in all_keys:
        branch, sem = key
        d = drive.get(key, 0)
        s = sc.get(key, 0)
        f = fc.get(key, 0)
        if d == 0 and s == 0 and f == 0:
            continue
        if d == s == f:
            status = "OK"
        elif s > d:
            status = f"STORAGE>{d-s if d-s>0 else s-d}"
            parity.append(key)
        elif s < d:
            status = f"GAP: {d-s} missing"
            gaps.append((key, d, s, f))
        elif s != f:
            status = f"S/F mismatch ({s-f})"
            parity.append(key)
        else:
            status = "?"
        print(f"  {branch:25s}  {sem:>3s}  {d:>5d}  {s:>7d}  {f:>9d}  {status}")

    print()
    print("=" * 75)
    print("VERDICT")
    print("=" * 75)
    if not gaps and not parity:
        print("  ALL OK — every (branch, sem) has drive == storage == firestore counts.")
    else:
        if gaps:
            print(f"  {len(gaps)} combo(s) with missing uploads:")
            for (branch, sem), d, s, f in gaps:
                print(f"    {branch}/sem {sem}: drive={d}, storage={s}  -> {d-s} missing")
        if parity:
            print(f"  {len(parity)} parity issue(s)")


if __name__ == "__main__":
    main()
