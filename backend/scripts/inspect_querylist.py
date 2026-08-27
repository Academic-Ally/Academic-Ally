"""One-off: dump QueryList/{uni}/{course}/SubjectsListDetail schema."""
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

import json

uni, course = sys.argv[1], sys.argv[2]
doc_path = f"QueryList/{uni}/{course}/SubjectsListDetail"
print(f"Reading doc: {doc_path}\n")
doc = db.document(doc_path).get()
if not doc.exists:
    print("  Doc does not exist.")
    # Try child collections of the doc
    parent = db.document(f"QueryList/{uni}/{course}")
    print(f"  Listing collections under QueryList/{uni}/{course}/ ...")
    for c in parent.collections():
        print(f"    collection: {c.id}")
    sys.exit(0)
data = doc.to_dict() or {}
print(f"Top-level keys ({len(data)}):")
for k in list(data.keys())[:50]:
    v = data[k]
    desc = type(v).__name__
    if isinstance(v, list):
        desc = f"list[{len(v)}]"
        if v and isinstance(v[0], dict):
            desc += f"  first item keys: {list(v[0].keys())[:6]}"
    elif isinstance(v, dict):
        desc = f"dict[{len(v)}]  keys: {list(v.keys())[:6]}"
    print(f"  {k}  ({desc})")

# If there's clearly a structure, sample one branch's payload
sample_key = None
for k in data:
    if k.lower() in ("it", "cse", "ece", "mech", "civil", "eee"):
        sample_key = k
        break
if sample_key:
    print(f"\n--- Sample: data[{sample_key!r}] ---")
    print(json.dumps(data[sample_key], indent=2, default=str)[:3000])
