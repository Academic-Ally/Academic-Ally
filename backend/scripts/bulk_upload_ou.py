"""Bulk-upload every (branch, sem) under OU/B.E from the drive to Firebase.

For each (branch, sem) found on disk:
  1. Pre-flight diff: drive subject folders vs QueryList SubjectsListDetail
  2. Run upload_pdfs.py logic (idempotent — skips already-uploaded files)
  3. Log result

JNTUH is intentionally NOT covered here (needs QueryList prep first).

Run from backend/:
    uv run python scripts/bulk_upload_ou.py
"""
import os
import subprocess
import sys
import time
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

UNIVERSITY = "OU"
COURSE = "BE"  # Firestore name (drive uses "B.E")
DRIVE_ROOT = Path("E:/Academic Ally Complete Drive/NOTES/OU/B.E")

# Drive → Firestore branch name mapping.
BRANCH_MAP = {
    "CIVIL": "CIVIL",
    "CSE": "CSE",
    "CSE AIML": "CSE AIML",
    "CSE IoT": "CSE IOT",  # drive uses IoT, Firestore uses IOT
    "ECE": "ECE",
    "EEE": "EEE",
    "IT": "IT",
    "MECH": "MECH",
}

IGNORE_DIRS = {"desktop.ini"}


def load_querylist_subjects(db) -> dict:
    """Returns dict {(branch, sem) -> set(subject_names)} from QueryList."""
    doc_path = f"QueryList/{UNIVERSITY}/{COURSE}/SubjectsListDetail"
    snap = db.document(doc_path).get()
    if not snap.exists:
        print(f"[FATAL] QueryList doc missing: {doc_path}")
        sys.exit(2)
    items = (snap.to_dict() or {}).get("list") or []
    out = {}
    for it in items:
        if not isinstance(it, dict):
            continue
        b = str(it.get("branch", "")).strip()
        s = str(it.get("sem", "")).strip()
        name = it.get("subjectName") or it.get("subject")
        if not (b and s and name):
            continue
        out.setdefault((b, s), set()).add(str(name).strip())
    return out


def discover_drive_combos() -> list[tuple[str, str, Path]]:
    """Returns list of (drive_branch, sem, sem_path) for every sem folder
    found on disk under DRIVE_ROOT."""
    combos = []
    if not DRIVE_ROOT.is_dir():
        print(f"[FATAL] Drive root missing: {DRIVE_ROOT}")
        sys.exit(2)
    for branch_dir in sorted(DRIVE_ROOT.iterdir()):
        if not branch_dir.is_dir() or branch_dir.name in IGNORE_DIRS:
            continue
        drive_branch = branch_dir.name
        if drive_branch not in BRANCH_MAP:
            print(f"  [WARN] Drive branch not in BRANCH_MAP, skipping: {drive_branch}")
            continue
        for sem_dir in sorted(branch_dir.iterdir(), key=lambda p: p.name):
            if not sem_dir.is_dir() or sem_dir.name in IGNORE_DIRS:
                continue
            # We expect sem folders to be plain ints "1".."8"
            if not sem_dir.name.isdigit():
                continue
            combos.append((drive_branch, sem_dir.name, sem_dir))
    return combos


def preflight(drive_path: Path, fs_branch: str, sem: str, ql: dict) -> list[str]:
    """Return list of mismatch warning lines (empty = perfect match)."""
    drive_subjects = {
        p.name for p in drive_path.iterdir()
        if p.is_dir() and p.name not in IGNORE_DIRS
    }
    ql_subjects = ql.get((fs_branch, sem), set())
    only_drive = drive_subjects - ql_subjects
    only_ql = ql_subjects - drive_subjects
    warnings = []
    if only_drive:
        warnings.append(f"    [drive-only, will upload but NOT findable in app] {sorted(only_drive)}")
    if only_ql:
        warnings.append(f"    [QueryList-only, no drive data] {sorted(only_ql)}")
    return warnings


