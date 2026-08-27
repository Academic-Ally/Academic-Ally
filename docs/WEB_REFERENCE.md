# Web App Reference — `../Academic Ally Legacy/academic-ally-web-main/` (DORMANT, but the site is still live)

React web version of Academic Ally. **Dormant** reference. Do not modify unless explicitly asked.

## Tech Stack

React 18.2.0, Material-UI (MUI) 5.x, Firebase 9.18.0, Redux Toolkit, React Router 6

## Routes

```
Authenticated:
  /home                    → Dashboard (resource type cards + recommended subjects)
  /search                  → Subject search with infinite scroll
  /upload                  → Upload resources (ProductsPage)
  /resources               → Notes list
  /resources/view-pdf      → PDF viewer (Google Drive iframe embed)
  /resources/:resType      → Single resource type view
  /resources/all           → All resource types for a subject
  /account/settings        → Account settings + delete account

Unauthenticated:
  /                        → Login/Register page
```

## Features

- Dashboard with 4 resource type cards and recommended subjects
- Infinite-scroll subject search (Intersection Observer)
- PDF viewing via Google Drive embedded iframe
- Account management with deletion
- Redux state persisted to localStorage via redux-persist
- Lazy-loaded routes with Suspense
- MUI theming (Primary: #6360FF, same as mobile)

## Key Differences from Mobile

- No AllyBot (chat) feature
- No SeekHub (resource requests)
- No offline/download capability
- No bookmarks (nav item commented out)
- PDF viewing via Google Drive iframe instead of native viewer
- No push notifications
