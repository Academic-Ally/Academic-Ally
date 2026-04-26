*ACADEMIC ALLY — PRESENTATION SCRIPT*
*Giridher — Adversarial Examiner and Firebase Backend Layer*

*PART 1 — ABOUT ACADEMIC ALLY*

*What It Is*

Academic Ally is a mobile app for B.E and B.Tech students at _Osmania University_ and _JNTUH_ in Hyderabad. It is two things in one.

One, it is an _AI-powered education platform_. Teams of AI agents work in the background to predict exam questions, build study plans, generate trap questions, and solve doubts from photos. The answers are based on the student's _own real PDFs_, not generic internet text.

Two, it is the largest organized library of _Notes, Previous Year Question Papers (PYQs), Question Banks, and Syllabi_ for these two universities.

*The Problem*

Before exams, students waste days hunting for material in WhatsApp groups and senior's Drive links. Even when they have everything, no one tells them what is important, where they are weak, or what is likely to come in the exam. Generic AI tools like ChatGPT do not know JNTUH or OU syllabi.

*Why We Built It*

The original app was built in React Native three years ago and went dormant. Akram then rewrote everything in Flutter and implemented all the AI features.

*Tech Stack*

App: Flutter (Frontend framework)
State Management: Riverpod.

AI Backend: FastAPI (Python), CrewAI (manages agent teams), Google Gemini API (the AI model), Tavily (web search API), Firestore Vector Search (finds relevant PDF chunks).

Cloud: Firebase for login/authentication, database, storage, and notifications.

*What Makes Us Different*

Most apps just call ChatGPT once and show the result. We use _4 to 5 specialized AI agents per feature_, working as a team. One researches, one analyzes, one predicts, one formats. The answers are based on _real PDFs_ — we cite real page numbers, not made-up facts. Also, our PDF library is _exclusive and private to Academic Ally_ — this collection is not available anywhere else online, so everything our AI agents do happens on data unique to us.


*PART 2 — YOUR CONTRIBUTION (GIRIDHER)*

I built _Adversarial Examiner_ (an AI feature with 4 agents) and the _Firebase backend layer_ that handles login, the database, and security.


*FEATURE 1 — ADVERSARIAL EXAMINER*

*What It Does*

Student picks a subject and taps Generate. About 60 to 90 seconds later, they get 6 _trap questions_ — questions where most students pick the wrong answer because of a common misconception.

Each question has:

- 4 multiple-choice options.
- The correct answer.
- The _common mistake_ — what most students pick wrong, explained.
- The _correct approach_ — the right way to think.
- The topic and difficulty.

When the student answers, the wrong answers update their _mastery score_ in Firestore. This data feeds into Study Planner (which gives more time to weak topics).

*The 4 AI Agents*

*Agent 1 — Topic Researcher*: Finds topics where students typically struggle, using RAG and the student's mastery snapshot.

*Agent 2 — Trap Designer*: Designs questions with one correct answer and three plausible wrong options based on common mistakes.

*Agent 3 — Verifier*: Checks each question. Rejects questions that are mathematically wrong, have multiple valid answers, or are too tricky to be fair.

*Agent 4 — Output Formatter*: Builds the final JSON.

*Why The Verifier Matters*

This is the difference between "AI generates MCQs" and Adversarial Examiner. The Verifier catches bad questions before the student sees them. Without it, the AI sometimes makes math errors or ambiguous questions. This is called the _generator-critic pattern_ — one agent creates, another agent reviews.


*FEATURE 2 — FIREBASE BACKEND LAYER*

This is the foundation everyone builds on.

*Firebase Authentication*

Login via email/password or Google. Each user gets a unique ID called `uid`. We store profile info at `Users/{uid}` and sensitive info at `ImmutableUserData/{uid}`.

*The Firestore Database*

29 collections, organized into:

- _Public library_: `Universities/{uni}/{course}/{branch}/{sem}/...` — all PDFs, public read.
- _Per-user state_: `Users/{uid}/...` — bookmarks, study plans, doubt history, mastery scores. Private.
- _AI state_: `PyqAnalysis` (cache), `AnalysisRuns` (live progress), `RagChunks` (vector store).
- _Community (Coming Soon)_: Jobs, Channels, Marketplace.

*Firestore Security Rules*

Server-side rules that decide who can read and write. Examples:

- Anyone can read PDFs from the library.
- A user can only read or write under their own `Users/{uid}` path.
- Only admins can publish PDFs to the public library.

