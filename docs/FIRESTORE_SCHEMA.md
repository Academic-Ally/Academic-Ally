# Firestore Schema — Current State (Phases 1+2+3 + Phase 4b PYQ Analyzer)

All 29 collections currently in use or declared. Every path defined in `lib/core/constants/firestore_paths.dart`.

**Rules status (2026-04-25):** `firestore.rules` checked into repo and deployed. Every collection that accepts writes has an explicit `allow read, write: if request.auth != null` rule block (close-circle demo policy). No catch-all wildcard. Phase 4 strict per-user rules still pending.

## University / Course Hierarchy

```
Universities:
├── JNTUH (Jawaharlal Nehru Technological University Hyderabad)
│   └── BTECH
└── OU (Osmania University)
    └── BE

Branches: IT, CSE, ECE, MECH, CIVIL, EEE, CSE AIML, CSE IOT
Semesters: 1–8
Resource Types: Notes, QuestionPapers, OtherResources, Syllabus
```

## Notification Topics

Format: `{university}_{course}_{branch}_{sem}` — e.g., `JNTUH_BTECH_CSE_3`. Branches with spaces (e.g., "CSE AIML") sanitized to `CSE-AIML`.

---

## Pre-existing Collections (from migration)

### `Users/{uid}`
```
{
  name, email, course, sem, branch, Year, university, college,
  pfp, sourceType ('MOBILE_APP'),
  premiumUser (bool), initiatedChats (int), messageCount (int),
  fcmToken, subscribeArray[], createdAt, lastUpdated
}
  └── NotesBookmarked/{noteId}     → bookmark data
  └── RatedList/{did}              → rating data
  └── UserUploads/{uploadId}       → upload metadata
  └── InitializedPdf/{pdfDocId}    → AllyBot chat sessions
  └── SeekHub/Requests             → user's request IDs
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
  storageId,   // FULL Firebase Storage path (or a legacy Drive file ID on old docs)
  did          // legacy alias
}
```

**Storage convention (LIVE):** `storageId` holds the **complete bucket-relative path** in Firebase Storage:
`Resources/{university}/{course}/{branch}/{sem}/{resourceType}/{subject}/{filename}.pdf`

Note the root is `Resources/`, **not** `Universities/` — the Firestore tree and the Storage tree
are rooted differently; don't conflate them.

The PDF viewer passes `storageId` straight to `FirebaseStorage.instance.ref(storageId).getDownloadURL()`
and streams the result into `flutter_pdfview`. Treat it as a whole path — never split it and use the
basename. Legacy docs from the React Native era have **no** `storageId`; the resource provider filters
those out so they never reach the UI.

### `QueryList/{university}/{course}/SubjectsListDetail`
```
{ list: [{ subjectName, sem, branch, ... }] }
```
⚠ Field is `subjectName` (capital N), NOT `subject`. `SubjectModel.fromMap` reads `subjectName` primary with `subject` fallback.

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

### `userReports/{university}/{course}/{branch}/{sem}/{uid}`
Abuse reports from PDF viewer. Shape:
```
{
  uid, email,
  report: { copyright: bool, misleading: bool, spam: bool },
  subjectName, subjectId, sCategory, sSubject,
  sUniversity, sCourse, sBranch, sSem, date
}
```

### Other Pre-existing
- `utils/meta-data` → App config (requiredVersion, dynamicLink, mailId, courses hierarchy)
- `UtilsProtected/meta-data` → Protected resources data
- `ImmutableUserData/{uid}` → Custom claims storage (`customClaims.admin`, `customClaims.branchManager`, etc.)
- `Premium_Users/{userId}` → Premium user data (higher rate limits)

---

## Phase 2 Collections (AI Features) — ALL BUILT ✅

