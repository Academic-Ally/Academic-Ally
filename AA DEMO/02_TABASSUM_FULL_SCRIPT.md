*ACADEMIC ALLY — PRESENTATION SCRIPT*
*Tabassum — PYQ Analyzer (5-Agent Flagship Feature)*

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


*PART 2 — YOUR CONTRIBUTION (TABASSUM)*

I built the _PYQ Analyzer_ — our flagship AI feature with 5 agents working as a team.

*1. What It Does*

The student picks a subject and taps Analyze. About 60 to 120 seconds later, they get back two things:

- _Topic Weights_: each topic with a percentage importance (e.g. ER Modeling 18%, Normalization 22%). The numbers add to 100.
- _Predicted Questions_: 8 to 12 likely exam questions for the next paper, written in the same style as past papers.

While they wait, they see each AI agent ticking off live — Syllabus Researcher, Web Researcher, Pattern Analyst, Question Predictor, Output Formatter.

*2. The 5 AI Agents*

This is the heart of the feature.

*Agent 1 — Syllabus Researcher*: Finds all topics in the subject. Uses both real PDFs (via RAG) and Tavily web search.

*Agent 2 — Web Researcher*: Looks online for recent updates, like JNTUH announcing a syllabus change.

*Agent 3 — Pattern Analyst*: Reads the past 10 years of question papers. Finds which topics keep repeating.

*Agent 4 — Question Predictor*: Combines everything from the first 3 agents and writes 8 to 12 predicted questions for the next exam.

*Agent 5 — Output Formatter*: Converts everything into clean JSON the app can display.

There is also a _manager agent_ (built into CrewAI) that decides which agent runs next.

*3. Why 5 Agents Instead Of 1*

Three reasons:

- _Better quality_. Each agent has one focused job — it does that one job well.
- _Modular_. We can replace one agent without breaking the others.
- _The demo story_. Showing 5 agents working as a team is much more impressive than one big AI prompt.

*4. RAG — Using Real PDFs*

Every agent that needs facts uses our RAG search tool. It finds the most relevant chunks from the student's own PDFs (syllabus and past question papers). The agents cite real page numbers, so answers are based on real content, not made up.

*5. Validation*

The Output Formatter uses _Pydantic_ — a Python library that checks the JSON shape. If the agent makes invalid JSON, Pydantic rejects it and asks the agent to fix it. So we never show broken results to the user.

*6. 24-Hour Cache*

If two students from the same university and subject ask the same thing within 24 hours, only the first one runs the full agent team. The second one gets the cached result instantly. Saves cost and time.


*PART 3 — QUESTIONS AND ANSWERS*


*Section A — Common Questions*

*Q1. Why CrewAI?*
CrewAI is built specifically for managing teams of AI agents. LangChain and LangGraph need much more code. CrewAI gives us agents, tasks, and teams as ready-made building blocks.

*Q2. Why Google Gemini over GPT-4 or Claude?*
Cost (about 10 times cheaper than GPT-4). Speed (fast enough for our agent teams).

*Q3. How do you stop the AI from making things up?*
RAG (real chunks from real PDFs) plus Pydantic validation on the final agent's output.

*Q4. What is RAG?*
Retrieval-Augmented Generation. We split PDFs into chunks, convert each chunk into 768 numbers, and store them in Firestore Vector Search. The agent's question is also converted to numbers and we find the closest chunks. Those chunks are sent to the agent.

*Q5. Why 768 numbers?*
Default for `gemini-embedding-001`. Sweet spot between meaning and storage cost.

*Q6. How do agents talk to each other?*
Each agent is just an AI prompt. CrewAI puts one agent's output text into the next agent's prompt. No actual inter-process communication.

*Q7. What is hierarchical process?*
A manager agent decides which worker agent runs next. More flexible than a fixed order.

*Q8. Why FastAPI?*
Async — long AI requests do not freeze the server. Auto-generates API docs.

*Q9. Why Firebase?*
Bundled login, database, storage, and notifications. Generous free tier. Vector search is built in.

*Q10. How is login handled?*
Firebase ID token in the Authorization header. The backend verifies it and extracts the user ID.

*Q11. How fast are the features?*
PYQ Analyzer 60 to 120 seconds. Other AI features 30 to 90 seconds. AllyBot 2 to 5 seconds. Cached results return instantly.

*Q12. How is each student's data kept private?*
Firestore security rules limit each user to their own user ID's path. The backend trusts only the verified token's user ID.

*Q13. What is your moat?*
Three things. Data (largest OU and JNTUH collection, 3 years, exclusive to us). System design (4 to 5 agents per feature). Focus (tuned for two specific universities).

*Q14. How is this different from ChatGPT?*
ChatGPT is generic. We use AI agents that read your university's actual question papers and notes, and answer based on real content with page citations.


*Section B — Tabassum-Specific Questions (PYQ Analyzer)*

*Q1. Why exactly 5 agents?*
We could have done it with one big AI call but the quality would be lower. Each agent has one focused job — it does it better than one prompt trying to do everything. Also, separating roles lets us replace one agent without touching the others. And showing 5 agents in a team is the strongest visual demo of multi-agent AI.

*Q2. Walk me through the order of agents and how data flows.*
The manager decides the order. Usually it goes: Syllabus Researcher first (everyone needs the syllabus), then Web Researcher (recent updates), then Pattern Analyst (patterns in past papers), then Question Predictor (writes new questions), then Output Formatter (converts to JSON). Each agent's output is passed as context to the next.

*Q3. What does the Output Formatter do? Why a separate agent?*
The other agents produce text. The Output Formatter converts that text into a strict JSON object. We use _Pydantic schema validation_ — if the JSON is malformed, CrewAI rejects it and asks the agent to retry. This eliminates broken results.

*Q4. How does the Pattern Analyst find patterns? Does it read all 10 years of PYQs at once?*
No. That would be too many tokens and too expensive. It uses RAG. The agent asks queries like "topics that repeat in DBMS exam JNTUH 2018-2024" and gets back the top 5 matching chunks from the PYQ corpus. It reasons over those.

*Q5. How does Tavily fit in?*
Tavily is a web search API. The Syllabus Researcher and Web Researcher use it for current information not in our PDFs (e.g. a new syllabus update on JNTUH's website). Free tier gives 1000 searches per month.

*Q6. What if an agent outputs garbage?*
Three safety nets. Pydantic catches malformed final output and the agent retries. The manager can detect bad intermediate output and re-delegate. The schema requires a non-empty list of predicted questions and topic weights that sum to 100, so empty results are blocked.

*Q7. How accurate are the predictions?*
The grounding is solid (real PYQs, real syllabus). For a real production version we would add a feedback loop — students rate predictions after exams and we use that signal to improve the prompts.

*Q8. How does the cache work?*
After a successful run, the result is saved in Firestore at `PyqAnalysis/{uni}/{course}/{branch}/{sem}/{subject}` with a timestamp. Before running again, the backend checks if the cached version is less than 24 hours old. If yes, it returns the cache. If no, it runs the full team again.
