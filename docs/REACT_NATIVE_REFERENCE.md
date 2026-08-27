# React Native Reference — `../Academic Ally Legacy/Academic-Ally-master/` (DORMANT)

The **original** React Native app, published on Google Play Store. **Dormant** — kept in the workspace solely as UI/behavior reference for the Flutter migration. Do not modify unless explicitly asked.

## Tech Stack

React Native 0.71.11, TypeScript, Firebase, Redux Toolkit, NativeBase, React Navigation

## App Identity

- **Package name:** `com.academically`
- **Display name:** Academic Ally
- **Version:** 0.0.8
- **Deep links:** `academically://`, `https://app.getacademically.co/`, `https://getacademically.co`
- **CI/CD:** Codemagic

## Navigation Structure

```
BootScreen → checks auth state
  ├── AuthScreen (Login / SignUp / ForgotPassword)
  └── BottomTabNavigator
        ├── Home
        ├── Search
        ├── Upload
        ├── Bookmark
        └── Profile
      + DrawerNavigator (Home)
      + Stack screens: SubjectResources, PdfViewer, AllyBot, SeekHub, Recents, Downloads, etc.
```

## Features

| Feature | Description |
|---------|-------------|
| **Authentication** | Email/password via Firebase Auth. Email verification. Password reset. |
| **Home** | Welcome greeting, quick access categories, recommended resources, theme toggle (light/dark) |
| **Notes/Resources** | Browse by university → course → branch → semester → subject. Four types: Notes, Question Papers, Other Resources, Syllabus |
| **PDF Viewer** | In-app PDF rendering, download for offline, view count tracking, rating, reporting, sharing via dynamic links |
| **AllyBot** | AI chat about PDF documents. Uses ChatPDF API. Conversation history stored in Firestore. |
| **SeekHub** | Community resource requests — students can request specific materials, others can fulfill them. Push notifications to subscribers. |
| **Upload** | Upload PDFs with metadata (subject, category, units). Goes to `NewUploads` collection for review. |
| **Bookmarks** | Save/unsave resources. Persisted to Firestore + AsyncStorage. |
| **Recents** | Recently viewed PDFs, stored locally in Redux + AsyncStorage. |
| **Downloads** | Offline PDF management. Files stored in device filesystem. |
| **Search** | Search across all subjects in user's curriculum. |
| **Profile** | View/edit profile, account settings, support links, logout. |
| **Theming** | Light/dark mode. Primary: #6360FF, Tertiary: #FF8181, Secondary: #F1F1FA |
| **Push Notifications** | Firebase Cloud Messaging. Topic-based subscriptions per university/course/branch/sem. |

## Redux State Shape

```
store:
  bootReducer        → { appBooting, authToken, showIntro, customClaims, userInfo, ... }
  usersData          → { usersData[], validEmail, usersDataLoaded, userProfile }
  userBookmarkManagement → { userBookMarks[], bookMarksLoaded }
  userRecentPdfs     → { RecentViews[] }
  subjectsList       → { list[], listLoaded, reccommendSubjects[], visitedSubjects{} }
  userState          → { userState, customLoader, noConnection, resourceLoader }
  theme              → { theme: 'light'|'dark', colors{}, sizes{} }
  UserRequestsReducer → { NewRequests[], SeekHubRequests[] }
  pdfViewerReducer   → { PdfData[], downloads[], downloadProgress, pdfChatLog[] }
  AllyBotReducer     → { initiatedChatsList[] }
  SeekHubReducer     → { resourceRequestList[] }
```

## Key Dependencies

- Firebase: Auth, Firestore, Storage, Messaging, Analytics, Crashlytics, Dynamic Links
- Navigation: @react-navigation (stack, bottom-tabs, drawer)
- UI: NativeBase, Lottie, react-native-vector-icons, Reanimated
- PDF: react-native-pdf, pdf-lib, react-pdf
- Storage: AWS SDK (Storj S3 gateway for file storage), react-native-fs, react-native-blob-util
- Forms: Formik + Yup
- State: Redux Toolkit, AsyncStorage

## File Storage (Historical)

PDFs were stored on **Storj** (decentralized cloud storage) via S3-compatible gateway:
```
endpoint: https://gateway.storjshare.io
```
Downloaded files cached at: `{DocumentDirectory}/Resources/`

**Access to Storj was lost** — Flutter migration uses Cloudflare R2 instead.
