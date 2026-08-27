"""Walk the 5 JNTUH branches that aren't in QueryList yet and add an entry
for every (branch, sem, subject) tuple found on disk. Preserves drive folder
names as-is (some have [R20A0xxx] course codes).
"""
import os
import sys
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

DRIVE_ROOT = Path("E:/Academic Ally Complete Drive/NOTES/JNTUH/BTECH")
NEW_BRANCHES = [
    "AER",
    "CSE(AI and ML)",
    "CSE(Cyber Security)",
    "CSE(Data Science)",
    "CSE(IOT)",
]
IGNORE = {"desktop.ini", ".DS_Store"}

# Build new entries from drive.
new_entries = []
for branch in NEW_BRANCHES:
    bdir = DRIVE_ROOT / branch
    if not bdir.is_dir():
        print(f"[WARN] missing on drive: {branch}")
        continue
    # Walk top-level sems
    for sub in sorted(bdir.iterdir()):
        if not sub.is_dir() or sub.name in IGNORE:
            continue
        if not sub.name.isdigit():
            continue
        sem = sub.name
        for subject_dir in sorted(sub.iterdir()):
            if not subject_dir.is_dir() or subject_dir.name in IGNORE:
                continue
            new_entries.append({"branch": branch, "sem": sem, "subject": subject_dir.name})
    # Walk nested same-name folder (if present)
    nested = bdir / branch
    if nested.is_dir():
        for sub in sorted(nested.iterdir()):
            if not sub.is_dir() or sub.name in IGNORE:
                continue
            if not sub.name.isdigit():
                continue
            sem = sub.name
            for subject_dir in sorted(sub.iterdir()):
                if not subject_dir.is_dir() or subject_dir.name in IGNORE:
                    continue
                new_entries.append({"branch": branch, "sem": sem, "subject": subject_dir.name})

print(f"Collected {len(new_entries)} new (branch, sem, subject) entries.\n")
# Show per-branch breakdown
by_branch = {}
for e in new_entries:
    by_branch.setdefault(e["branch"], 0)
    by_branch[e["branch"]] += 1
for b, n in sorted(by_branch.items()):
    print(f"  {b:25s}  {n} entries")

# Load existing QueryList
ql_ref = db.document("QueryList/JNTUH/BTECH/SubjectsListDetail")
snap = ql_ref.get()
if not snap.exists:
    print("\n[WARN] QueryList doc does not exist — creating with list field.")
    ql_ref.set({"list": []})
    snap = ql_ref.get()

existing = (snap.to_dict() or {}).get("list", [])
print(f"\nExisting QueryList entries: {len(existing)}")

# Deduplicate — only add entries not already present (exact match on b/s/subject)
existing_keys = set()
for e in existing:
    if not isinstance(e, dict):
        continue
    b = str(e.get("branch", "")).strip()
    s = str(e.get("sem", "")).strip()
    name = e.get("subject") or e.get("subjectName") or ""
    if b and s and name:
        existing_keys.add((b, s, str(name).strip()))

deduped_new = []
skip = 0
for e in new_entries:
    key = (e["branch"], e["sem"], e["subject"])
    if key in existing_keys:
        skip += 1
        continue
    deduped_new.append(e)

print(f"Already in QueryList (skipped): {skip}")
print(f"To be added: {len(deduped_new)}")

if deduped_new:
    merged = existing + deduped_new
    ql_ref.update({"list": merged})
    print(f"\n-> Updated QueryList: {len(existing)} -> {len(merged)} entries.")
else:
    print("\n-> Nothing to add.")
