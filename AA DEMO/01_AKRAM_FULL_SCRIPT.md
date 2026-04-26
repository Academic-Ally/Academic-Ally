*ACADEMIC ALLY — PRESENTATION SCRIPT*
*Mohd Mustafa Akram (Project Lead)*

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


*PART 2 — YOUR CONTRIBUTION (AKRAM)*

I am the project lead. My work covers the foundation everything else sits on.

*1. Migrating From React Native To Flutter*

The original app was on React Native. It was slow on cheaper Android phones and hard to extend. I rewrote the whole app in _Flutter_. Flutter gave us better speed, cleaner state management with Riverpod, Material Design 3 by default, and a single codebase for both Android and iOS.

*2. The AI Backend*

I built a Python backend using _FastAPI_. The flow is the same for all 4 AI features:

- The app sends a request to the backend with the student's Firebase login token.
- The backend checks the token and starts a team of AI agents.
- The backend writes live progress to Firestore. The app shows each agent ticking off in real time.
- When done, the backend returns the result and caches it for 24 hours.

I designed this once. All 4 AI features reuse the same pattern.

*3. The RAG System*

RAG stands for _Retrieval-Augmented Generation_. It is how we make sure the AI uses real PDFs, not made-up facts.

How it works:

- Every PDF is split into small chunks (about 800 characters each).
- Each chunk is converted into a list of 768 numbers using Google's `gemini-embedding-001` model. This list is called an _embedding_ — it represents the meaning of the chunk.
- All chunks and their embeddings are stored in _Firestore Vector Search_.
- When an AI agent has a question, the question is also converted to numbers, and we find the closest matching chunks in the database.
- The agent answers using those real chunks and cites the page numbers.

This is what separates us from ChatGPT-style tools. Also, our PDF library is _exclusive and private to Academic Ally_ — this material is not available anywhere else online. So our AI agents work on data that is unique to us.

*4. CrewAI Multi-Agent Setup*

I designed the pattern that all 4 AI features use. Each feature has:

- _Agents_ — each with a role (e.g. "Pattern Analyst") and tools they can use.
- _Tasks_ — chained so each agent's output feeds the next.
- _Crew_ — the team of agents plus a manager that decides who runs when.

We use the _hierarchical mode_ — a manager agent decides the order, instead of fixing it ourselves. This is what makes it _agent-based_, not just scripted.


*PART 3 — QUESTIONS AND ANSWERS*


*Section A — Common Questions*

*Q1. Why CrewAI? Why not LangChain or LangGraph?*
CrewAI is built specifically for managing teams of AI agents. LangChain and LangGraph need much more code to do the same thing. CrewAI gives us agents, tasks, and teams as ready-made building blocks.

*Q2. Why Google Gemini over GPT-4 or Claude?*
Two reasons. Cost — Gemini Flash Lite is about 10 times cheaper. Speed — fast enough that a 5-agent team finishes in under 2 minutes.

*Q3. How do you stop the AI from making things up?*
Two ways. _RAG_ — every agent gets real chunks from the student's PDFs and answers based on them. _Pydantic validation_ — the final agent's output is checked against a strict format. Bad output is rejected.

*Q4. What is RAG?*
Retrieval-Augmented Generation. We split PDFs into chunks, convert each chunk into a list of 768 numbers, and store them in Firestore Vector Search. When an agent has a question, we convert the question into numbers too and find the closest chunks in the database. Those chunks are sent to the agent.

*Q5. Why 768 numbers (dimensions)?*
That is the default for the `gemini-embedding-001` model. It is the sweet spot — enough numbers to capture meaning, not so many that storage and search get slow.

*Q6. How do agents talk to each other? They are not separate programs.*
Each agent is just an AI prompt. CrewAI puts each agent's output text into the next agent's prompt as context. So "talking" is really passing text from one prompt to the next.

*Q7. What is hierarchical process in CrewAI?*
A manager agent decides which worker agent runs next, in what order. The alternative is a fixed order. We use hierarchical so the manager can skip steps that are not needed.

