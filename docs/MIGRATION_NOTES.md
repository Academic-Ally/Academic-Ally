# RN → Flutter Migration Notes

## What Stays the Same

- Firebase backend (Firestore, Auth, Storage, Messaging)
- Cloud functions (Netlify serverless — Chat + Notifications APIs)
- Firestore schema and collections
- Business logic and feature set

## What Changed

| Concern | React Native | Flutter |
|---------|-------------|---------|
| UI framework | React Native + NativeBase | Flutter + Material Design 3 |
| State management | Redux Toolkit | Riverpod 3.x (Notifier pattern) |
| Navigation | React Navigation | GoRouter (ShellRoute for bottom nav) |
| PDF storage | Storj (access lost) | Cloudflare R2 (to be configured) |
| PDF viewing | react-native-pdf | flutter_pdfview |
| Local storage | AsyncStorage | SharedPreferences + dart:io filesystem |
| File handling | react-native-fs | path_provider + dart:io |
| Forms | Formik + Yup | Flutter built-in Form/TextFormField |
| Animations | Lottie React Native | lottie (Flutter) |
| Deep linking | Firebase Dynamic Links | TBD (app_links or Firebase Dynamic Links Flutter) |

## Migration Status (as of 2026-04-18)

**Complete:** All 15 screens migrated (14 features + splash), 45 Dart files, 6 data models, 9 feature providers, 17 routes, zero analysis issues. Custom launcher icon + native/Dart splash screens. Release APK built and tested on device.

**Remaining:**
- Infrastructure: Cloudflare R2 wiring, ChatPDF/LLM wiring (Phase 4)
- Features to build: FCM push notifications, deep linking (Phase 1)

**NOT a "just hook up storage and we're done" situation** — real features and AI layer still to build. See `AI_PIVOT_PLAN.md` for what's next.

## UI Reference (RN → Flutter mapping)

The original RN UI code is at `Academic-Ally-master/src/screens/`. Flutter screens were **remastered** to match the original look: purple header (#6360FF) with rounded body (#F1F1FA, borderRadius 30).

| RN Screen | Flutter Screen | Status |
|-----------|---------------|--------|
| authScreen.tsx / LoginScreen.tsx | login_screen.dart | Done (with white-logo.png) |
| SignUpScreen.tsx | signup_screen.dart | Done (university/course/branch/sem dropdowns) |
| homeScreen.tsx | home_screen.dart | Done (QuickAccess wired, Recommended from Firestore) |
| searchScreen.tsx | search_screen.dart | Done (Firestore search + branch/sem filters) |
| SubjectResourcesScreen.tsx | subject_resources_screen.dart | Done (4 resource type cards) |
| NotesListScreen.tsx | resources_list_screen.dart | Done (resource cards with views/rating) |
| pdfViewerScreen.tsx | pdf_viewer_screen.dart | Done (download/bookmark/rate/share/AllyBot/report) |
| AllyBotScreen.tsx | allybot_screen.dart + ally_chat_screen.dart | Done (chat UI + message bubbles) |
| SeekHubScreen.tsx | seekhub_screen.dart + create_request_screen.dart | Done (requests + create form) |
| Bookmark.tsx | bookmarks_screen.dart | Done (Firestore stream, grouped, swipe-to-delete) |
| RecentScreen.tsx | recents_screen.dart | Done (SharedPreferences, time-ago) |
| DownloadScreen.tsx | downloads_screen.dart | Done (filesystem management) |
| uploadScreen.tsx | upload_screen.dart | Done (form + Firestore NewUploads) |
| profile.tsx | profile_screen.dart + update_profile_screen.dart | Done (display + edit) |
| OnBoardingScreen.tsx | onboarding_screen.dart | Done (4 slides matching RN, no skip button) |
| ReportActionSheet.tsx | report_bottom_sheet.dart | Done (3 reasons + mailto fallback) |
