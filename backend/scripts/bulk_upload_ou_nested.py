"""Phase 2: upload sems that live inside nested same-name folders on the drive.

Some OU/B.E branches have sems organized inside a nested folder named the
same as the branch (e.g. CSE/CSE/5, ECE/ECE/7). The main bulk_upload_ou.py
only walks top-level sem folders, so this script handles the leftovers.

Mapping (drive source -> Firebase target):
  CSE/CSE/5   ->  Resources/OU/BE/CSE/5
  CSE/CSE/7   ->  Resources/OU/BE/CSE/7
  CSE/CSE/8   ->  Resources/OU/BE/CSE/8
  ECE/ECE/7   ->  Resources/OU/BE/ECE/7
  EEE/EEE/4   ->  Resources/OU/BE/EEE/4
  IT/IT/8     ->  Resources/OU/BE/IT/8     (supplementary — idempotent merge)
  MECH/MECH/6 ->  Resources/OU/BE/MECH/6   (supplementary — idempotent merge)

Run from backend/:
    uv run python scripts/bulk_upload_ou_nested.py
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

UNIVERSITY = "OU"
COURSE = "BE"
DRIVE_ROOT = Path("E:/Academic Ally Complete Drive/NOTES/OU/B.E")

# (drive_branch_folder, drive_sem_folder, fs_branch, fs_sem)
NESTED_CASES = [
    ("CSE", "5", "CSE", "5"),
    ("CSE", "7", "CSE", "7"),
    ("CSE", "8", "CSE", "8"),
    ("ECE", "7", "ECE", "7"),
    ("EEE", "4", "EEE", "4"),
    ("IT", "8", "IT", "8"),
    ("MECH", "6", "MECH", "6"),
]


def run_upload(source: Path, fs_branch: str, sem: str) -> tuple[int, int, int]:
    cmd = [
        sys.executable,
        str(Path(__file__).parent / "upload_pdfs.py"),
        "--root", str(source),
        "--university", UNIVERSITY,
        "--course", COURSE,
        "--branch", fs_branch,
        "--sem", sem,
    ]
    print(f"    Running: upload_pdfs.py --root {source} --branch {fs_branch!r} --sem {sem}")
    env = os.environ.copy()
    env["PYTHONIOENCODING"] = "utf-8"
    result = subprocess.run(
        cmd, env=env, capture_output=True, text=True, encoding="utf-8", errors="replace",
    )
    uploaded = skipped = failed = 0
    for line in (result.stdout or "").splitlines():
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
    print(f"Phase 2: nested-folder uploads for {UNIVERSITY}/{COURSE}")
    print(f"Drive root: {DRIVE_ROOT}\n")

    started_at = time.time()
    total_up = total_skip = total_fail = 0
    results = []

    for idx, (drive_b, drive_s, fs_b, fs_s) in enumerate(NESTED_CASES, 1):
        source = DRIVE_ROOT / drive_b / drive_b / drive_s
        print()
        print("=" * 75)
        print(f"[{idx}/{len(NESTED_CASES)}]  {drive_b}/{drive_b}/{drive_s}  ->  {fs_b}/sem {fs_s}")
        print("=" * 75)
        if not source.is_dir():
            print(f"    [SKIP] source folder missing: {source}")
            results.append((fs_b, fs_s, 0, 0, 0, 0.0, "missing"))
            continue
        t0 = time.time()
        up, sk, fa = run_upload(source, fs_b, fs_s)
        dt = time.time() - t0
        total_up += up
        total_skip += sk
        total_fail += fa
        results.append((fs_b, fs_s, up, sk, fa, dt, "ok"))
        print(f"    -> uploaded={up} skipped={sk} failed={fa}  ({dt:.0f}s)")

    elapsed = time.time() - started_at
    print()
    print("=" * 75)
    print("PHASE 2 COMPLETE")
    print("=" * 75)
    print(f"  Cases processed:    {len(NESTED_CASES)}")
    print(f"  Files uploaded:     {total_up}")
    print(f"  Files skipped:      {total_skip}  (idempotent)")
    print(f"  Files failed:       {total_fail}")
    print(f"  Total elapsed:      {elapsed/60:.1f} min")
    print()
    print("  Per-case summary:")
    for fs_b, fs_s, up, sk, fa, dt, status in results:
        print(f"    {fs_b:6s}/sem {fs_s}  uploaded={up:4d}  skipped={sk:3d}  failed={fa}  ({dt:.0f}s)  [{status}]")


if __name__ == "__main__":
    main()
