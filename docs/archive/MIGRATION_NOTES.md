# RN → Flutter Migration Notes

## Migration Status — COMPLETE (and then some)

The RN → Flutter migration is fully done. The app now has more features than the original RN version because of the Phase 1/2/3 build.

## What Stays the Same (vs original RN)

- Firebase backend (Firestore, Auth, Storage, Messaging) — unchanged, same project `academic-ally-app`
- Firestore schema for pre-existing collections — unchanged
- Business logic and feature set for the core 15 screens — preserved
- Brand identity — same purple header pattern, Poppins font, #6360FF primary

## What Changed

| Concern | React Native | Flutter |
|---------|-------------|---------|
| UI framework | React Native + NativeBase | Flutter + Material Design 3 |
| State management | Redux Toolkit | Riverpod 3.x (Notifier pattern) |
| Navigation | React Navigation | GoRouter (ShellRoute for bottom nav) |
| PDF storage | Storj (access lost) | **Cloudflare R2** (planned for Phase 4) |
| PDF viewing | react-native-pdf | `flutter_pdfview` |
| Local storage | AsyncStorage | SharedPreferences + dart:io filesystem |
| File handling | react-native-fs | path_provider + dart:io |
| Forms | Formik + Yup | Flutter built-in Form/TextFormField |
| Animations | Lottie React Native | lottie (Flutter) |
| Deep linking | Firebase Dynamic Links | `app_links` (custom scheme + universal links) |
| Push notifications | `@react-native-firebase/messaging` | `firebase_messaging` (with 3-layer idempotency fix for the loop bug) |
| Image picking | react-native-image-picker | `image_picker` |

## What's new (not in RN original)

All the Phase 2 AI features + Phase 3 community features are new — they didn't exist in the RN app:

**AI features (built on mocks, Phase 4 will wire Gemini):**
- Knowledge Map / Misconception Graph
- Study Planner
- Gen UI
- PYQ Analyzer
- Snap-a-Doubt
- Project Copilot

**Community features (live on real Firestore):**
- Jobs & Internships (with external apply links)
- Communities & Channels (real-time chat)
- Marketplace (with Firebase Storage image uploads + WhatsApp seller contact)

**Infrastructure improvements:**
- Onboarding with Skip button (original didn't have Skip… wait, it did — we added it back after the 2026-04-19 session dropped it)
- Deep linking with pending-link queue for pre-auth users + FCM-tap bridge
- FCM with three-layer idempotency fix for the Users/{uid} sync-loop bug
- Firebase billing cap Cloud Function (₹200/month safety net)
- Auth-gated Storage rules (replaces Firebase default wide-open scaffold)

## Migration Stats

| Metric | Original RN | Current Flutter |
|---|---|---|
| Screens | ~15 | ~34 |
| Features | 15 | 27 |
| Dart/TS files | ~45 TS | ~80 Dart |
| Data models | 6 | 11 |
| Firestore collections | 10 | 27 |
| Routes | ~15 | 31 |
| Analyzer issues | — | 0 |

## UI Reference (RN → Flutter mapping, pre-existing screens)

Flutter screens were remastered to match the original look: purple header (#6360FF) with rounded body (#F1F1FA, borderRadius 30). Subsequent Phase 2/3 screens follow the same pattern.

| RN Screen | Flutter Screen | Status |
|-----------|---------------|--------|
| authScreen.tsx / LoginScreen.tsx | login_screen.dart | Done |
| SignUpScreen.tsx | signup_screen.dart | Done |
| homeScreen.tsx | home_screen.dart | Done + Phase 2/3 sections added |
| searchScreen.tsx | search_screen.dart | Done |
| SubjectResourcesScreen.tsx | subject_resources_screen.dart | Done |
| NotesListScreen.tsx | resources_list_screen.dart | Done |
| pdfViewerScreen.tsx | pdf_viewer_screen.dart | Done (+ report bottom sheet in Phase 1) |
| AllyBotScreen.tsx | allybot_screen.dart + ally_chat_screen.dart | Done (+ Phase 4 will swap backend to Gemini) |
| SeekHubScreen.tsx | seekhub_screen.dart + create_request_screen.dart | Done |
| Bookmark.tsx | bookmarks_screen.dart | Done |
| RecentScreen.tsx | recents_screen.dart | Done |
| DownloadScreen.tsx | downloads_screen.dart | Done |
| uploadScreen.tsx | upload_screen.dart | Done |
| profile.tsx | profile_screen.dart + update_profile_screen.dart | Done |
| OnBoardingScreen.tsx | onboarding_screen.dart | Done (4 slides with Skip button) |
| ReportActionSheet.tsx | report_bottom_sheet.dart | Done |

## Critical cross-cutting fixes applied during migration

1. **`SubjectModel.fromMap` reads `subjectName` (capital N), not `subject`.** Production data uses `subjectName` (confirmed from web app). The RN Redux store accidentally worked because of a different field-name mapping. Flutter initially didn't, so `recommendedSubjectsProvider` returned empty lists. Fixed in Phase 2.

2. **Legacy `sem` can be int or string.** Always `.toString()` when parsing from Firestore. Applied to SubjectModel and UserModel parsing.

3. **FCM topic names don't allow spaces.** Branches like "CSE AIML" need sanitization. `FcmService.buildTopic()` regex-replaces non-allowed chars with hyphen.

4. **FCM infinite-loop bug** — documented separately in `feedback_fcm_loop_bug.md` memory. Three-layer idempotency fix: listener guard (curriculum tuple), service-level token check, fast-path topic matching.

## What's left (not Phase 4 — actual migration tech debt)

Nothing blocking. The migration is complete. Phase 4 is a separate "make it production-ready" phase, not migration cleanup.

## Related docs

- `AI_PIVOT_PLAN.md` — the 4-phase build plan (Phases 1-3 complete, Phase 4 remaining)
- `ARCHITECTURE.md` — deep dive into folder structure, routes, dependencies
- `FIRESTORE_SCHEMA.md` — every collection used today
- `FIREBASE_AUDIT.md` — rules, indexes, deploy workflow
- `REACT_NATIVE_REFERENCE.md` — pointers to the dormant RN codebase for reference
- `WEB_REFERENCE.md` — pointers to the dormant web app for reference
- `CLOUD_FUNCTIONS.md` — Netlify + Firebase function inventory
