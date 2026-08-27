"""Bulk-upload every (branch, sem) under JNTUH/BTECH from the drive to
Firebase. Mirrors bulk_upload_ou.py.

Handles top-level sem folders only. Run bulk_upload_jntuh_nested.py
afterward to catch sems that live inside nested same-name folders.

Run from backend/:
    uv run python scripts/bulk_upload_jntuh.py
"""
import os
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.settings import settings  # noqa
if settings.google_application_credentials and not os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"):
    cred_path = settings.google_application_credentials
    if not os.path.isabs(cred_path):
        cred_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", cred_path))
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = cred_path

UNIVERSITY = "JNTUH"
COURSE = "BTECH"
DRIVE_ROOT = Path("E:/Academic Ally Complete Drive/NOTES/JNTUH/BTECH")

# Drive name == Firestore name for JNTUH (verified — no remap needed).
BRANCHES = [
    "AER",
    "CIVIL",
    "CSE",
    "CSE(AI and ML)",
    "CSE(Cyber Security)",
    "CSE(Data Science)",
    "CSE(IOT)",
    "CSE(Non-Autonomous)",
    "ECE",
    "EEE",
    "IT",
    "MECH",
]
IGNORE = {"desktop.ini", ".DS_Store", "Thumbs.db"}


def discover_combos():
    """List (branch, sem, sem_path) for every top-level sem folder on disk."""
    combos = []
    for branch in BRANCHES:
        bdir = DRIVE_ROOT / branch
        if not bdir.is_dir():
            print(f"  [WARN] branch missing on drive: {branch}")
            continue
        for sub in sorted(bdir.iterdir()):
            if not sub.is_dir() or sub.name in IGNORE:
                continue
            if sub.name.isdigit():
                combos.append((branch, sub.name, sub))
    return combos


def run_upload(drive_path: Path, branch: str, sem: str) -> tuple[int, int, int]:
    cmd = [
        sys.executable,
        str(Path(__file__).parent / "upload_pdfs.py"),
        "--root", str(drive_path),
        "--university", UNIVERSITY,
        "--course", COURSE,
        "--branch", branch,
        "--sem", sem,
    ]
    env = os.environ.copy()
    env["PYTHONIOENCODING"] = "utf-8"
    # upload_pdfs.py logs via logging -> stderr by default. Merge so we can parse.
    result = subprocess.run(
        cmd, env=env, capture_output=True, text=True,
        encoding="utf-8", errors="replace",
    )
    uploaded = skipped = failed = 0
    # Parse from stderr (logging) — that's where upload_pdfs.py's logger writes.
    for line in (result.stderr or "").splitlines():
        if "done" in line and "uploaded=" in line:
            for piece in line.split():
                if piece.startswith("uploaded="):
                    uploaded = int(piece.split("=", 1)[1])
                elif piece.startswith("skipped="):
                    skipped = int(piece.split("=", 1)[1])
                elif piece.startswith("failed="):
                    failed = int(piece.split("=", 1)[1])
    if result.returncode != 0:
        print(f"    [ERROR] upload_pdfs.py exit={result.returncode}")
        for line in (result.stderr or "").splitlines()[-15:]:
            print(f"    {line}")
    return uploaded, skipped, failed


def main():
    combos = discover_combos()
    print(f"Discovered {len(combos)} (branch, sem) combos on drive:")
    for b, s, _ in combos:
        print(f"  {b:25s}  sem {s}")
    print()

    started_at = time.time()
    total_up = total_skip = total_fail = 0
    results = []

    for idx, (branch, sem, path) in enumerate(combos, 1):
        print()
        print("=" * 75)
        print(f"[{idx}/{len(combos)}]  {UNIVERSITY}/{COURSE}/{branch}/sem {sem}")
        print("=" * 75, flush=True)
        t0 = time.time()
        up, sk, fa = run_upload(path, branch, sem)
        dt = time.time() - t0
        total_up += up
        total_skip += sk
        total_fail += fa
        results.append((branch, sem, up, sk, fa, dt))
        print(f"    -> uploaded={up} skipped={sk} failed={fa}  ({dt:.0f}s)", flush=True)

    elapsed = time.time() - started_at
    print()
    print("=" * 75)
    print("JNTUH BULK COMPLETE")
    print("=" * 75)
    print(f"  Combos processed:   {len(combos)}")
    print(f"  Files uploaded:     {total_up}")
    print(f"  Files skipped:      {total_skip}")
    print(f"  Files failed:       {total_fail}")
    print(f"  Total elapsed:      {elapsed/60:.1f} min")
    print()
    print("  Per-combo summary:")
    for branch, sem, up, sk, fa, dt in results:
        print(f"    {branch:25s}  sem {sem}  uploaded={up:4d}  skipped={sk:3d}  failed={fa}  ({dt:.0f}s)")


if __name__ == "__main__":
    main()
