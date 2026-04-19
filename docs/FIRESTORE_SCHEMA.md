# Firestore Schema — Current + Planned

Current collections in production + all new collections planned for AI pivot and Phase 3 features.

## University / Course Hierarchy

```
Universities:
├── JNTUH (Jawaharlal Nehru Technological University Hyderabad)
│   └── BTECH
└── OU (Osmania University)
    └── BE

Branches: IT, CSE, ECE, MECH, CIVIL, EEE
Semesters: 1–8
Resource Types: Notes, QuestionPapers, OtherResources, Syllabus
```

## Notification Topics

Format: `{university}_{course}_{branch}_{sem}` — e.g., `JNTUH_BTECH_CSE_3`

---

## Current Collections (Production)

### `Users/{uid}`
```
{
  name, email, course, sem, branch, Year, university, college,
  pfp (profile picture URL), sourceType ('MOBILE_APP'),
  premiumUser (boolean), initiatedChats (number), messageCount (number),
  fcmToken, subscribeArray[], createdAt, lastUpdated
}
  └── NotesBookmarked/{noteId}     → bookmark data
  └── RatedList/{did}              → rating data
  └── UserUploads/{uploadId}       → upload metadata
  └── InitializedPdf/{pdfDocId}    → AllyBot chat sessions
      { sourceId, url, conversation[], createdAt, lastUpdated }
  └── SeekHub/Requests             → user's SeekHub request IDs
```

### `Universities/{university}/{course}/{branch}/{sem}/`
```
  └── SubjectsList (doc)           → { Notes: bool, QuestionPapers: bool, ... } per subject
  └── Notes/{subject}/{docId}      → resource documents
  └── QuestionPapers/{subject}/{docId}
  └── OtherResources/{subject}/{docId}
  └── Syllabus/{subject}/{docId}
```

**Resource Document shape:**
```
{
  name, subject, category, rating, views, uploaderId, uploaderName,
  size, sem, branch, date, units,
  storageId,  // Google Drive file ID (Phase 2 demo storage)
  did         // legacy alias for storageId (older web-uploaded records)
}
```

**Storage (Phase 2 demo):** `storageId` (or legacy `did`) holds a Google Drive file ID. The Flutter PDF viewer embeds `https://drive.google.com/file/d/<storageId>/preview` in a WebView. Files must be "Anyone with link can view" on Drive. Download button opens `https://drive.google.com/uc?export=download&id=<storageId>` in the system browser.

**Phase 4 migration path:** add a `storageType` field ('drive' | 'r2') or swap `storageId` semantics to an R2 path after a bulk migration script runs. PDF viewer will branch on `storageType` to pick WebView vs native renderer.

### `QueryList/{university}/{course}/SubjectsListDetail`
```
{ list: [{ subject, sem, branch }] }   → quick lookup for search/recommendations
```

### `SeekHub/{university}/{course}/{requestId}`
```
{
  id (uuid), subject, category, seekerName, seekerUid, seekerPhoto,
  sem, branch, course, university, requestedOn, date,
  status ('pending' | 'fulfilled'), notifyList[]
}
```

### `NewUploads/{university}/{course}/{branch}/uploads/{docId}`
```
{
  name, uploaderName, uploaderEmail, uploaderId, subject, category,
  units, pfp, date, storageId, university, course, branch, sem
}
```

### Other Collections
- `utils/meta-data/` → App config (requiredVersion, dynamicLink, mailId, courses hierarchy)
- `UtilsProtected/meta-data/` → Protected resources data
- `ImmutableUserData/{uid}/` → Custom claims / user permissions
- `userReports/{university}/{course}/{branch}/{sem}/{uid}/` → Abuse reports
- `Premium_Users/{userId}` → Premium user data (higher rate limits)

---

## Planned Collections — AI Features (Phase 2)

| Feature | Collections / Document shape |
|---------|------------------------------|
| **Misconception Graph** | `KnowledgeGraph/{university}/{course}/{subject}/nodes/{nodeId}` — `{topic, prerequisites[], commonMisconceptions[]}`. `Users/{uid}/Misconceptions/{nodeId}` — `{misconceptionIds[], lastSeen, strength}`. `Users/{uid}/MasteryScores/{nodeId}` — `{score, attempts, lastUpdated}` |
| **Study Planner** | `Users/{uid}/StudyPlans/{planId}` — `{examDate, subjects[], dailyTasks[], progress, createdAt}` |
| **PYQ Analyzer** | `PyqAnalysis/{university}/{course}/{branch}/{sem}/{subject}` — `{topicWeights{}, predictedQuestions[], lastAnalyzed, sourceResourceIds[]}` (cache to avoid re-running expensive LLM calls) |
| **Snap-a-Doubt** | `Users/{uid}/DoubtHistory/{doubtId}` — `{imageUrl, extractedQuestion, solution, topic, subject, createdAt}` |
| **Project Copilot** | `Users/{uid}/Projects/{projectId}` — `{title, description, phase, ideation, litReview, scaffolding, reportDraft, createdAt, lastUpdated}` |
| **Gen UI** | Runtime-only; no schema needed. Optional: `Users/{uid}/GenUIHistory/{sessionId}` for session replay |

