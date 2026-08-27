"""Audit the ENTIRE Firebase Storage bucket: total size, count, and breakdown
by top-level prefix. For the Resources/ prefix, also break down by
(uni, course, branch, sem) since that's where curriculum PDFs live.

Run from backend/:
    uv run python scripts/bucket_summary.py
"""
import os
import sys
from collections import defaultdict
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
from firebase_admin import storage  # noqa: E402

if not firebase_admin._apps:
    firebase_admin.initialize_app(
        options={"storageBucket": settings.backend_storage_bucket}
    )

bucket = storage.bucket()
print(f"Auditing bucket: {bucket.name}")
print("Listing all blobs...\n")

top_count = defaultdict(int)
top_bytes = defaultdict(int)
resources_combos = defaultdict(int)
resources_combo_bytes = defaultdict(int)
total_blobs = 0
total_bytes = 0

for blob in bucket.list_blobs():
    total_blobs += 1
    size = blob.size or 0
    total_bytes += size
    parts = blob.name.split("/")
    top = parts[0] if parts else "(root)"
    top_count[top] += 1
    top_bytes[top] += size
    if top == "Resources" and len(parts) >= 5:
        uni, course, branch, sem = parts[1], parts[2], parts[3], parts[4]
        resources_combos[(uni, course, branch, sem)] += 1
        resources_combo_bytes[(uni, course, branch, sem)] += size


def fmt_size(n):
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if n < 1024:
            return f"{n:.2f} {unit}"
        n /= 1024
    return f"{n:.2f} PB"


print("=" * 75)
print("OVERALL")
print("=" * 75)
print(f"  Total blobs:  {total_blobs}")
print(f"  Total size:   {fmt_size(total_bytes)}  ({total_bytes:,} bytes)")

print()
print("=" * 75)
print("BY TOP-LEVEL PREFIX")
print("=" * 75)
for top in sorted(top_count.keys(), key=lambda k: -top_bytes[k]):
    n = top_count[top]
    sz = top_bytes[top]
    print(f"  {top:25s}  {n:6d} blobs   {fmt_size(sz)}")

if resources_combos:
    print()
    print("=" * 75)
    print("Resources/ — by (uni, course, branch, sem)")
    print("=" * 75)
    for key in sorted(resources_combos.keys()):
        uni, course, branch, sem = key
        n = resources_combos[key]
        sz = resources_combo_bytes[key]
        print(f"  {uni} / {course} / {branch} / sem {sem}  --  {n} files  {fmt_size(sz)}")