### `Users/{uid}/Misconceptions/{nodeId}`
Per-user tagged misconceptions from the Knowledge Map practice sheet.
```
{
  description,           // Plain-English misconception description
  evidenceIds[],         // Question IDs that revealed this
  lastSeen (Timestamp),
  strength (0..1)        // How strongly the misconception is held
}
```
Written by `PracticeNotifier.submit()` after a wrong answer. `AIService.tagMisconceptions` produces these.

### `Users/{uid}/MasteryScores/{nodeId}`
Per-topic mastery tracked over time.
```
{
  score (0..1),          // EMA-style update: correct pulls toward 1
  attempts (int),        // Total practice count
  lastUpdated (Timestamp)
}
```
Written by `AIService.updateMastery()`. Streamed back into Knowledge Map UI via `userMasteryStreamProvider`.

### `Users/{uid}/StudyPlans/{planId}`
Full study schedule. Generated by `AIService.generateStudyPlan()`.
```
{
  examDate (Timestamp),
  subjects[],
  days: [{                 // Array of StudyDay
    date (Timestamp),
    tasks: [{              // Array of StudyTask
      subject, topic,
      durationMinutes,
      rationale,
      completed (bool)
    }]
  }],
  createdAt (Timestamp)
}
```
Task toggles update the whole `days` array via `toggleStudyTaskCompletion()` (Firestore can't update nested list index atomically).

### `PyqAnalysis/{university}/{course}/{branch}/{sem}/{subject}`
Shared analysis cache (not per-user — whole university/course cohort shares).
```
{
  subject,
  topicWeights: { topic -> 0..1 },
  predictedQuestions: [{
    question, topic, expectedMarks, likelihood, sourcePaperIds[]
  }],
  sourceResourceIds[],
  lastAnalyzed (Timestamp)
}
```
⚠ **No rule block for this collection in live Firestore rules — writes silently fail today.** Analyzer UI works (reads the cached doc if present, shows "Run Analysis" CTA if absent), but "Run Analysis" can't persist. Phase 4 fix, or one-line rule add to unblock pre-Phase 4.

### `Users/{uid}/DoubtHistory/{doubtId}`
Snap-a-Doubt solutions history.
```
{
  imageUrl,              // Phase 2: local file path. Phase 4: Firebase Storage URL
  extractedQuestion,
  steps: [{ index, description, latex? }],
  finalAnswer,
  topic, subject?,
  createdAt (Timestamp)
}
```

### `Users/{uid}/Projects/{projectId}`
Project Copilot state.
```
{
  title, brief,
  type ('major' | 'minor'),
  createdAt (Timestamp),
  cachedGuidance: {      // Map keyed by phase wire name
    ideation: ProjectGuidance,
    litReview: ProjectGuidance,
    scaffolding: ProjectGuidance,
    report: ProjectGuidance
  }
}

// ProjectGuidance shape:
{
  phase, summary, bullets[], nextSteps[], references[], codeSnippet?
}
```
Guidance is cached under `cachedGuidance.{phase.wire}` via dotted-path field update. Detail screen streams the doc so new guidance renders live.

### `KnowledgeGraph/{uni}/{course}/{subject}/nodes/{nodeId}` (DECLARED but UNUSED in Phase 2)
Admin-seeded topic graph. Live rules deny writes from client, so Phase 2 generates nodes client-side in `knowledgeNodesProvider` mirroring `MockAIService._topicsFor`. Phase 4 will seed this collection server-side and the provider will switch to stream from Firestore.

```
Planned shape:
{
  topic,
  subject,
  prerequisites: [nodeId],
  commonMisconceptions: [string]
}
```

---

## Phase 3 Collections (Community Features) — ALL BUILT ✅

### `Jobs/{jobId}`
Job/internship postings. Open to all authenticated users to post/read.
```
{
  title, company, location,
  type ('internship' | 'full-time' | 'part-time'),
  description,
  applyUrl,              // External URL (url_launcher opens it)
  tags[],
  postedBy (uid), postedByName,
  postedAt (Timestamp)
}
```

### `Channels/{channelId}`
Community chat channel metadata.
```
{
  name, description,
  createdBy (uid), createdByName,
  createdAt (Timestamp),
  messageCount (int),    // Best-effort increment on each message
  lastMessageAt (Timestamp)
}
```

### `Channels/{channelId}/Messages/{messageId}`
Individual chat messages (subcollection).
```
{
  text,
  authorUid, authorName,
  createdAt (Timestamp)
}
```
Live stream via `channelMessagesProvider` ordered by `createdAt` ascending.

### `Marketplace/{listingId}`
Buy/sell listings.
```
{
  title, description,
  priceInr (double),
  condition ('new' | 'like-new' | 'good' | 'fair'),
  category?,
  imageUrls[],           // Firebase Storage URLs (up to 5)
  sellerUid, sellerName,
  sellerPhone?,          // Digits-only; WhatsApp deep-link uses this
  createdAt (Timestamp)
}
```

---

## Firebase Storage Paths

### `Marketplace/{listingId}/{i}.jpg` — ACTIVE (Phase 3)
Listing images uploaded during `createListing()`. Up to 5 per listing. Pre-generated `listingId` so uploads happen before Firestore write.

### Planned for Phase 4
- `profile_pictures/{uid}/` — profile avatars (owner-write, public-read)
- `snap_a_doubt/{uid}/{doubtId}.jpg` — user-submitted doubt photos (swap from local file paths)

---

## Firestore Composite Indexes (needed for Phase 4 deploy)

| Collection | Fields | Purpose |
|---|---|---|
| `Channels/{id}/Messages` (collection group) | `createdAt asc` | Message ordering |
| `Marketplace` | `createdAt desc` | Newest listings first |
| `Jobs` | `postedAt desc` | Newest jobs first |
| `Users/{uid}/StudyPlans` | `createdAt desc` | User's plans newest first |
| `Users/{uid}/Projects` | `createdAt desc` | User's projects newest first |
| `Users/{uid}/DoubtHistory` | `createdAt desc` | Doubt history ordering |

Some of these may already exist in the Firebase Console — Phase 4 deploy should diff before creating duplicates.

---

## Per-Feature Backend Checklist

When building any feature (was followed in Phase 1, drifted in Phase 2-3 — Phase 4 catches up):
- [x] Add collection paths to `firestore_paths.dart` — DONE for all 27 collections
- [x] Write Dart model with `fromFirestore` / `toMap` — DONE
- [ ] Update `firestore.rules` for the new collection(s) — **DRIFTED, Phase 4 catches up**
- [ ] Update `firestore.indexes.json` if compound queries are used — **DRIFTED, Phase 4 catches up**
- [ ] Add Firebase Storage path constants if the feature uploads media — Marketplace done inline
- [ ] Smoke-test rules with emulator before deploy — Phase 4

## Rule Drift Summary (Phase 4 must address)

| Collection | Covered by live rules? | Action needed |
|---|---|---|
| `Users/{uid}/Misconceptions` | Via `Users/**` wildcard | Per-user ownership scoping |
| `Users/{uid}/MasteryScores` | Via `Users/**` wildcard | Per-user ownership scoping |
| `Users/{uid}/StudyPlans` | Via `Users/**` wildcard | Per-user ownership scoping |
| `Users/{uid}/DoubtHistory` | Via `Users/**` wildcard | Per-user ownership scoping |
| `Users/{uid}/Projects` | Via `Users/**` wildcard | Per-user ownership scoping |
| `PyqAnalysis/**` | ✅ DEPLOYED 2026-04-25 | Strict per-curriculum scoping (Phase 4 strict rules) |
| `KnowledgeGraph/**` | ✅ DEPLOYED 2026-04-25 | Admin-write, public-read |
| `Jobs/**` | ✅ DEPLOYED 2026-04-25 | Poster-owned writes, public-read |
| `Channels/**` | ✅ DEPLOYED 2026-04-25 | Auth-any writes, auth-any reads |
| `Marketplace/**` | ✅ DEPLOYED 2026-04-25 | Owner-scoped writes, public-read |
| `AnalysisRuns/{runId}` | ✅ DEPLOYED 2026-04-25 | Backend writes only (currently permissive) |
| `Premium_Users/**` | ✅ DEPLOYED 2026-04-25 | Admin writes only |

---

## Phase 4b — AnalysisRuns collection (LIVE)

### `AnalysisRuns/{runId}`
Ephemeral per-run progress tracker for the PYQ Analyzer multi-agent crew. Flutter subscribes to this doc in real time to render the progressive loading UI (5 agent checkmarks).

```
{
  runId: string (client-generated UUID),
  subject: string,
  status: 'running' | 'complete' | 'failed' | 'timeout',
  agents: {
    syllabus: 'pending' | 'done' | 'failed',
    webResearch: 'pending' | 'done' | 'failed',
    pattern: 'pending' | 'done' | 'failed',
    predictor: 'pending' | 'done' | 'failed',
    formatter: 'pending' | 'done' | 'failed',
  },
  errorMessage?: string,
  createdAt: serverTimestamp,
  completedAt?: serverTimestamp,
}
```

**Writes:** only by the Python backend (`cloud_run_revision/pyq_analyze` Cloud Run service) via the step_callback hook + explicit `mark_complete` / `mark_failed` calls.

**Reads:** by Flutter via `analysisRunProvider(runId)` StreamProvider — live doc subscription.

**Lifetime:** ~60–90 seconds during a run. Scheduled function `cleanup_old_trackers` deletes docs older than 1 hour every hour.

---

## Phase 4c — `RagChunks` vector store (LIVE)

### `RagChunks/{subject_key}/chunks/{chunkId}`

The retrieval corpus behind every AI feature. `subject_key` is
`{university}_{course}_{branch}_{sem}_{subject}` — one sub-collection per subject,
which keeps vector queries scoped and cheap.

```js
{
  text: string,            // 2000-char chunk (200-char overlap) from pdf_chunker.py
  embedding: Vector,       // 768-dim, gemini-embedding-001 (3072 truncated to 768)
  page: number,            // source page — powers clickable PDF citations
  pdfName: string,
  resourceId: string,      // ties the chunk back to its Universities/... doc
  subject: string,
  university: string,
  branch: string,
  sem: string,
}
```

**Written by:** `backend/scripts/upload_pdfs.py` at ingestion (embeddings use
`RETRIEVAL_DOCUMENT` task type).

**Read by:** `RagSearchTool` in every crew, via Firestore Vector Search
(`find_nearest`, COSINE) with `RETRIEVAL_QUERY` embeddings. AllyBot additionally
filters by `resource_id_filter` so chat stays scoped to the open PDF.

**⚠️ Requires a per-`subject_key` vector index.** Queries fail until the index
exists — created manually via Console/`gcloud` today. Automating this is an open
to-do; a subject with no index is the most common cause of "AI returns nothing".

---

## Cost Implications (ballpark)

- **Firestore operations:** Blaze ~$0.06 per 100K reads. Communities chat is the biggest risk (every message = 1 write + N client reads via stream). Mitigation: pagination + message limits already in place (200-message cap per channel).
- **Firebase Storage:** ~31 GB stored (6,481 PDFs) ≈ $0.80/month; egress ~$0.12/GB is the real variable. (R2 was evaluated as an egress escape hatch and ABANDONED — PDFs are served straight from Firebase Storage.)
- **FCM messages:** free for transactional pushes. Topic subscription is free.
- **AI costs (Phase 4b, PYQ only):** Gemini 2.5 Flash Lite ~$0.01–0.02 per analysis on paid tier. 200 requests/day free-tier quota = roughly 8–15 full PYQ runs/day before hitting the cap.
- **Tavily web search:** free tier is 1000 searches/month; each PYQ run uses 2–5 searches. Comfortable headroom.