*Q8. Why FastAPI?*
It is async — meaning a 60-second AI request does not freeze the server. It also auto-generates API docs and validates inputs.

*Q9. Why Firebase?*
Bundled — login, database, storage, and notifications all in one. Free tier is generous. Firestore now supports vector search built in, so we did not need a separate database like Pinecone.

*Q10. How is login handled?*
Every backend request needs a Firebase ID token in the Authorization header. The backend verifies the token and gets the user's ID. No token means 401 Unauthorized.

*Q11. How fast are the features?*
PYQ Analyzer 60 to 120 seconds. Study Planner and Adversarial Examiner 60 to 90 seconds. Snap a Doubt 30 to 60 seconds. AllyBot 2 to 5 seconds. Cached results return instantly.

*Q12. How is each student's data kept private?*
Two layers. _Firestore security rules_ — a student can only read or write under their own user ID. _Backend check_ — every request's user ID is taken from the verified token, never from the request body.

*Q13. What is your moat? AI is everywhere now.*
Three things. _Data_ — the largest organized collection of OU and JNTUH material, built over 3 years, exclusive to Academic Ally. _System design_ — we use 4 to 5 specialized agents per feature, not one ChatGPT call. _Focus_ — we are tuned for two specific universities.

*Q14. How is this different from ChatGPT?*
ChatGPT is generic. It does not know your university's syllabus or marking scheme. We use AI agents that read your university's actual question papers and notes, and answer based on real content with page citations.


*Section B — Akram-Specific Questions*

*Q1. Why did you migrate from React Native to Flutter?*
React Native was slow on cheaper Android phones, the build pipeline was fragile, and adding native features was getting hard. Flutter gave us better speed, Material Design 3 by default, and a single codebase for Android and iOS. The migration took a few months but the maintainability gain is permanent.

*Q2. Walk me through the RAG pipeline once.*
We have a Python script that opens each PDF, splits it page by page into 800-character chunks with 100 character overlap. Each chunk is converted to a 768-number embedding using `gemini-embedding-001`. We store the chunk's text, page number, embedding, and metadata in Firestore at `RagChunks/{subject_key}/chunks/{chunkId}`. The script is idempotent — re-running on the same PDF skips already-uploaded chunks.

*Q3. How does retrieval work for the agents?*
We built a custom CrewAI tool. The agent calls it with a query. The tool converts the query to a 768-number embedding and asks Firestore Vector Search for the top 5 closest chunks using cosine similarity (a math formula that measures how close two number lists are). The tool returns the chunks with their PDF name and page number. The agent reads them and answers.

*Q4. Why hierarchical over sequential process?*
Two reasons. _Flexibility_ — the manager can skip steps that are not needed. For example, if cached syllabus is fresh, the Syllabus Researcher can be skipped. _Demo value_ — the professor sees a real autonomous agent (the manager) making decisions, not a hardcoded pipeline.

*Q5. How does the live progress UI work? WebSockets?*
No. We use _Firestore real-time listeners_, which Firebase already gives us. While the agent team is running, we update a Firestore document with each agent's status. The Flutter app subscribes to that document and the UI updates live as the document changes.

*Q6. Why a local backend for the demo? Why not deploy to the cloud?*
For speed of iteration. We are still tuning agent prompts and a cloud deploy takes 5 to 10 minutes. Local restart is 2 seconds. The PYQ Analyzer is also fully deployed on Firebase Cloud Functions — we can switch by changing one constant in the app.

*Q7. Cost per query?*
About ₹2 per cold-start AI run (Gemini token costs plus Tavily web search). Cache hits are free. We tested with about 50 runs during development and the total bill was under ₹100.

*Q8. Could you swap to a different LLM?*
Yes. CrewAI uses `litellm` underneath, which supports OpenAI, Anthropic, Mistral, and many others. We expose `LLM_MODEL` as an environment variable. Changing it from Gemini to Claude or GPT would just work — no code change needed.
