# Firebase Audit — Current State (2026-04-20)

Tracks the state of Firebase artifacts (rules, indexes, config) in the repo and deployed in production.

## What's in the repo now

- **`firebase.json`** — Firebase CLI config. Currently points to: `functions/` codebase + `storage.rules` file
- **`functions/`** — Firebase Cloud Function: `stopBilling` (₹200/month auto-disable)
- **`storage.rules`** — Auth-gated rules (DEPLOYED 2026-04-20 via `firebase deploy --only storage`)
- ❌ `firestore.rules` — NOT in repo. Live rules live only in Firebase Console, permissive, pending Phase 4 rewrite
- ❌ `firestore.indexes.json` — NOT in repo. Live indexes live only in Console
- ❌ `.firebaserc` — NOT in repo (CLI uses `--project academic-ally-app` explicitly)

## Firebase project state

- **Firebase CLI:** v15.14.0 installed + logged in. `academic-ally-app` is current project.
- **Firebase plan:** **Blaze (pay-as-you-go)** — upgraded 2026-04-19
- **Billing cap:** ₹200/month via `stopBilling` Cloud Function (deployed)
- **Services available:** Auth ✅ · Firestore ✅ · Storage ✅ · Messaging ✅ · Analytics ✅ · Cloud Functions ✅

## Currently deployed rules

### Firestore (unchanged — still Console-only, permissive)

Read/write permissive rules for every authenticated-user collection. Key issues:

1. **`ImmutableUserData` helper functions are broken.** Uses `{document}` in function body as literal text, not a variable binding. Always evaluates false for admin writes. Low priority because no admin writes from client.

2. **`Users/{document=**}` wildcard is wide open.** Any authenticated user can read/write/delete any other user's profile + subcollections (including PII like `fcmToken`, `email`).

3. **`PyqAnalysis` has NO match block.** Firestore default is deny, so PYQ Analyzer "Run Analysis" writes fail silently. Known issue.

4. **`utils/{document=**}` has public read** (no auth required). If this holds only splash/config data, fine. If anything sensitive (admin lists, API keys), that's a leak. Verify contents.

5. **Hardcoded admin UID in `Test` collection** is brittle — should use a proper admin check via `isAdmin()` once helper functions are fixed.

### Storage (DEPLOYED 2026-04-20)

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

Replaces the default `allow read, write;` (wide open to the internet). Now only authenticated users can upload/read. Marketplace uploads work on this rule. Phase 4 will further scope to path-ownership + MIME + size.

## Deployed indexes

5 indexes + 1 field override (from pre-Blaze audit):
- `BE` / `BTECH` collection groups indexed on `(status, date)` — SeekHub requests
- `InitializedPdf` collection group indexed on `(docId, date)` — AllyBot chat sessions
- `SeekHub` collection group indexed on `(APP, SeekHub)` — appears leftover
- ⚠ `"undefined"` collection group indexed on `(status, date)` — bug leak (runtime undefined path)
- `Chemistry` field override on `category` — one-off experiment, likely dead

**Still need to add for Phase 2/3 collections:**
- `Channels/{id}/Messages` → `createdAt asc` (real-time chat ordering)
- `Marketplace` → `createdAt desc`
- `Jobs` → `postedAt desc`
- `Users/{uid}/StudyPlans` → `createdAt desc`
- `Users/{uid}/Projects` → `createdAt desc`
- `Users/{uid}/DoubtHistory` → `createdAt desc`

These are used by stream providers across Phase 2-3 features. Some may auto-create indexes on first query failure via the Firebase Console's "Create Index" link in error logs.

## Phase 4 deploy workflow (not yet executed)

```bash
cd "C:/Devspace/flutterprojects/Academic Ally/academic_ally"

# 1. Diff drafted rules against live first (paste live rules from Console into a local file, diff)
# 2. Then deploy
firebase deploy --only firestore:rules --project academic-ally-app
firebase deploy --only firestore:indexes --project academic-ally-app
firebase deploy --only storage --project academic-ally-app

# OR deploy all at once
firebase deploy --only firestore,storage --project academic-ally-app
```

## Post-deploy sanity checks (Phase 4)

- Run the Flutter app end-to-end: login, bookmark, rate, report, upload (via NewUploads), open AllyBot chat, all Phase 2 AI features, Jobs browse, channel message, Marketplace listing creation with photo — all must work without `PERMISSION_DENIED` errors
- Open Firebase Console → Firestore → Rules → Simulator, test representative paths:
  - Read your own `Users/{uid}` doc (allowed)
  - Read another user's `Users/{uid}` doc (denied post-Phase 4)
  - Write to `Jobs/{any}` (allowed for any authenticated user)
  - Write to `Users/{uid}/StudyPlans/{any}` (allowed only when uid matches auth)
- Watch Firebase Crashlytics / Flutter logs for `PERMISSION_DENIED` errors in first 24h of testing

## Tech-debt items (non-blocking but should be fixed)

- Delete the rogue `undefined` collectionGroup index
- Delete the unused `SeekHub (APP, SeekHub)` index if confirmed dead
- Delete the `Chemistry.category` field override if unused
- Set up Firebase Custom Claims assignment Cloud Function — needed before `isAdmin()` rules work
- Add Firebase Crashlytics to `pubspec.yaml` for production error tracking
- Add Firebase Remote Config for feature flags (gate AI features per tier)

## Cloud Functions

### Deployed
- `stopBilling` — in `functions/index.js`, auto-disables billing when monthly spend crosses ₹200. Verified end-to-end 2026-04-19 (IAM + Pub/Sub + topic link).
- Legacy functions from prior dev (discovered 2026-04-19): `chatMessage`, `initiateChat`, `sendNotification`, `sendMessageToTopic`, `resetPdfCountDaily` — all in `us-central1`, Node 18 (deprecating soon). Status unclear; re-investigate when Phase 4 wires real AllyBot / notifications.

### Planned for Phase 4
- **Custom Claims function** — grants `admin: true` / `branchManager: true` to selected UIDs via Admin SDK. Required for `isAdmin()` in rules.
- **Gemini proxy** — calls Gemini API server-side to keep API key off-device. `GeminiAIService` client calls this endpoint.
- **Channel message counter** — trigger on message create to atomically bump `messageCount` (currently done client-side best-effort).

## Baseline Snapshot (pending Phase 4)

Before deploying strict rules, should create `academic_ally/firebase_snapshot/{date}_pre-phase4/` with:
- `indexes.live.json` — current deployed indexes
- `firestore.rules.live` — user pastes from Console
- `storage.rules.live` — the auth-gated rule from 2026-04-20
- `collections.md` — top-level collections + sample doc shapes
- `RESTORE.md` — revert instructions if Phase 4 deploy breaks anything
