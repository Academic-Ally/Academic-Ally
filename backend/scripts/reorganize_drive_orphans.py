"""Reorganize the 25 orphan PDFs on the E:\\ drive so they land in the
proper `{subject}/{Notes|OtherResources|Syllabus|QuestionPapers}/` layout
that upload_pdfs.py expects.

Run with --dry-run first to see what would happen, then again without
--dry-run to execute.

Usage from backend/:
    uv run python scripts/reorganize_drive_orphans.py --dry-run
    uv run python scripts/reorganize_drive_orphans.py
"""
import argparse
import shutil
import sys
from pathlib import Path

DRIVE_ROOT = Path("E:/Academic Ally Complete Drive/NOTES/OU/B.E")

# (source_relative, dest_relative)
# source = single PDF file to move; dest = where it should land (relative
# to DRIVE_ROOT). dest's parent dirs are created as needed.
SINGLE_FILE_MOVES = [
    # CSE/sem 6 — Soft Skills
    ("CSE/6/Soft Skills and Interpersonal Skills/SOFT SKILLS AND INTERPERSONAL SKILLS Syllabus.pdf",
     "CSE/6/Soft Skills and Interpersonal Skills/Syllabus/SOFT SKILLS AND INTERPERSONAL SKILLS Syllabus.pdf"),

    # IT/sem 3 — Data Structures Lab (records / programs -> OtherResources)
    ("IT/3/Data Structures Lab/All DS Programs with Execution.pdf",
     "IT/3/Data Structures Lab/OtherResources/All DS Programs with Execution.pdf"),
    ("IT/3/Data Structures Lab/DSA LAB RECORD-III sem.pdf",
     "IT/3/Data Structures Lab/OtherResources/DSA LAB RECORD-III sem.pdf"),

    # IT/sem 4 — JAVA Lab
    ("IT/4/JAVA Programming Lab/Java Lab Manual.pdf",
     "IT/4/JAVA Programming Lab/OtherResources/Java Lab Manual.pdf"),
    ("IT/4/JAVA Programming Lab/java lab record.pdf",
     "IT/4/JAVA Programming Lab/OtherResources/java lab record.pdf"),
    ("IT/4/JAVA Programming Lab/java lab syllabus.pdf",
     "IT/4/JAVA Programming Lab/Syllabus/java lab syllabus.pdf"),

    # IT/sem 4 — Microprocessor Lab
    ("IT/4/Microprocessor Lab/8085 instruction set details.pdf",
     "IT/4/Microprocessor Lab/OtherResources/8085 instruction set details.pdf"),
    ("IT/4/Microprocessor Lab/Micro Processors Lab Programs. (1).pdf",
     "IT/4/Microprocessor Lab/OtherResources/Micro Processors Lab Programs. (1).pdf"),
    ("IT/4/Microprocessor Lab/microprocessor lab manual.pdf",
     "IT/4/Microprocessor Lab/OtherResources/microprocessor lab manual.pdf"),
    ("IT/4/Microprocessor Lab/MICROPROCESSORLABMANUALBIT281.pdf",
     "IT/4/Microprocessor Lab/OtherResources/MICROPROCESSORLABMANUALBIT281.pdf"),
    ("IT/4/Microprocessor Lab/mp lab codes.pdf",
     "IT/4/Microprocessor Lab/OtherResources/mp lab codes.pdf"),
    ("IT/4/Microprocessor Lab/MP lab Prev Yr record.pdf",
     "IT/4/Microprocessor Lab/OtherResources/MP lab Prev Yr record.pdf"),
    ("IT/4/Microprocessor Lab/MP lab program pics.pdf",
     "IT/4/Microprocessor Lab/OtherResources/MP lab program pics.pdf"),
    ("IT/4/Microprocessor Lab/mp lab syllabus.pdf",
     "IT/4/Microprocessor Lab/Syllabus/mp lab syllabus.pdf"),

    # IT/sem 4 — Operations Research: fix "Other Resources" (with space) -> "OtherResources"
    ("IT/4/Operations Research/Other Resources/OR 5 units Saqs MJ.pdf",
     "IT/4/Operations Research/OtherResources/OR 5 units Saqs MJ.pdf"),

    # IT/sem 6 — DAA Lab
    ("IT/6/Design and Analysis of Algorithms Lab/DAA_VIVA.pdf",
     "IT/6/Design and Analysis of Algorithms Lab/OtherResources/DAA_VIVA.pdf"),
]