def run_upload(drive_path: Path, fs_branch: str, sem: str) -> tuple[int, int, int]:
    """Invoke upload_pdfs.py for this combo. Returns (uploaded, skipped, failed)."""
    cmd = [
        sys.executable,
        str(Path(__file__).parent / "upload_pdfs.py"),
        "--root", str(drive_path),
        "--university", UNIVERSITY,
        "--course", COURSE,
        "--branch", fs_branch,
        "--sem", sem,
    ]
    print(f"    Running: upload_pdfs.py --branch {fs_branch!r} --sem {sem}")
    env = os.environ.copy()
    env["PYTHONIOENCODING"] = "utf-8"
    result = subprocess.run(
        cmd, env=env, capture_output=True, text=True, encoding="utf-8", errors="replace",
    )
    # The summary line looks like: "done -- uploaded=N skipped=M failed=K"
    uploaded = skipped = failed = 0
    for line in (result.stdout or "").splitlines():
        if "done" in line and "uploaded=" in line:
            # parse "uploaded=N skipped=M failed=K"
            for piece in line.split():
                if piece.startswith("uploaded="):
                    uploaded = int(piece.split("=", 1)[1])
                elif piece.startswith("skipped="):
                    skipped = int(piece.split("=", 1)[1])
                elif piece.startswith("failed="):
                    failed = int(piece.split("=", 1)[1])
    if result.returncode != 0:
        print(f"    [ERROR] upload_pdfs.py exit={result.returncode}")
        print("    --- stderr tail ---")
        for line in (result.stderr or "").splitlines()[-15:]:
            print(f"    {line}")
    return uploaded, skipped, failed


def main():
    db = firestore.client()
    print(f"Loading QueryList for {UNIVERSITY}/{COURSE} ...")
    ql = load_querylist_subjects(db)
    print(f"  -> {len(ql)} (branch, sem) entries in QueryList\n")

    combos = discover_drive_combos()
    print(f"Discovered {len(combos)} (branch, sem) combos on drive:\n")
    for db_b, sem, _ in combos:
        fs_b = BRANCH_MAP[db_b]
        n_ql = len(ql.get((fs_b, sem), set()))
        print(f"  {db_b:12s}  sem {sem}  (QueryList has {n_ql} subjects for {fs_b}/sem {sem})")
    print()

    started_at = time.time()
    total_up = total_skip = total_fail = 0
    combo_results = []

    for idx, (db_b, sem, path) in enumerate(combos, 1):
        fs_b = BRANCH_MAP[db_b]
        print()
        print("=" * 75)
        print(f"[{idx}/{len(combos)}]  {db_b}  ->  {UNIVERSITY}/{COURSE}/{fs_b}/sem {sem}")
        print("=" * 75)
        warnings = preflight(path, fs_b, sem, ql)
        if warnings:
            print("  Pre-flight warnings (will still upload):")
            for w in warnings:
                print(w)
        else:
            print("  Pre-flight: perfect match (drive subjects == QueryList)")

        t0 = time.time()
        up, sk, fa = run_upload(path, fs_b, sem)
        dt = time.time() - t0
        total_up += up
        total_skip += sk
        total_fail += fa
        combo_results.append((fs_b, sem, up, sk, fa, dt, warnings))
        print(f"    -> uploaded={up} skipped={sk} failed={fa}  ({dt:.0f}s)")

    elapsed = time.time() - started_at
    print()
    print("=" * 75)
    print("BULK UPLOAD COMPLETE")
    print("=" * 75)
    print(f"  Combos processed:   {len(combos)}")
    print(f"  Files uploaded:     {total_up}")
    print(f"  Files skipped:      {total_skip}  (idempotent — already in Firestore)")
    print(f"  Files failed:       {total_fail}")
    print(f"  Total elapsed:      {elapsed/60:.1f} min")
    print()
    print("  Per-combo summary:")
    for fs_b, sem, up, sk, fa, dt, warnings in combo_results:
        warn_flag = "  *MISMATCHES" if warnings else ""
        print(f"    {fs_b:12s}  sem {sem}  uploaded={up:4d}  skipped={sk:3d}  failed={fa}  ({dt:.0f}s){warn_flag}")

    combos_with_warnings = [r for r in combo_results if r[6]]
    if combos_with_warnings:
        print()
        print("  Combos with QueryList mismatches (need cleanup):")
        for fs_b, sem, _, _, _, _, warnings in combos_with_warnings:
            print(f"    {fs_b}/sem {sem}:")
            for w in warnings:
                print(w)


if __name__ == "__main__":
    main()
