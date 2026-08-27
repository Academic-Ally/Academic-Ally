"""Pre-flight diff for JNTUH/BTECH: drive folder structure vs Firestore
QueryList. Identifies branches/sems present on drive but missing from
QueryList, subject-name mismatches, and the cleanup work needed before
JNTUH bulk upload.

Run from backend/:
    uv run python scripts/preflight_jntuh.py
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
from firebase_admin import firestore  # noqa
if not firebase_admin._apps:
    firebase_admin.initialize_app(options={"storageBucket": settings.backend_storage_bucket})

db = firestore.client()

UNIVERSITY = "JNTUH"
COURSE = "BTECH"
DRIVE_ROOT = Path("E:/Academic Ally Complete Drive/NOTES/JNTUH/BTECH")
IGNORE_DIRS = {"desktop.ini", ".DS_Store", "Thumbs.db"}

print(f"Pre-flight: {UNIVERSITY}/{COURSE}")
print(f"Drive root: {DRIVE_ROOT}")
print()

# ---- Drive structure ------------------------------------------------------
print("[1] Walking drive ...")
drive_branches = {}  # branch -> {sem -> set(subjects)}
for branch_dir in sorted(DRIVE_ROOT.iterdir()):
    if not branch_dir.is_dir() or branch_dir.name in IGNORE_DIRS:
        continue
    drive_branches[branch_dir.name] = {}
    for sub in sorted(branch_dir.iterdir()):
        if not sub.is_dir() or sub.name in IGNORE_DIRS:
            continue
        if sub.name.isdigit():
            sem = sub.name
            subjects = {
                p.name for p in sub.iterdir()
                if p.is_dir() and p.name not in IGNORE_DIRS
            }
            drive_branches[branch_dir.name][sem] = subjects

# Print drive summary
print(f"  -> {len(drive_branches)} branches on drive:")
for b in sorted(drive_branches):
    sems = sorted(drive_branches[b].keys())
    total_subjects = sum(len(s) for s in drive_branches[b].values())
    nested = (DRIVE_ROOT / b / b).is_dir()
    print(f"    {b:25s}  sems={sems}  subjects={total_subjects}  nested-folder={'YES' if nested else 'no'}")

# ---- QueryList for JNTUH/BTECH ------------------------------------------
print()
print("[2] Reading QueryList ...")
ql_path = f"QueryList/{UNIVERSITY}/{COURSE}/SubjectsListDetail"
snap = db.document(ql_path).get()
if not snap.exists:
    print(f"  [ERROR] QueryList doc missing: {ql_path}")
    print("  -> JNTUH will need QueryList fully built from scratch.")
    ql_branches = {}
else:
    items = (snap.to_dict() or {}).get("list", [])
    print(f"  -> {len(items)} entries in QueryList")
    ql_branches = defaultdict(lambda: defaultdict(set))
    for it in items:
        if not isinstance(it, dict):
            continue
        b = str(it.get("branch", "")).strip()
        s = str(it.get("sem", "")).strip()
        name = it.get("subject") or it.get("subjectName")
        if b and s and name:
            ql_branches[b][s].add(str(name).strip())
    for b in sorted(ql_branches):
        total = sum(len(s) for s in ql_branches[b].values())
        print(f"    {b:25s}  sems={sorted(ql_branches[b].keys())}  subjects={total}")

# ---- Branch-level diff ----------------------------------------------------
print()
print("[3] Branch-level diff (drive vs QueryList)")
print("=" * 70)
drive_branch_set = set(drive_branches.keys())
ql_branch_set = set(ql_branches.keys())
both = drive_branch_set & ql_branch_set
only_drive = drive_branch_set - ql_branch_set
only_ql = ql_branch_set - drive_branch_set

print(f"  Branches in BOTH ({len(both)}):           {sorted(both)}")
print(f"  Branches on drive only ({len(only_drive)}):    {sorted(only_drive)}")
print(f"  Branches in QueryList only ({len(only_ql)}): {sorted(only_ql)}")

# ---- Per (branch, sem) diff for shared branches ---------------------------
print()
print("[4] Per (branch, sem) subject-name diff for shared branches")
print("=" * 70)
total_subject_mismatch_combos = 0
total_drive_only_subjects = 0
total_ql_only_subjects = 0
for b in sorted(both):
    print(f"\n  --- {b} ---")
    drive_sems = drive_branches[b]
    ql_sems = ql_branches[b]
    all_sems = sorted(set(drive_sems) | set(ql_sems), key=lambda x: int(x))
    for sem in all_sems:
        d_subs = drive_sems.get(sem, set())
        q_subs = ql_sems.get(sem, set())
        if d_subs == q_subs:
            if d_subs:
                print(f"    sem {sem}: MATCH ({len(d_subs)} subjects)")
            continue
        only_d = d_subs - q_subs
        only_q = q_subs - d_subs
        common = d_subs & q_subs
        flag = " *MISMATCH" if only_d or only_q else ""
        print(f"    sem {sem}: {len(common)} match, {len(only_d)} drive-only, {len(only_q)} ql-only{flag}")
        if only_d:
            total_drive_only_subjects += len(only_d)
            for s in sorted(only_d)[:6]:
                print(f"      drive-only: {s!r}")
            if len(only_d) > 6:
                print(f"      ... +{len(only_d) - 6} more drive-only")
        if only_q:
            total_ql_only_subjects += len(only_q)
            for s in sorted(only_q)[:6]:
                print(f"      ql-only: {s!r}")
            if len(only_q) > 6:
                print(f"      ... +{len(only_q) - 6} more ql-only")
        if only_d or only_q:
            total_subject_mismatch_combos += 1

# ---- Drive-only branches: full subject dump for those ---------------------
if only_drive:
    print()
    print("[5] Subject inventory for branches NOT in QueryList")
    print("=" * 70)
    for b in sorted(only_drive):
        print(f"\n  --- {b} ---")
        for sem in sorted(drive_branches[b].keys(), key=lambda x: int(x)):
            subs = sorted(drive_branches[b][sem])
            print(f"    sem {sem}: {len(subs)} subject(s)")
            for s in subs[:5]:
                print(f"      - {s}")
            if len(subs) > 5:
                print(f"      ... +{len(subs) - 5} more")

# ---- Summary --------------------------------------------------------------
print()
print("=" * 70)
print("PRE-FLIGHT SUMMARY")
print("=" * 70)
print(f"  Drive branches:          {len(drive_branch_set)}")
print(f"  QueryList branches:      {len(ql_branch_set)}")
print(f"  Branches matching:       {len(both)}")
print(f"  Drive-only branches:     {len(only_drive)}  (need QueryList entries OR skip on upload)")
print(f"  (branch, sem) mismatch:  {total_subject_mismatch_combos}")
print(f"  Drive-only subjects:     {total_drive_only_subjects}  (will upload but NOT findable in app)")
print(f"  QueryList-only subjects: {total_ql_only_subjects}  (no drive data, just empty)")