# Whole-folder moves (move entire subject folder including all sub-content).
# (source_relative_dir, dest_relative_dir)
FOLDER_MOVES = [
    ("IT/7/IT/8/Cryptography and Network Security",
     "IT/8/Cryptography and Network Security"),
]

# Empty directories to delete AFTER the moves complete (cleanup).
CLEANUP_DIRS = [
    "IT/7/IT/8",  # parent of moved Cryptography folder, should be empty after move
    "IT/7/IT",     # phantom IT nested folder
    "IT/4/Operations Research/Other Resources",  # parent of moved OR file
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true",
                    help="Print planned moves; do not execute.")
    args = ap.parse_args()

    print(f"Drive root: {DRIVE_ROOT}")
    print(f"Mode: {'DRY-RUN' if args.dry_run else 'EXECUTE'}\n")

    total_planned = 0
    total_done = 0
    total_skipped = 0
    total_errors = 0

    # ---- Single file moves ----------------------------------------------
    print("=" * 75)
    print(f"SINGLE FILE MOVES ({len(SINGLE_FILE_MOVES)})")
    print("=" * 75)
    for src_rel, dst_rel in SINGLE_FILE_MOVES:
        src = DRIVE_ROOT / src_rel
        dst = DRIVE_ROOT / dst_rel
        total_planned += 1
        print(f"  {src_rel}")
        print(f"    -> {dst_rel}")
        if not src.is_file():
            print(f"    [SKIP] source file missing")
            total_skipped += 1
            continue
        if dst.exists():
            print(f"    [SKIP] destination already exists — not overwriting")
            total_skipped += 1
            continue
        if not args.dry_run:
            try:
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(src), str(dst))
                print(f"    [OK] moved")
                total_done += 1
            except Exception as e:
                print(f"    [ERROR] {e}")
                total_errors += 1
        else:
            print(f"    [DRY] would move")

    # ---- Folder moves ---------------------------------------------------
    print()
    print("=" * 75)
    print(f"FOLDER MOVES ({len(FOLDER_MOVES)})")
    print("=" * 75)
    for src_rel, dst_rel in FOLDER_MOVES:
        src = DRIVE_ROOT / src_rel
        dst = DRIVE_ROOT / dst_rel
        total_planned += 1
        print(f"  {src_rel}/  (contains {sum(1 for _ in src.rglob('*.pdf')) if src.is_dir() else '?'} PDFs)")
        print(f"    -> {dst_rel}/")
        if not src.is_dir():
            print(f"    [SKIP] source folder missing")
            total_skipped += 1
            continue
        if dst.exists():
            print(f"    [SKIP] destination already exists — not overwriting")
            total_skipped += 1
            continue
        if not args.dry_run:
            try:
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(src), str(dst))
                print(f"    [OK] moved folder")
                total_done += 1
            except Exception as e:
                print(f"    [ERROR] {e}")
                total_errors += 1
        else:
            print(f"    [DRY] would move folder")

    # ---- Cleanup empty dirs --------------------------------------------
    print()
    print("=" * 75)
    print(f"CLEANUP — REMOVE EMPTY DIRS ({len(CLEANUP_DIRS)})")
    print("=" * 75)
    for rel in CLEANUP_DIRS:
        path = DRIVE_ROOT / rel
        if not path.exists():
            print(f"  {rel}  -- already gone, skip")
            continue
        # Check it's empty (ignore desktop.ini)
        contents = [c for c in path.iterdir() if c.name != "desktop.ini"]
        if contents:
            print(f"  {rel}  -- not empty ({len(contents)} items remain), skip")
            continue
        if not args.dry_run:
            try:
                # Remove desktop.ini if present, then rmdir
                ini = path / "desktop.ini"
                if ini.exists():
                    ini.unlink()
                path.rmdir()
                print(f"  {rel}  -- removed")
            except Exception as e:
                print(f"  {rel}  -- [ERROR] {e}")
        else:
            print(f"  {rel}  -- [DRY] would remove (empty)")

    print()
    print("=" * 75)
    print("SUMMARY")
    print("=" * 75)
    print(f"  Planned: {total_planned}")
    if not args.dry_run:
        print(f"  Done:    {total_done}")
        print(f"  Skipped: {total_skipped}")
        print(f"  Errors:  {total_errors}")
        if total_errors == 0:
            print("\n  Next step: re-run upload_pdfs.py for affected combos to push the relocated PDFs.")
        else:
            print("\n  Resolve errors before re-running upload.")


if __name__ == "__main__":
    main()
