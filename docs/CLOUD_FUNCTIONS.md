# Cloud Functions — `academic-ally-cloud-functions-main/`

Netlify serverless functions providing Chat (AllyBot) + Notifications APIs to all clients.

## Tech Stack

Node.js, Express 4.x, Firebase Admin SDK, Netlify Functions

## Architecture

- **Local dev:** Express server on port 3000
- **Production:** Netlify serverless functions with 30s timeout
- **Bundler:** esbuild

## API Endpoints

### Chat API (AllyBot) — `/chat/`

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/chat/initiate` | POST | Initialize chat for a PDF. Calls ChatPDF API, creates Firestore doc. |
| `/chat/message` | POST | Send message in existing chat. Returns AI response. |

**Rate Limits:**
- Chat initiation: 50 max per user
- Messages: 10/day (regular), 15/day (premium)

**AI Service:** ChatPDF API (`https://api.chatpdf.com/v1/`) — NOT a general LLM. Specialized for document Q&A only. Will be swapped to Gemini in Phase 4 of the AI pivot (see `AI_PIVOT_PLAN.md`).

### Notifications API — `/notifications/`

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/notifications/subscribe-user` | POST | Subscribe user to FCM topic by userId |
| `/notifications/subscribe` | POST | Subscribe device token to topic directly |
| `/notifications/unsubscribe` | POST | Unsubscribe token from topic |
| `/notifications/send` | POST | Send notification to all topic subscribers |
| `/notifications/resource-accepted` | POST | Dual notification: topic subscribers + uploader |

### Reset API — `/reset/`

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/reset/pdf-count` | POST | Reset initiatedChats to 0 for all non-premium users |

## Environment Variables

```
CHATPDF_API_KEY          # ChatPDF service key
NODE_ENV                 # production | development
PORT                     # Local dev port (3000)

# Firebase service account fields (10 fields):
type, project_id, private_key_id, private_key, client_email, client_id,
auth_uri, token_uri, auth_provider_x509_cert_url, client_x509_cert_url, universe_domain
```

## Firebase Admin SDK Note

These functions use Firebase Admin SDK, which **bypasses Firestore security rules by design**. All server-side writes are trusted. Client-side writes are still subject to `firestore.rules`.

## Flutter Integration Status

- Flutter's `allybot_provider.dart` calls `/chat/initiate` and `/chat/message`
- ⚠ `cloudFunctionsBaseUrl` in `academic_ally/lib/core/constants/app_constants.dart:55` is **wrong** — points to Firebase Cloud Functions URL, but backend is actually Netlify. Fix in Phase 4.
