"""Re-upload the 5 (branch, sem) combos affected by the orphan-PDF
relocation. Idempotent — existing files skip, only the 25 newly-moved
files upload.
"""
import os
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# These are the combos that gained newly-relocated files.
AFFECTED = [
    ("CSE/6",   "CSE",  "6"),   # 1 Syllabus pdf moved into Syllabus subfolder
    ("IT/3",    "IT",   "3"),   # 2 DSL records
    ("IT/4",    "IT",   "4"),   # 13 lab files
    ("IT/6",    "IT",   "6"),   # 1 DAA viva
    ("IT/8",    "IT",   "8"),   # 8 CNS files (whole subject folder)
]

DRIVE_ROOT = Path("E:/Academic Ally Complete Drive/NOTES/OU/B.E")

env = os.environ.copy()
env["PYTHONIOENCODING"] = "utf-8"

t0 = time.time()
for rel, branch, sem in AFFECTED:
    src = DRIVE_ROOT / rel
    print()
    print("=" * 75)
    print(f"Re-uploading: {src}  ->  Resources/OU/BE/{branch}/{sem}/")
    print("=" * 75)
    cmd = [
        sys.executable,
        str(Path(__file__).parent / "upload_pdfs.py"),
        "--root", str(src),
        "--university", "OU",
        "--course", "BE",
        "--branch", branch,
        "--sem", sem,
    ]
    result = subprocess.run(cmd, env=env)
    print(f"exit={result.returncode}")

print(f"\nTotal time: {(time.time()-t0)/60:.1f} min")