---

## Planned Collections — Non-AI Features (Phase 3)

| Feature | Collections / Document shape |
|---------|------------------------------|
| **Communities & Channels** | `Channels/{channelId}` — `{name, topic, description, memberCount, admins[], createdAt}`. `Channels/{channelId}/Messages/{messageId}` — `{senderId, text, attachments[], createdAt}`. `Users/{uid}/JoinedChannels/{channelId}`. ⚠ **Heavy write volume — evaluate Firebase Realtime Database or a dedicated chat service vs Firestore** |
| **Jobs & Internships** | `Jobs/{jobId}` — `{title, company, location, type, description, applyUrl, deadline, postedBy, createdAt}`. `Users/{uid}/SavedJobs/{jobId}`. Admin-only write rules |
| **Marketplace** | `MarketplaceListings/{listingId}` — `{sellerId, title, description, price, condition, subject, category, imageUrls[], status, createdAt}`. `MarketplaceListings/{listingId}/Messages/{messageId}` (buyer-seller chat). `Users/{uid}/MyListings/{listingId}`. Needs Firebase Storage paths for listing images |

---

## Cross-Cutting Concerns

### Firestore Composite Indexes

Required for compound queries (`firestore.indexes.json`):
- MarketplaceListings: `(subject, price, createdAt)` for filtered browse
- Jobs: `(type, deadline, createdAt)` for active-jobs feed
- Channel Messages: `(channelId, createdAt)` for paginated chat history
- PyqAnalysis: `(university, course, branch, sem)` for lookup

### Firebase Storage Paths (in addition to R2 for PDFs)

- `profile_pictures/{uid}/` — profile avatars (owner-write, public-read)
- `snap_a_doubt/{uid}/{doubtId}.jpg` — user-submitted doubt photos (owner-only)
- `marketplace/{sellerId}/{listingId}/{imageIndex}.jpg` — listing images (seller-write, auth-read)
- `channels/{channelId}/attachments/{senderId}/{fileName}` — community chat attachments

### Cost Implications

Firestore pricing (reads/writes/deletes/storage). Spark (free) tier: 50K reads/day, 20K writes/day. At scale:
- **Communities chat** is the biggest cost risk (every message = 1 write + N reads for participants)
- **Misconception Graph** updates hit per-quiz (moderate)
- **Gen UI** uses LLM, not Firestore — different cost vector
- Mitigation: Firestore bundle for static data (subjects list), pagination everywhere, caching layer

### Per-Feature Backend Checklist (bundled with feature build)

When building any feature:
- [ ] Add collection paths to `firestore_paths.dart`
- [ ] Write Dart model with `fromFirestore` / `toMap`
- [ ] Update `firestore.rules` for the new collection(s)
- [ ] Update `firestore.indexes.json` if compound queries are used
- [ ] Add Firebase Storage path constants if the feature uploads media
- [ ] Smoke-test rules with emulator before deploy

### Infrastructure Prep (one-time, before Phase 2 starts)

- [x] Audit current `firestore.rules` — DONE 2026-04-18 (see FIREBASE_AUDIT.md)
- [x] Create `firestore.indexes.json` — DONE 2026-04-18
- [x] Create `firebase.json` + `.firebaserc` + `storage.rules` — DONE 2026-04-18
- [ ] Deploy rules (deferred to Phase 4 per user decision)
- [ ] Set up Firebase Custom Claims Cloud Function (required for `isAdmin()` to work)
- [ ] Clean up rogue Firestore indexes (`undefined` collectionGroup, unused `SeekHub (APP, SeekHub)`, `Chemistry.category` override)
- [ ] Add Crashlytics to pubspec + Android/iOS config
- [ ] Add Remote Config to pubspec
- [ ] Decide: Firebase Cloud Functions alongside Netlify? (yes for Firestore triggers)
