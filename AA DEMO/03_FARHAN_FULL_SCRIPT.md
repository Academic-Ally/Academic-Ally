*ACADEMIC ALLY — PRESENTATION SCRIPT*
*Farhan — Snap a Doubt and AllyBot*

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


*PART 2 — YOUR CONTRIBUTION (FARHAN)*

I built two AI features — _Snap a Doubt_ and _AllyBot_.


*FEATURE 1 — SNAP A DOUBT*

*What It Does*

Student is stuck on a problem in their textbook or notes. They open Snap a Doubt, take a photo, pick the subject, and submit.

About 30 to 60 seconds later, they get:

- The question read from the photo.
- A step-by-step solution with reasoning.
- The final answer.
- Citations — clickable links to the PDF page in their own course material that explains the concept.

*The Vision Step*

This is what makes Snap a Doubt special. We send the photo directly to the _Google Gemini API_, which is a _multimodal AI_ — it can read images, not just text. It extracts the question even if it is handwritten or has equations.

This is OCR (reading characters) plus understanding the problem in one step. Better than tools like Tesseract that only read characters.

*The 4 AI Agents (After The Vision Step)*

*Agent 1 — Topic Classifier*: Identifies which topic this question belongs to.

*Agent 2 — Solver*: Solves the problem step by step using real material from the student's PDFs (RAG).

*Agent 3 — Citation Resolver*: For each step, finds the exact PDF and page number that explains that concept.

*Agent 4 — Output Formatter*: Builds the final JSON for the app.

*Privacy*

The doubt photo is uploaded to Firebase Storage at a path locked to the student's user ID. Other students cannot see it.


*FEATURE 2 — ALLYBOT*

*What It Does*

A student opens any PDF in the app and taps AllyBot. A chat opens. They ask questions about that PDF in plain English. The AI answers based on _that specific PDF only_, with page citations.

*Why It Is Different From ChatGPT*

ChatGPT does not have your PDF. It answers from general knowledge and may invent details. AllyBot is _scoped to one PDF_ — it only reads chunks from that PDF. So the answer is always based on real content from that document.

*Why It Is Simpler Than Other Features*

AllyBot is _one AI call with RAG context_, not a 4-agent team. The reason is speed — chat needs to be fast (2 to 5 seconds). A 5-agent team would be too slow for chat.

*The Old AllyBot*

The first AllyBot used an external service called ChatPDF through a Netlify cloud function. We replaced it with our own version using RAG and the Gemini API. Cheaper, faster, and integrated with the rest of the app.


*PART 3 — QUESTIONS AND ANSWERS*


*Section A — Common Questions*

*Q1. Why CrewAI?*
Built specifically for AI agent teams. Less code than LangChain. Ready-made building blocks for agents, tasks, and teams.

*Q2. Why Google Gemini?*
Cost (about 10 times cheaper than GPT-4). Speed.

*Q3. How do you stop the AI from making things up?*
RAG (real chunks from real PDFs) plus Pydantic validation on the final agent's output.

*Q4. What is RAG?*
Retrieval-Augmented Generation. We split PDFs into chunks, convert each chunk into 768 numbers, and store them in Firestore Vector Search. The agent's question is also converted to numbers, and we find the closest chunks.

*Q5. Why 768 numbers?*
Default for `gemini-embedding-001`. Sweet spot between meaning and storage cost.

*Q6. How do agents talk to each other?*
CrewAI passes one agent's output text into the next agent's prompt as context.

*Q7. What is hierarchical process?*
A manager agent decides which worker agent runs next. More flexible than a fixed order.

*Q8. Why FastAPI?*
Async, so long AI requests do not freeze the server. Auto API docs.

*Q9. Why Firebase?*
Bundled login, database, storage, notifications. Free tier. Vector search built in.

*Q10. How is login handled?*
Firebase ID token in Authorization header. Backend verifies and extracts the user ID.

*Q11. How fast are the features?*
PYQ Analyzer 60 to 120 seconds. Other AI features 30 to 90 seconds. AllyBot 2 to 5 seconds.

*Q12. How is each student's data kept private?*
Firestore security rules per user ID. Backend trusts only the verified token.

*Q13. What is your moat?*
Data (largest OU and JNTUH collection, exclusive to us). System design (multi-agent per feature). Focus (two specific universities).

*Q14. How is this different from ChatGPT?*
ChatGPT is generic. We use AI agents that read your university's actual material and answer based on real content with page citations.


*Section B — Farhan-Specific Questions*

*Q1. How does Gemini's vision work?*
Gemini is a _multimodal model_ — it was trained on both text and images. When we send a photo, it processes the image and the text prompt together. It can read characters and understand the structure of the problem in one step. There is no separate OCR step.

*Q2. What if the image is blurry or handwritten?*
Gemini handles handwriting better than traditional OCR. For very blurry images, accuracy drops. We mitigate by showing the extracted question to the user so they can verify the AI saw it correctly. If Gemini cannot read parts of the image, our prompt asks it to say so explicitly.

*Q3. Why do you need 4 agents to solve a doubt? One AI call could do it.*
True, but split roles give better quality. The Topic Classifier first identifies the topic so the Solver pulls more relevant context. The Solver focuses purely on solving. The Citation Resolver finds page numbers — the Solver should not be distracted with that. The Output Formatter ensures clean JSON. Each prompt is smaller and more focused.

*Q4. How is AllyBot scoped to one PDF?*
At ingestion time, every chunk gets tagged with the PDF's resource ID. Our RAG search tool accepts an optional resource ID filter. AllyBot passes the current PDF's ID, so the search only returns chunks from that PDF.

*Q5. How do citations work? Are page numbers reliable?*
Yes. When we ingest a PDF, we record the page number for each chunk. So when we retrieve a chunk, we know which page it came from. The Citation Resolver picks the most relevant chunks for each step. The app uses the resource ID and page number to open the PDF at the right page.

*Q6. Why is AllyBot a single AI call but Snap a Doubt is a 4-agent team?*
Latency. Chat needs 2 to 5 seconds per response. A 4-agent team takes 30+ seconds, which kills chat. For Snap a Doubt the user already expects a wait, so we can spend that time doing higher-quality multi-agent work.

*Q7. Is the doubt photo private?*
Yes. Uploaded to Firebase Storage at `Doubts/{user_id}/{doubt_id}.jpg`. Storage rules require authentication and that the user ID in the path matches the requesting user. Other students cannot read it.
