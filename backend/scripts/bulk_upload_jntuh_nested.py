"""Phase 2: upload JNTUH sems that live inside nested same-name folders.

Mapping (drive source -> Firebase target):
  CIVIL/CIVIL/1                              -> Resources/JNTUH/BTECH/CIVIL/1
  CIVIL/CIVIL/2                              -> Resources/JNTUH/BTECH/CIVIL/2
  CSE/CSE/5                                  -> Resources/JNTUH/BTECH/CSE/5
  CSE(Non-Autonomous)/CSE(Non-Autonomous)/2  -> Resources/JNTUH/BTECH/CSE(Non-Autonomous)/2
  CSE(Non-Autonomous)/CSE(Non-Autonomous)/5  -> Resources/JNTUH/BTECH/CSE(Non-Autonomous)/5
  CSE(Non-Autonomous)/CSE(Non-Autonomous)/6  -> Resources/JNTUH/BTECH/CSE(Non-Autonomous)/6
  CSE(Non-Autonomous)/CSE(Non-Autonomous)/7  -> Resources/JNTUH/BTECH/CSE(Non-Autonomous)/7
  IT/IT/3                                    -> Resources/JNTUH/BTECH/IT/3
  IT/IT/6                                    -> Resources/JNTUH/BTECH/IT/6
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

NESTED_CASES = [
    ("CIVIL", "1"),
    ("CIVIL", "2"),
    ("CSE", "5"),
    ("CSE(Non-Autonomous)", "2"),
    ("CSE(Non-Autonomous)", "5"),
    ("CSE(Non-Autonomous)", "6"),
    ("CSE(Non-Autonomous)", "7"),
    ("IT", "3"),
    ("IT", "6"),
]


def run_upload(source: Path, branch: str, sem: str) -> tuple[int, int, int]:
    cmd = [
        sys.executable,
        str(Path(__file__).parent / "upload_pdfs.py"),
        "--root", str(source),
        "--university", UNIVERSITY,
        "--course", COURSE,
        "--branch", branch,
        "--sem", sem,
    ]
    print(f"    Running: upload_pdfs.py --root {source} --branch {branch!r} --sem {sem}", flush=True)
    env = os.environ.copy()
    env["PYTHONIOENCODING"] = "utf-8"
    result = subprocess.run(
        cmd, env=env, capture_output=True, text=True,
        encoding="utf-8", errors="replace",
    )
    uploaded = skipped = failed = 0
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
    print(f"JNTUH Phase 2: nested-folder uploads")
    print(f"Drive root: {DRIVE_ROOT}\n")

    started_at = time.time()
    total_up = total_skip = total_fail = 0
    results = []

    for idx, (branch, sem) in enumerate(NESTED_CASES, 1):
        source = DRIVE_ROOT / branch / branch / sem
        print()
        print("=" * 75)
        print(f"[{idx}/{len(NESTED_CASES)}]  {branch}/{branch}/{sem}  ->  {branch}/sem {sem}")
        print("=" * 75)
        if not source.is_dir():
            print(f"    [SKIP] source folder missing: {source}")
            results.append((branch, sem, 0, 0, 0, 0.0, "missing"))
            continue
        t0 = time.time()
        up, sk, fa = run_upload(source, branch, sem)
        dt = time.time() - t0
        total_up += up
        total_skip += sk
        total_fail += fa
        results.append((branch, sem, up, sk, fa, dt, "ok"))
        print(f"    -> uploaded={up} skipped={sk} failed={fa}  ({dt:.0f}s)", flush=True)

    elapsed = time.time() - started_at
    print()
    print("=" * 75)
    print("JNTUH PHASE 2 COMPLETE")
    print("=" * 75)
    print(f"  Cases processed:    {len(NESTED_CASES)}")
    print(f"  Files uploaded:     {total_up}")
    print(f"  Files skipped:      {total_skip}")
    print(f"  Files failed:       {total_fail}")
    print(f"  Total elapsed:      {elapsed/60:.1f} min")
    print()
    print("  Per-case summary:")
    for branch, sem, up, sk, fa, dt, status in results:
        print(f"    {branch:25s}  sem {sem}  uploaded={up:4d}  skipped={sk:3d}  failed={fa}  ({dt:.0f}s)  [{status}]")


if __name__ == "__main__":
    main()
