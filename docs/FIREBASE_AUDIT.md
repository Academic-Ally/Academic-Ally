# Firebase Audit Findings (2026-04-18)

First audit of the Firebase project was performed on 2026-04-18.

## What was missing from the repo

- No `firebase.json`, no `.firebaserc` — rules and indexes were never kept in source control
- No `firestore.rules` — existed only in the Firebase Console, not reviewable/versionable
- No `firestore.indexes.json` — same story; indexes existed only in the Console
- No `storage.rules` — Firebase Storage rules also Console-only

## What exists in the project

- Firebase CLI installed (v15.14.0), authenticated, project `academic-ally-app` visible
- `academic_ally/android/app/google-services.json` present and correct
- iOS Firebase config placeholder only (no Mac to build)
- Cloud Functions (Netlify) use Firebase Admin SDK, which **bypasses Firestore rules by design** — all server-side writes are trusted
- **Firebase plan:** Spark (free tier). Firestore Export to GCS + Firebase Cloud Functions require Blaze upgrade.

## Live Firestore state at time of audit

5 indexes + 1 field override currently deployed:
- `BE` / `BTECH` collection groups indexed on `(status, date)` — SeekHub requests
- `InitializedPdf` collection group indexed on `(docId, date)` — AllyBot chat sessions
- `SeekHub` collection group indexed on `(APP, SeekHub)` — appears leftover/unused
- ⚠ `"undefined"` collection group indexed on `(status, date)` — **this is a bug leak**: a JS `undefined` value ended up in a collection path at runtime, and Firestore auto-created an index. Should be cleaned up from the Console.
- `Chemistry` field override on `category` — one-off experiment, likely dead

Live rules could not be pulled via REST API due to CLI OAuth token scope limitations. **Before deploying the new `firestore.rules`, the user must manually diff the drafted rules against the live rules in Firebase Console** (`console.firebase.google.com/project/academic-ally-app/firestore/rules`) to avoid regressing any custom logic.

## Files added to fix the audit gaps (in `academic_ally/`)

- `firebase.json` — Firebase CLI config pointing to rules/indexes/storage files + emulator ports
- `.firebaserc` — default project = `academic-ally-app`
- `firestore.rules` — release-grade deny-by-default rules covering all current + planned Phase 2/3 collections. Uses custom claims (`request.auth.token.admin`) for admin checks — requires setting custom claims via Admin SDK on a trusted server.
- `firestore.indexes.json` — current queries + anticipated indexes for Jobs, Marketplace, Channel messages
- `storage.rules` — deny-by-default rules for profile pictures, Snap-a-Doubt, marketplace images, channel attachments

## Deploy workflow (deferred to Phase 4 per user decision)

```bash
cd "C:/Devspace/flutterprojects/Academic Ally/academic_ally"

# Validate + deploy individual concerns
firebase deploy --only firestore:rules --project academic-ally-app
firebase deploy --only firestore:indexes --project academic-ally-app
firebase deploy --only storage --project academic-ally-app

# OR deploy all at once
firebase deploy --only firestore,storage --project academic-ally-app
```

## Post-deploy sanity checks

- Run the Flutter app end-to-end: login, bookmark, rate, report, upload (via NewUploads), open AllyBot chat — all must work without permission-denied errors
- Open Firebase Console → Firestore → Rules → Simulator, test representative paths
- Watch Firebase Crashlytics / Flutter logs for `PERMISSION_DENIED` errors in first 24h

## Tech-debt items flagged (non-blocking but should be fixed)

- Delete the rogue `undefined` collectionGroup index from Firebase Console
- Delete the unused `SeekHub (APP, SeekHub)` index if confirmed dead
- Delete the `Chemistry.category` field override if unused
- Set up Firebase custom claims assignment (Cloud Function that writes `admin: true` to selected uids) — without this, `isAdmin()` in rules always returns false. **Required before launching Phase 3.**
- Add Firebase Crashlytics to `academic_ally/pubspec.yaml` for production error tracking
- Add Firebase Remote Config for feature flags (gate AI features per tier)

## Baseline Snapshot (pending)

Before enabling Firebase MCP with full production write access, create `academic_ally/firebase_snapshot/YYYY-MM-DD_baseline/` containing:
- `indexes.live.json` — current deployed indexes (pulled via CLI)
- `firestore.rules.live` — user pastes from Console (CLI can't pull due to scope)
- `storage.rules.live` — user pastes from Console
- `collections.md` — top-level collections + sample doc shapes
- `apps-config.md` — `firebase apps:list` output
- `RESTORE.md` — step-by-step revert instructions