These rules are enforced by Firebase, not by the app. So even if someone tries to bypass the app, the rules block unauthorized access.

*Push Notifications*

Students get push notifications when their SeekHub request is fulfilled or when new PDFs are added to their subject. Uses topic-based subscriptions through Firebase Cloud Messaging.

*Billing Cap*

Firebase is on the paid Blaze plan. To prevent surprise bills, there is a _Cloud Function_ called stopBilling. It auto-disables Firebase if monthly spend exceeds ₹200.


*PART 3 — QUESTIONS AND ANSWERS*


*Section A — Common Questions*

*Q1. Why CrewAI?*
Built specifically for AI agent teams. Less code than LangChain. Ready-made building blocks.

*Q2. Why Google Gemini?*
Cost (about 10 times cheaper than GPT-4). Speed.

*Q3. How do you stop the AI from making things up?*
RAG (real chunks from real PDFs) plus Pydantic validation on the output.

*Q4. What is RAG?*
Retrieval-Augmented Generation. PDFs split into chunks, each chunk converted to 768 numbers, stored in Firestore Vector Search. The agent's question is also converted to numbers and we find the closest chunks.

*Q5. Why 768 numbers?*
Default for `gemini-embedding-001`. Sweet spot between meaning and storage cost.

*Q6. How do agents talk to each other?*
CrewAI passes one agent's output text into the next agent's prompt.

*Q7. What is hierarchical process?*
A manager agent decides which worker agent runs next. More flexible than a fixed order.

*Q8. Why FastAPI?*
Async — long AI requests do not freeze the server. Auto API docs.

*Q9. Why Firebase?*
Bundled. Free tier. Vector search built in.

*Q10. How is login handled?*
Firebase ID token in the Authorization header. Backend verifies and extracts the user ID.

*Q11. How fast are the features?*
PYQ Analyzer 60 to 120 seconds. Other AI features 30 to 90 seconds. AllyBot 2 to 5 seconds.

*Q12. How is each student's data kept private?*
Firestore security rules per user ID. Backend trusts only the verified token.

*Q13. What is your moat?*
Data (exclusive to Academic Ally), system design, focus on two specific universities.

*Q14. How is this different from ChatGPT?*
ChatGPT is generic. We use AI agents that read your university's actual material and answer with page citations.


*Section B — Giridher-Specific Questions*

*Q1. What is a "trap question"?*
A question where most students pick the wrong answer because of a common misconception. The wrong options are plausible — they look like answers a student following bad reasoning would naturally choose. Not random nonsense.

*Q2. Why do you need a separate Verifier agent?*
LLMs are inconsistent on quality. The Trap Designer's prompt is focused on creativity. Asking it to also strictly self-check would dilute that creativity. Splitting roles gives us two AI passes — one creates, one reviews. This is called the _generator-critic pattern_ and it produces measurably better output than asking one agent to do both.

*Q3. How are mastery scores updated?*
Each topic has a score between 0 and 1, stored at `Users/{uid}/MasteryScores/{topic_id}`. We use an _exponential moving average_ — `new_score = 0.7 * old_score + 0.3 * this_answer`. Recent answers weigh more, so a student who improves sees their mastery rise smoothly.

*Q4. How do Firestore security rules work?*
Server-side guards that run on every read and write. Example: `match /Users/{uid} { allow read, write: if request.auth.uid == uid; }`. This says only the user with matching `uid` can read or write that document. If alice tries to read bob's profile, Firebase rejects it before the query returns.

*Q5. How is the admin role checked?*
We store admin flag in Firestore at `ImmutableUserData/{uid}.customClaims.admin = true`. The rules read this document to check admin status. For now there is one known admin (Akram). For production we would set up a proper Firebase Custom Claims Cloud Function.

*Q6. Tell me about the billing cap.*
Firebase is on the paid Blaze plan because Vector Search and Cloud Functions need it. To prevent surprise bills, we have a Cloud Function called `stopBilling`. It listens to a Pub/Sub topic that Google Cloud Billing publishes to. When monthly spend crosses ₹200, the function calls the Cloud Billing API to disable billing on the project. This caps Firebase only — Gemini API costs are billed separately and we monitor them manually.

*Q7. Can a student see another student's data?*
No. Per-user data lives at `Users/{uid}/...`. Firestore rules enforce that only the user with matching `uid` can read or write under that path. Cross-user reads are rejected at the Firebase level.
