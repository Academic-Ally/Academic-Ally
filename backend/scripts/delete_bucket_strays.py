"""Delete the 4 stray bucket prefixes confirmed inert by audit_bucket_strays.py.

Prefixes deleted:
  Universities/                   20 blobs, ~82 MB  (RN-era community uploads)
  OU/                             18 blobs, ~29 MB  (RN-era stray)
  JNTUH/                           3 blobs, ~19 MB  (RN-era stray)
  2023-07-05T03:50:23_34529/       9 blobs, ~4 MB   (Firestore backup export)

All confirmed to have ZERO Firestore docs referencing them.
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
from firebase_admin import storage  # noqa
if not firebase_admin._apps:
    firebase_admin.initialize_app(options={"storageBucket": settings.backend_storage_bucket})

bucket = storage.bucket()

STRAY_PREFIXES = [
    "Universities/",
    "OU/",
    "JNTUH/",
    "2023-07-05T03:50:23_34529/",
]

total_deleted = 0
total_bytes = 0
for prefix in STRAY_PREFIXES:
    print(f"\n[{prefix}]")
    blobs = list(bucket.list_blobs(prefix=prefix))
    print(f"  Found {len(blobs)} blob(s) to delete")
    for blob in blobs:
        sz = blob.size or 0
        try:
            blob.delete()
            total_deleted += 1
            total_bytes += sz
        except Exception as e:
            print(f"    [ERROR] {blob.name}: {e}")
    print(f"  Done.")

print()
print("=" * 60)
print(f"  Total deleted: {total_deleted} blobs / {total_bytes / 1024 / 1024:.2f} MB")
