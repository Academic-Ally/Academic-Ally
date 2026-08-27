"""Pre-flight: for a given (uni, course, branch, sem), compare the subject
folders on disk (E:\\...) against the subject names in Firestore's QueryList.
Reports exact matches, case-only mismatches, and items that exist on only one
side — so we know what to fix before running upload_pdfs.py.

Run from backend/:
    uv run python scripts/preflight_diff.py \
        --root "E:/Academic Ally Complete Drive/NOTES/OU/B.E/IT/3" \
        --university OU --course BE --branch IT --sem 3
"""
import argparse
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
from firebase_admin import firestore  # noqa: E402

if not firebase_admin._apps:
    firebase_admin.initialize_app(
        options={"storageBucket": settings.backend_storage_bucket}
    )


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True, help="Local folder of the sem (e.g. E:/.../IT/3)")
    ap.add_argument("--university", required=True)
    ap.add_argument("--course", required=True)
    ap.add_argument("--branch", required=True)
    ap.add_argument("--sem", required=True)
    args = ap.parse_args()

    root = Path(args.root)
    if not root.is_dir():
        print(f"[ERROR] Root path does not exist or is not a directory: {root}")
        sys.exit(1)

    # ---- Drive side ------------------------------------------------------
    drive_subjects = sorted(
        p.name for p in root.iterdir()
        if p.is_dir() and not p.name.startswith(".") and p.name != "desktop.ini"
    )
    print(f"\n[Drive] {len(drive_subjects)} subject folders under {root}:")
    for s in drive_subjects:
        print(f"  - {s}")

    # ---- QueryList side --------------------------------------------------
    # Schema: QueryList/{uni}/{course}/SubjectsListDetail is a single DOC with
    # field `list` = [ {branch, subject|subjectName, sem}, ... ]
    db = firestore.client()
    doc_path = f"QueryList/{args.university}/{args.course}/SubjectsListDetail"
    print(f"\n[Firestore] Reading {doc_path} ...")
    snap = db.document(doc_path).get()
    if not snap.exists:
        print(f"  [ERROR] Doc missing. Aborting.")
        sys.exit(2)
    data = snap.to_dict() or {}
    items = data.get("list") or []
    print(f"  -> {len(items)} total entries in the QueryList list field")

    ql_subjects = set()
    target_branch = args.branch.strip()
    target_sem = str(args.sem).strip()
    for item in items:
        if not isinstance(item, dict):
            continue
        b = str(item.get("branch", "")).strip()
        s = str(item.get("sem", "")).strip()
        if b == target_branch and s == target_sem:
            name = item.get("subjectName") or item.get("subject")
            if name:
                ql_subjects.add(str(name).strip())
    if not ql_subjects:
        print(f"\n[Firestore] No subjects matched branch={target_branch!r} sem={target_sem!r}.")
        # Help debug: show what branches/sems DO exist
        branches_seen = {str(it.get("branch", "")).strip() for it in items if isinstance(it, dict)}
        sems_seen = {str(it.get("sem", "")).strip() for it in items if isinstance(it, dict)}
        print(f"  branches present: {sorted(branches_seen)}")
        print(f"  sems present:     {sorted(sems_seen)}")
        return

    ql_subjects_sorted = sorted(ql_subjects)
    print(f"\n[QueryList] {len(ql_subjects_sorted)} subjects for {args.branch} sem {args.sem}:")
    for s in ql_subjects_sorted:
        print(f"  - {s}")

    # ---- Diff ------------------------------------------------------------
    drive_set = set(drive_subjects)
    ql_set = set(ql_subjects_sorted)

    exact = drive_set & ql_set
    only_drive = drive_set - ql_set
    only_ql = ql_set - drive_set

    # case-only matches (lowercased)
    drive_lc = {s.lower(): s for s in only_drive}
    ql_lc = {s.lower(): s for s in only_ql}
    case_only = []
    for lc in set(drive_lc) & set(ql_lc):
        case_only.append((drive_lc[lc], ql_lc[lc]))
    case_only_drive = {d for d, _ in case_only}
    case_only_ql = {q for _, q in case_only}

    only_drive_real = only_drive - case_only_drive
    only_ql_real = only_ql - case_only_ql

    print()
    print("=" * 70)
    print(f"DIFF SUMMARY — {args.university}/{args.course}/{args.branch}/sem {args.sem}")
    print("=" * 70)
    print(f"  Exact matches:        {len(exact)}")
    print(f"  Case-only mismatches: {len(case_only)}")
    print(f"  Only on drive:        {len(only_drive_real)}")
    print(f"  Only in QueryList:    {len(only_ql_real)}")

    if exact:
        print(f"\n[OK] Exact matches ({len(exact)}):")
        for s in sorted(exact):
            print(f"    {s}")
    if case_only:
        print(f"\n[CASE] Same letters, different case ({len(case_only)}):")
        for d, q in sorted(case_only):
            print(f"    drive: {d!r}   queryList: {q!r}")
    if only_drive_real:
        print(f"\n[DRIVE-ONLY] Folders on drive with no QueryList entry ({len(only_drive_real)}):")
        for s in sorted(only_drive_real):
            print(f"    {s}")
    if only_ql_real:
        print(f"\n[QL-ONLY] QueryList entries with no drive folder ({len(only_ql_real)}):")
        for s in sorted(only_ql_real):
            print(f"    {s}")


if __name__ == "__main__":
    main()
