# Academic Ally

An AI-native study platform for B.E/B.Tech engineering students at **Osmania
University** and **JNTUH**, Hyderabad. Students browse curriculum notes, question
papers, question banks and syllabi — then work through them with a set of
multi-agent AI tools grounded in those same documents.

Originally a React Native app on the Play Store, since rebuilt in Flutter and
expanded into an agentic platform.

## What's in the app

**Resources** — browse by university → course → branch → semester → subject,
across Notes / Question Papers / Question Banks / Syllabus, with search,
bookmarks, recents, offline downloads, community uploads and a resource request
board (SeekHub).

**AI tools** (each a CrewAI multi-agent crew, retrieval-grounded in the actual
subject PDFs):

| Feature | What it does |
|---|---|
| PYQ Analyzer | Mines past question papers for patterns and predicts likely questions |
| Study Planner | Builds a personalised revision schedule from syllabus + time available |
| Adversarial Examiner | Generates deliberately tricky exam questions and scores mastery |
| Snap a Doubt | Photograph a doubt → Gemini Vision reads it → solved with citations back to the source PDF page |
| AllyBot | Chat scoped to the PDF you have open |

## Stack

Flutter (Riverpod · GoRouter · Material 3) · Firebase (Auth, Firestore, Storage,
FCM) · Python FastAPI + CrewAI + Google Gemini · Firestore Vector Search for RAG.

## Repository layout

```
lib/          Flutter source — core/ (services, providers, constants) + features/
backend/      FastAPI AI service: 5 agent crews + shared RAG layer
functions/    Firebase Cloud Function — billing hard-cap
functions_py/ LEGACY Cloud Functions (superseded by backend/)
docs/         Architecture, Firestore schema, agentic feature deep-dive
```

## Running it

```bash
flutter pub get && flutter run          # the app
cd backend && ./run.sh                  # the AI backend (needs uv + backend/.env)
```

The app reads its backend URL from `aiBackendBaseUrl` in
`lib/core/constants/app_constants.dart`.

## Documentation

**`CLAUDE.md` is the orientation document** — read it first. It carries the
architecture, the Firestore/Storage schema, the current infrastructure status and
a list of hard-won gotchas. `AGENTS.md` points AI coding agents at it. Deep dives
live in `docs/`; anything in `docs/archive/` is deliberately out of date.
