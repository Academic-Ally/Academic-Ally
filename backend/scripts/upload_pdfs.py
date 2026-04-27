"""Upload local PDFs to Firebase Storage + create matching Firestore docs.

Local layout expected:
    {root}/{sem}/{subject}/{category}/{filename}.pdf

Where ``category`` ∈ {Notes, QuestionPapers, Syllabus, OtherResources}
and ``subject`` matches the QueryList entry for the target university.

For each PDF found, this script:
1. Uploads to Firebase Storage at:
       Resources/{uni}/{course}/{branch}/{sem}/{category}/{subject}/{filename}
2. Writes a Firestore doc at:
       Universities/{uni}/{course}/{branch}/{sem}/{category}/{subject}/{auto-id}
   with fields ResourceModel.fromFirestore reads (storageId, name, etc.).

Idempotent — skips files whose storageId already has a Firestore doc.

Usage:
    cd backend
    uv run python scripts/upload_pdfs.py \\
        --root ../IT/2 \\
        --university OU \\
        --course BE \\
        --branch IT \\
        --sem 2 \\
        --subjects "EOITK" "English" "Chemistry"

Without --subjects, every subject folder under {root} is uploaded.
"""
import argparse
import logging
import sys
from pathlib import Path

# Make app/ importable so we reuse settings + auth bootstrapping
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.settings import settings  # noqa: E402
from app.firebase_init import init_firebase_admin  # noqa: E402

from firebase_admin import firestore, storage  # noqa: E402
from google.cloud.firestore_v1 import SERVER_TIMESTAMP  # noqa: E402


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger("upload_pdfs")


CATEGORIES = ("Notes", "QuestionPapers", "Syllabus", "OtherResources")
IGNORE_NAMES = {"desktop.ini", ".DS_Store", "Thumbs.db"}


def _init_firebase() -> None:
    init_firebase_admin(storage_bucket=settings.backend_storage_bucket)


def _walk_pdfs(
    root: Path,
    subjects_filter: list[str] | None,
):
    """Yield ``(subject, category, local_path)`` for each PDF under ``root``."""
    if not root.exists():
        raise FileNotFoundError(f"root does not exist: {root}")

    for subject_dir in sorted(root.iterdir()):
        if not subject_dir.is_dir():
            continue
        if subject_dir.name in IGNORE_NAMES:
            continue
        if subjects_filter and subject_dir.name not in subjects_filter:
            continue

        for category in CATEGORIES:
            cat_dir = subject_dir / category
            if not cat_dir.is_dir():
                continue
            for pdf in sorted(cat_dir.iterdir()):
                if not pdf.is_file():
                    continue
                if pdf.name in IGNORE_NAMES:
                    continue
                if pdf.suffix.lower() != ".pdf":
                    continue
                yield subject_dir.name, category, pdf


def _build_storage_id(
    *,
    university: str,
    course: str,
    branch: str,
    sem: str,
    category: str,
    subject: str,
    filename: str,
) -> str:
    return (
        f"Resources/{university}/{course}/{branch}/{sem}/"
        f"{category}/{subject}/{filename}"
    )


def _firestore_doc_already_exists(
    client, *, university: str, course: str, branch: str, sem: str,
    category: str, subject: str, storage_id: str,
) -> bool:
    """Idempotency check: any doc in this subject's collection with this storageId?"""
    coll_path = (
        f"Universities/{university}/{course}/{branch}/{sem}/{category}/{subject}"
    )
    q = client.collection(coll_path).where("storageId", "==", storage_id).limit(1)
    return any(True for _ in q.stream())


def _upload_one(
    *,
    bucket,
    client,
    local_path: Path,
    university: str,
    course: str,
    branch: str,
    sem: str,
    category: str,
    subject: str,
) -> tuple[bool, str]:
    """Upload one PDF + create Firestore doc.

    Returns ``(skipped, message)``. ``skipped`` is True if the doc already
    existed and we did nothing.
    """
    filename = local_path.name
    storage_id = _build_storage_id(
        university=university,
        course=course,
        branch=branch,
        sem=sem,
        category=category,
        subject=subject,
        filename=filename,
    )

    if _firestore_doc_already_exists(
        client,
        university=university,
        course=course,
        branch=branch,
        sem=sem,
        category=category,
        subject=subject,
        storage_id=storage_id,
    ):
        return True, f"skip (already indexed): {storage_id}"

    # Upload to Storage
    blob = bucket.blob(storage_id)
    blob.upload_from_filename(str(local_path), content_type="application/pdf")
    size_mb = round(local_path.stat().st_size / (1024 * 1024), 2)

    # Write Firestore doc
    coll_path = (
        f"Universities/{university}/{course}/{branch}/{sem}/{category}/{subject}"
    )
    name_no_ext = local_path.stem
    doc_payload = {
        "name": name_no_ext,
        "subject": subject,
        "category": category,
        "university": university,
        "course": course,
        "branch": branch,
        "sem": sem,
        "storageId": storage_id,
        "rating": 0,
        "views": 0,
        "size": size_mb,
        "units": [],
        "date": SERVER_TIMESTAMP,
    }
    client.collection(coll_path).add(doc_payload)
    return False, f"uploaded: {storage_id} ({size_mb} MB)"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Upload a sem's PDFs to Firebase Storage + Firestore.",
    )
    parser.add_argument("--root", required=True, help="Local sem folder, e.g. ../IT/2")
    parser.add_argument("--university", required=True, help="e.g. OU")
    parser.add_argument("--course", required=True, help="e.g. BE")
    parser.add_argument("--branch", required=True, help="e.g. IT")
    parser.add_argument("--sem", required=True, help="e.g. 2")
    parser.add_argument(
        "--subjects",
        nargs="*",
        default=None,
        help="Optional: subset of subjects (folder names). Default: all.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="List what would be uploaded without writing anything.",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    subjects_filter = list(args.subjects) if args.subjects else None

    logger.info("root=%s", root)
    logger.info(
        "target=%s/%s/%s/%s subjects=%s dry_run=%s",
        args.university, args.course, args.branch, args.sem,
        subjects_filter or "(all)", args.dry_run,
    )

    _init_firebase()
    bucket = storage.bucket()
    client = firestore.client()

    n_uploaded = 0
    n_skipped = 0
    n_failed = 0

    for subject, category, pdf in _walk_pdfs(root, subjects_filter):
        if args.dry_run:
            logger.info(
                "  [DRY] %s / %s / %s",
                subject, category, pdf.name,
            )
            continue
        try:
            skipped, msg = _upload_one(
                bucket=bucket,
                client=client,
                local_path=pdf,
                university=args.university,
                course=args.course,
                branch=args.branch,
                sem=args.sem,
                category=category,
                subject=subject,
            )
            if skipped:
                n_skipped += 1
                logger.info("  %s", msg)
            else:
                n_uploaded += 1
                logger.info("  %s", msg)
        except Exception as exc:
            n_failed += 1
            logger.error("  FAIL %s/%s/%s: %s", subject, category, pdf.name, exc)

    logger.info(
        "done — uploaded=%d skipped=%d failed=%d", n_uploaded, n_skipped, n_failed
    )


if __name__ == "__main__":
    main()
