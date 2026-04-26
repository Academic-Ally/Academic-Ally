*ACADEMIC ALLY — PRESENTATION SCRIPT*
*Kaviya — Study Planner and Resources / PDF System*

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


*PART 2 — YOUR CONTRIBUTION (KAVIYA)*

I built _Study Planner_ (an AI feature with 4 agents) and the _Resources and PDF system_ that the whole app uses.


*FEATURE 1 — STUDY PLANNER*

*What It Does*

Student enters their exam date, subjects, and weak topics. They tap Generate. Around 60 to 90 seconds later, they get a _day-by-day study plan_ with actual calendar dates from today until the exam:

- Each day has 1 to 3 study tasks.
- Each task has a subject, topic, time in minutes, and a one-line reason.
- Hard topics get more time. Weak topics get a revision pass closer to the exam.

*The 4 AI Agents*

*Agent 1 — Subject Researcher*: For each subject, builds a topic list ranked by importance using RAG.

*Agent 2 — Strategy Planner*: Decides which topics get more time. Hard and weak topics get priority.

*Agent 3 — Schedule Builder*: Maps the strategy to specific calendar dates while respecting the daily-minutes limit.

*Agent 4 — Output Formatter*: Builds the final JSON.

*The Mastery Snapshot*

Before the agents run, we pull the student's past mistakes from Firestore (e.g. trap questions they got wrong from Adversarial Examiner). The Strategy Planner uses this to give weak topics extra time. So the plan is _personalized_, not generic.

*Calendar Anchoring*

AI models often mess up dates — skip days or repeat them. We solve this by passing the exact list of dates into the Schedule Builder. The AI fills tasks for each date but cannot invent new dates.


*FEATURE 2 — RESOURCES AND PDF SYSTEM*

This is the foundation of the app — how students browse and read material.

*Resource Browsing*

Students pick their _university_, _course_, _branch_, _semester_, and _subject_. They see 4 tabs:

- Notes
- Question Papers
- Question Banks
- Syllabus

All organized by Firestore paths.

*PDF Viewer*

I built the in-app PDF viewer using `flutter_pdfview`. It supports:

- Streaming pages from Firebase Storage.
- Initial page jump (used by Snap a Doubt's citations).
- Bookmarking, rating, downloading, sharing, reporting.
- Opening AllyBot scoped to that PDF.

*Bookmarks, Recents, Downloads*

Per-user state stored in Firestore subcollections. Bookmarks sync across devices. Downloads work offline.

*Search With Filters*

Students can search across the whole library, filtered by subject, year, and type. Uses Firestore composite indexes.

*Upload And SeekHub*

- _Upload_: Students can upload PDFs they have. Goes to a moderation queue.
- _SeekHub_: Students request resources they cannot find. Other students or admins fulfill the request.

These two keep the library growing through the community.


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
PYQ Analyzer 60 to 120 seconds. Study Planner and Adversarial Examiner 60 to 90 seconds. Snap a Doubt 30 to 60 seconds. AllyBot 2 to 5 seconds.

*Q12. How is each student's data kept private?*
Firestore security rules per user ID. Backend trusts only the verified token.

*Q13. What is your moat?*
Data (exclusive to Academic Ally), system design, focus on two specific universities.

*Q14. How is this different from ChatGPT?*
ChatGPT is generic. We use AI agents that read your university's actual material and answer with page citations.


*Section B — Kaviya-Specific Questions*

*Q1. How is the study plan generated? Walk me through inputs and outputs.*
Inputs from the student: exam date, list of subjects, optional weak topics, daily-minutes budget. Inputs from Firestore: the student's past mistakes (mastery snapshot). The backend pre-computes the date list. The 4 agents run in order. Output is JSON with the exam date, subjects, and a day-by-day list of tasks.

*Q2. What is the mastery snapshot and why does it matter?*
A small Firestore document that tracks the student's understanding of each topic. Topics where the student got Adversarial Examiner trap questions wrong are flagged as weak. We feed this into the Strategy Planner so the AI gives more time to weak topics. Without the snapshot, the AI would treat the student like a blank slate.

*Q3. Why pass dates explicitly? Why not let the AI generate them?*
AI models often skip days or repeat dates. By pre-computing the date list and forcing the Schedule Builder to fill tasks per date, we eliminate calendar bugs. The AI is good at strategy, bad at calendar arithmetic. So we let each part do what it is good at.

*Q4. What if the student's daily time budget is too small to cover everything?*
The Strategy Planner prioritizes — drops low-weight topics, focuses on the highest-frequency exam topics from the PYQ corpus. The output JSON has a field that explains which topics were prioritized and which were dropped. The student sees this in the UI.

*Q5. How are PDFs streamed in the viewer?*
`flutter_pdfview` streams pages from Firebase Storage as they load. For previously viewed PDFs, the file is cached locally so reopening is instant.

*Q6. What about offline mode?*
Resource browsing and PDF viewing work offline once the PDF is downloaded. AI features require internet because the AI model is in the cloud.

*Q7. How do bookmarks sync across devices?*
Bookmarks are stored in Firestore at `Users/{user_id}/NotesBookmarked/{bookmark_id}`. Sign in on a different device with the same account and Firestore syncs them automatically.
