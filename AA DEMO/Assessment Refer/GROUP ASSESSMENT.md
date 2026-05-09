GROUP ASSESSMENT BRIEFING — ACADEMIC ALLY

For module LD7232 (Applied Technologies for Project Management, Northumbria University).


HOW TO USE THIS DOCUMENT

This briefing is the source material for five individual reflective reports — one per team member — under module LD7232 (Applied Technologies for Project Management). Each report is 2,000 words, weighted at 60 percent of the module mark, and is due 21 May 2026 at 16:00 via Turnitin.

Although each student submits their own report, every report is about the same group project — Academic Ally. The shared sections of this document (about the project, system architecture, tech stack, ethics, glossary) are common context that every report should draw from. The per-member sections that follow are the spine of each student's Task 1 evaluation, which focuses on the part of the project they personally led.

The expert writer should select, paraphrase, and condense from this document. It is intentionally several times longer than five reports' worth of words, so the writer has selection room. Each report should read as that one student's voice, academic and reflective and professionally toned.

The brief permits AI for grammar, structure, idea organisation, and editorial suggestions, but not for generating whole sentences, paragraphs, or sections of substantive content. The writer must record AI-tool usage on the cover sheet at the front of each submission and in a reference declaration in the bibliography.

Each report has three weighted parts. Task 1, about 1,000 words and weighted 45 percent, is an evaluation of the tools and technologies used in the project, with critical comparison and reflection on outcomes. Task 2, about 1,000 words and weighted 45 percent, is a critical analysis of the ethical and social implications of emerging technologies in project management. Task 3 covers presentation, structure, and academic style, weighted 10 percent. The word count excludes the table of contents, page numbers, and figure or table captions.


ABOUT ACADEMIC ALLY

Academic Ally is a mobile application built for engineering undergraduates (B.E. and B.Tech.) preparing for end-of-semester examinations. It combines two purposes in one product. First, it is an AI-powered study companion: teams of artificial-intelligence agents work in the background to predict likely exam questions, generate personalised study plans, design adversarial practice questions targeting common misconceptions, and solve doubts photographed from a textbook. Every answer is grounded in real course material the platform has ingested, with cited page numbers, rather than generic internet text. Second, it is an organised academic library — notes, previous-year question papers, question banks, and syllabi catalogued by institution, branch, course, semester, and subject.

The first live deployment is for Osmania University and JNTUH in Hyderabad, the cohort whose curriculum the team has ingested first. The architecture is intentionally institution-agnostic. The same product can be deployed for any university, polytechnic, or technical institution worldwide by ingesting that institution's syllabi, notes, and past papers. Institution, branch, and semester are parameters of the data model rather than built-in assumptions in the code, so onboarding a new university is a content and configuration exercise rather than a software rebuild.

The Problem It Solves

Before exams, students lose days hunting for study material across informal channels — peer messaging groups, shared cloud-drive links, scattered PDFs of unknown provenance. Even with a complete pile of material, no resource tells them what is important, where they are weak, what types of question recur, or what is likely to appear in the next paper. Generic AI assistants cannot fill this gap because they do not know any specific institution's syllabi, marking schemes, or question patterns.

Target Users And Stakeholders

The primary users are undergraduate engineering students preparing for examinations. Indirect users include faculty members and academic administrators who benefit from improvements in student preparedness. Stakeholders include the institutions whose intellectual property informs the corpus, the Academic Ally founding team, and the infrastructure providers behind the cloud platform, language model, and search APIs.

What Sets It Apart

Most consumer AI study apps make a single call to a general-purpose chatbot and display the output. Academic Ally takes a different approach. Each AI feature is implemented as a team of four to five specialised agents — one researches, one analyses, one predicts or solves, one verifies, one formats. The agents collaborate, and they ground their answers in retrieved chunks from real PDFs the platform owns. The output cites real page numbers, not fabricated facts. Combined with a curated, institution-specific library, this produces depth of context that a general-purpose chatbot cannot easily replicate.


SYSTEM ARCHITECTURE

A student opens the Flutter mobile application on their Android phone (iOS is also supported). The app obtains a fresh Firebase ID token, which is a signed proof of the student's identity, and sends an HTTPS request to the FastAPI backend with the token in the Authorization header. The backend verifies the token with Firebase, recovers the student's user ID from the verified token (never trusting any user ID supplied in the request body, which prevents impersonation), and routes the request to the appropriate feature handler.

For AI features, the backend instantiates a CrewAI agent crew. The crew's manager agent decides which worker agent runs first. As each agent finishes its turn, the backend writes a progress update to a temporary Firestore document called an AnalysisRun. The mobile app subscribes to that document through a Firestore real-time listener, so the user interface updates live as each agent ticks off, without polling and without a custom WebSocket protocol.

Worker agents that need facts call a shared retrieval-augmented generation tool, which converts their query into an embedding (a list of numbers representing meaning), looks up the closest matching chunks in Firestore Vector Search, and returns those chunks with the PDF name and page number. Agents that need fresh web information call a web search tool. When all agents have finished, an Output Formatter agent produces a strictly-validated JSON object that is returned to the app.

All per-user data lives under user-owned Firestore paths protected by server-enforced security rules. Cross-user reads are rejected at the database layer, not at the application layer.

The architecture solves three project-management concerns at once. First, latency tolerance. AI runs take 30 to 120 seconds, so a synchronous design would freeze the app; the real-time listener pattern lets the user see genuine progress and converts wait time into engagement. Second, cost containment. Retrieval happens against PDFs the platform already owns, and only the language model and web search are paid external dependencies. Third, quality control. The multi-agent split with a Verifier or Output Formatter at the end of every crew gives the system two natural quality checkpoints — schema validation and critic agents.


TECH STACK

Mobile Application

The mobile application is built in Flutter, chosen for its single codebase across Android and iOS, smooth rendering on lower-end Android phones common in the Indian student market, and mature plugin ecosystem. The credible alternative was native development with Kotlin for Android and Swift for iOS; the trade-off is a heavier installed binary than native apps.

State management uses Riverpod 3.x for its compile-time-safe dependency injection, testability, and support for the Notifier pattern. Provider, Bloc, and GetX were credible alternatives; Riverpod has a slightly steeper initial learning curve than Provider but pays off in larger applications.

Navigation is handled by GoRouter, which provides declarative URL-style routing with native deep-link integration. Navigator 1.0 and Beamer were credible alternatives; GoRouter is configuration-heavy at the start of a project but supports the deep-link patterns the platform needs.

The design system is Material Design 3, which gives built-in theming, dark mode, and a brand-token system. A custom design language was a credible alternative but would have been less visually consistent across Android versions.

PDF viewing uses flutter_pdfview, which streams remote PDFs, supports an initial-page-jump parameter (essential for Snap a Doubt's clickable citations), and caches files locally for offline reading. Alternative PDF plugins were considered; the trade-off is limited annotation support in the chosen plugin.

Image picking uses the standard image_picker plugin for camera and gallery access; this covers permission flows on Android and iOS without custom platform-channel code.

Deep linking uses app_links, which supports both custom-scheme and universal-link integration in one plugin; the alternative uni_links was less complete.

AI Backend

The web framework is FastAPI 0.115 on Python 3.12. FastAPI was chosen for its asynchronous request handling (so a 60-second AI run does not block the server), auto-generated interactive documentation, and built-in request validation. Flask, Django, and Node.js with Express were credible alternatives; the trade-off is that asynchronous Python has steeper debugging tooling than synchronous code.

Multi-agent orchestration uses CrewAI 1.14.3, which is purpose-built for cooperating agents and provides ready-made abstractions for Agent, Task, and Crew. It supports a hierarchical process where a manager agent decides execution order. LangChain, LangGraph, AutoGen, and custom orchestration were credible alternatives; CrewAI has a smaller community than LangChain but a more ergonomic surface for the patterns the platform needs.

The launch language model is Google Gemini 2.5 Flash Lite. It was selected for strong reasoning across multimodal inputs (text and images, which is essential for the doubt-photo feature), and latency low enough that multi-agent crews finish in under two minutes. Any major provider — Claude, GPT, Mistral, Kimi — would be a credible alternative. The platform is designed for vendor portability through a model-abstraction layer, so the chosen language model can be swapped to any other supported provider by changing one configuration value, with no code change in the agents themselves.

The model abstraction is litellm (under CrewAI). It allows the language model to be swapped to Claude, Kimi, Mistral, GPT, or any other supported provider by changing a single configuration value. Hard-coded provider SDK calls were the alternative; litellm adds a small indirection layer when debugging vendor-specific behaviour but pays off in resilience to vendor change.

The embeddings model is gemini-embedding-001 at 768 dimensions. It comes from the same provider family as the generative model, so quotas and latency are aligned, and 768 dimensions balances semantic richness against storage cost. Other embedding providers were credible alternatives; the trade-off is that the dimension is fixed for this model.

The vector store is Firestore Vector Search. It is already part of Firebase, so there is no second database to operate; it inherits Firestore security rules; cosine-similarity search is built in. Pinecone, Weaviate, Chroma, and pgvector were credible alternatives; Firestore Vector Search is a newer feature and per-collection vector indexes must be created manually today.

Web search for agents uses Tavily, which is designed specifically for AI agents and returns clean parseable summaries rather than scraped HTML. SerpAPI and Bing Search API were credible alternatives; Tavily has a smaller index than top-tier engines but a much friendlier output format.

Process and package management uses uv from Astral. It provides fast, deterministic dependency resolution and replaces pip, virtualenv, and pip-tools in one tool. Pip with requirements files and Poetry were credible alternatives; uv is newer and has fewer tutorials but is markedly faster.

Cloud Platform

Firebase is the cloud platform. Authentication is handled by Firebase Authentication (email and password, Google sign-in), which issues the signed ID token used by every backend request. Cloud Firestore is the primary database (about 29 collections) and also serves as the vector store and the live progress tracker. Cloud Storage holds curriculum PDFs, community-uploaded PDFs, doubt photos, and marketplace listing images. Cloud Messaging handles topic-based push notifications scoped to the student's branch and semester. Cloud Functions hosts a billing-cap function that auto-disables Firebase if monthly spend exceeds the configured threshold. The hosting plan is Blaze (pay-as-you-go), required because Vector Search and Cloud Functions are not on the free tier.

Validation And Quality Control

Schema validation uses Pydantic. Every AI feature's final agent emits JSON validated against a strict Pydantic schema; malformed output is rejected and the agent retries.

The critic-agent role in Adversarial Examiner is performed by a dedicated Verifier agent that re-reads each generated trap question and rejects errors and ambiguity. This is the generator-critic pattern.

Server-side data security uses Firestore Security Rules. Per-user ownership rules are enforced by the database itself.

Server-side identity checking is bearer ID-token verification. Every backend endpoint verifies the Firebase ID token and uses the verified user ID, ignoring any user ID supplied in the request body.

Operational Notes

The AI backend currently runs locally on the development machine on port 8000, with the Android emulator reaching it through the alias 10.0.2.2 on port 8000. Production deployment to a managed runtime such as Cloud Run is a known follow-up item. Firebase spend is auto-capped via the stopBilling Cloud Function; language-model API spend is monitored separately. Cost per cold-start AI run is approximately two rupees (language model plus web search); cached results return at no further cost.


PER-MEMBER CONTRIBUTIONS

Each sub-section below is the spine of one team member's Task 1 evaluation. The writer should expand the relevant sub-section to roughly 1,000 words for that member's report.


Mohd Mustafa Akram — Architecture, Retrieval-Augmented Generation, and Multi-Agent Foundation

Role In The Project

Akram serves as the project lead. His direct technical contribution is the platform's shared technical foundation: the FastAPI backend service, the retrieval-augmented generation pipeline, and the multi-agent orchestration pattern using CrewAI. These pieces establish conventions the team agreed on collectively — authentication via Firebase ID tokens, live progress streaming through Firestore real-time listeners, and output validation through Pydantic schemas at the end of every agent crew. The four AI feature crews and the chat assistant are built on these foundations; each feature is independently designed, implemented, and owned by a different team member.

What He Built

The shared AI backend service is a single FastAPI service in Python 3.12 that exposes one HTTPS endpoint per AI feature. The service handles four cross-cutting concerns. Authentication is verified on every call through the Firebase Admin SDK. Lifecycle management uses per-run tracker documents in Firestore. Live progress streaming reuses Firebase real-time listeners, so there is no custom WebSocket protocol. Caching, where appropriate, writes a 24-hour entry to a stable Firestore path so subsequent identical requests can return instantly.

The retrieval-augmented generation pipeline has two halves. Ingestion runs offline as a script. For every curriculum PDF, the script opens the PDF and walks page by page, splits the text into chunks of approximately 800 characters with a 100-character overlap so meaning is not cut at chunk boundaries, calls the embedding model to convert each chunk into 768 floating-point numbers, and writes a Firestore document containing the chunk text, the page number, the embedding vector, the PDF name, and metadata identifying the institution, branch, semester, and resource. The script is idempotent. Retrieval runs online whenever an agent needs facts. A custom CrewAI tool wraps the retrieval logic. The agent calls the tool with a natural-language query, the tool calls the embedding model to embed the query, the tool calls Firestore Vector Search and asks for the top five chunks by cosine similarity, and the tool returns the chunk text, PDF name, and page number to the agent. The agent answers using those chunks and cites real page numbers.

The CrewAI multi-agent pattern provides the skeleton every AI feature uses. A crew is a team containing four to five agents and the tasks that connect them. Each agent has a role, a goal, and a small set of tools. The platform uses CrewAI's hierarchical process rather than its sequential process; an automatic manager agent decides which worker agent runs next based on the state of the work so far. This enables flexibility (the manager can skip cached steps) and observability (the manager's decisions are visible in the run trace, which makes the system auditable). Output validation is the final shared concern: every crew ends with an Output Formatter agent whose JSON output is validated against a Pydantic schema, and on failure CrewAI retries the formatter.

Tools and Technologies — Critical Evaluation

FastAPI enabled long-running AI requests without blocking the server, thanks to native asynchronous support, and auto-generated documentation made endpoints testable from a browser before the mobile app was wired up. The trade-off is that asynchronous Python has steeper debugging tooling than synchronous code, and deployments require an ASGI server.

CrewAI reduced per-feature orchestration code from hundreds of lines of LangChain plumbing to roughly fifty lines of declarative agent and task definitions. The trade-off is that the framework is younger than some alternatives, and advanced control flows occasionally require workarounds.

The hierarchical process allowed the manager agent to skip cached steps and re-delegate failed ones. The trade-off is slightly higher token cost because the manager itself consumes tokens at each decision.

Gemini 2.5 Flash Lite as the launch model provides strong multimodal capability (so the same model serves the doubt-photo feature), and latency low enough for five-agent crews to finish in under two minutes. The trade-off is free-tier daily-request limits during heavy testing, mitigated by the model-abstraction layer described next.

litellm as the model abstraction means the whole stack can switch from Gemini to Claude, Kimi, Mistral, GPT, or any other supported provider by changing one environment variable, with no code change anywhere in the agents. The trade-off is one indirection layer to debug.

Firestore Vector Search removed an entire second database (no Pinecone or Weaviate to operate) and inherits Firestore's security rules. The trade-off is that per-collection vector indexes must be created manually today.

The real-time listener pattern for live progress meant no custom WebSocket code was needed. The trade-off is tight coupling to Firebase; moving off Firebase would require replacing this mechanism.

Implementation Highlights

The RAG ingestion script processes about 150 PDFs (around 236 megabytes of source material) into tens of thousands of chunks, idempotently. Every AI run writes to a per-run tracker document so the user interface can subscribe and display live progress without any custom networking code. All five AI features standardise on the same authentication scheme and the same output-validation pattern. The 24-hour cache on the PYQ Analyzer is keyed at a stable institution-and-subject path, so two students from the same cohort and subject share the result and the second student gets it instantly.

Limitations and Trade-offs

The backend currently runs locally; production hardening to a managed runtime is on the roadmap. Per-subject vector indexes are still created manually. Despite the litellm abstraction, the project still depends on Google for embeddings, vector store, and cloud platform; production rollout would diversify across at least two vendors. Free-tier rate limits on the language-model provider can interrupt heavy testing days.


Tabassum — PYQ Analyzer

Role In The Project

Tabassum owns the PYQ Analyzer, the platform's flagship AI feature and the largest agent crew in the system — five worker agents plus the manager. PYQ stands for Previous Year Questions. The feature predicts which topics and which exam-style questions are most likely to appear in the next paper for a given subject, based on the past decade of question papers, the official syllabus, and any recent online updates. It is the only feature with a 24-hour shared cache.

What She Built

A student selects their subject and taps Analyze. After 60 to 120 seconds (or instantly if the cache is fresh), the screen shows topic weights — every topic in the subject with a percentage importance score that sums to 100 — and 8 to 12 predicted exam questions written in the same style as past papers. While the student waits, each agent ticks off live as it completes its turn.

The five agents are organised as follows. The Syllabus Researcher uses the retrieval-augmented generation tool against the syllabus PDF and Tavily web search to enumerate every topic. The Web Researcher calls Tavily for current information not in the local corpus. The Pattern Analyst, the analytical core, queries the retrieval tool against the past-question-paper corpus to produce a topic-frequency profile. The Question Predictor combines syllabus, web updates, and patterns into eight to twelve predicted questions. The Output Formatter converts everything into strictly-typed JSON validated against a Pydantic schema. A manager agent decides the running order under CrewAI's hierarchical process.

Splitting roles across five agents instead of using one big prompt produces three measurable improvements. Higher quality, because each agent's prompt is small and focused. Modularity, because one agent can be replaced without touching the others. Demonstrability, because five visibly-working agents tell a clearer story than a single opaque AI call.

A 24-hour shared cache, keyed at a stable institution-and-subject path, ensures the first student in a cohort pays the full cost while every later student that day gets the result instantly.

Tools and Technologies — Critical Evaluation

The five-agent CrewAI crew enabled higher answer quality, modular design, and a strong demonstrative narrative. The trade-off is that five agent calls is roughly five times the language-model usage of a single-call solution; the cache mitigates this for repeated queries.

Retrieval-augmented generation over the full PYQ corpus grounded predictions in real past papers rather than hallucinated trends. The trade-off is that the system is limited to ingested institutions; corpus gaps appear as predictive gaps.

Tavily for current updates captured recent syllabus changes that arrived after the local PDFs were ingested. The trade-off is the free-tier search limit at production scale.

Pydantic validation (with the constraint that topic weights must sum to 100 and the predictions list must be non-empty) eliminated broken results from reaching the user interface. The trade-off is one retry round-trip on validation failure.

The 24-hour Firestore-keyed cache let same-cohort students share the cost. The trade-off is purely time-based invalidation; a syllabus change inside the 24-hour window is not picked up until the next day.

Implementation Highlights

The Pydantic schema enforces that the topic-weights array sums to exactly 100, correcting any percentage drift from the language model before the user sees it. The output is shown live, turning a 90-second wait into engagement, not anxiety. Cache hits on popular subjects return in under one second.

Limitations and Trade-offs

There is no feedback loop yet — students cannot grade predictions after the exam to feed signal back into prompt tuning. Pattern detection is statistical, not causal; a topic that has been hot for ten years could be dropped tomorrow without warning. The launch model's strongest performance is in English, so question papers in regional languages would need a different ingestion path.


Farhan — Snap a Doubt and AllyBot

Role In The Project

Farhan owns two AI features that share infrastructure (the same backend, the same retrieval-augmented generation system) but differ deliberately in design. Snap a Doubt is a slow, deep, multi-agent solver. AllyBot is a fast, single-call conversational assistant. The contrast is itself a design discipline — matching architecture to the latency budget of the user's context.

What He Built

Snap a Doubt. A student photographs a textbook problem (handwritten or printed, with diagrams or equations), picks the subject, and submits. Roughly 30 to 60 seconds later they see the question as the system read it from the photo, a step-by-step solution with reasoning, the final answer, and citations — clickable links that open the relevant page in their own course PDF. The pipeline begins with a vision pre-step. The photo is uploaded to Firebase Cloud Storage at a user-owned path (the path layout is Doubts, then the user ID, then the doubt ID, with a jpg extension; storage rules enforce that the path's user-ID segment matches the requester's authenticated user-ID). The multimodal language model reads the image and the prompt together, with no separate optical-character-recognition step. After extraction, four agents take over: a Topic Classifier identifies the topic, a Solver solves the problem step by step using retrieval-supplied PDF context, a Citation Resolver finds the relevant page numbers for each step, and an Output Formatter builds the final JSON.

AllyBot. While reading any PDF in the app, the student taps the AllyBot floating action button. A chat opens. They ask plain-English questions; AllyBot answers based on that specific PDF only, with page citations, in two to five seconds. AllyBot is a single language-model call wrapped with retrieval context — not an agent crew, deliberately. Conversation has a different latency budget; a four-agent team would be too slow. The cleverness is in the scoping. Every chunk in the vector store carries the resource ID of the PDF it came from. The shared retrieval tool accepts an optional resource-ID filter parameter. AllyBot always passes the current PDF's ID, so retrieval is restricted to chunks from that PDF only, with no cross-PDF leakage.

Tools and Technologies — Critical Evaluation

Multimodal vision in the same model that produces text replaces a two-stage OCR-then-reason pipeline; handwriting is handled better than legacy libraries. The trade-off is that vision quality drops on very blurry or poorly-lit images; the system shows the recognised question to the user as a verification step.

The four-agent split for solving doubts gives each agent a focused task — topic, solving, citation, formatting — and produces higher quality than a single mega-prompt. The trade-off is roughly four language-model calls per doubt rather than one.

The per-user storage path with strict rules for doubt photos means photos cannot be read by another student even if they guess the URL. The trade-off is that photos are stored indefinitely unless an explicit cleanup policy is introduced.

The single-call AllyBot with retrieval scoping meets the chat latency budget of two to five seconds. The trade-off is that the single call has no quality-checking critic; an occasional weak answer cannot be filtered.

The resource-ID filter on the retrieval tool means AllyBot is provably scoped to the PDF the student is reading. The trade-off is that this requires ingestion to have correctly tagged every chunk; a missing tag would be an invisible failure mode.

Implementation Highlights

Citations in Snap a Doubt are working clickable links. The viewer accepts an initial-page-jump parameter, so each citation opens the PDF at exactly that page. AllyBot replaces an earlier external dependency (a third-party document-chat service called via a serverless cloud function); bringing chat in-house was cheaper, faster, and aligned with the rest of the platform's retrieval infrastructure. Doubt photos are stored at user-owned paths whose layout makes a security violation impossible by construction, not just by convention.

Limitations and Trade-offs

Vision is probabilistic; some photos are simply unreadable. Single-call AllyBot has no critic agent; a weak answer slips through. Citation reliability depends on chunking; if a concept is split across two chunks, the Citation Resolver may pick the less helpful one.


Kaviya — Study Planner and Resources/PDF System

Role In The Project

Kaviya owns two responsibilities. The first is the Study Planner, an AI feature with four agents that produces a personalised day-by-day study schedule. The second is the Resources and PDF system — the foundation infrastructure through which every student in the app browses, reads, bookmarks, and downloads study material. The AI features are the marketing-visible novelty, but the resources system is the everyday backbone (the most-used surface in the app) and is the substrate on which the AI features depend, since every PDF the AI agents retrieve was browsed and ingested through this system.

What She Built

Study Planner. The student enters their exam date, the list of subjects, optional weak topics, and a daily-minutes budget. They tap Generate. After 60 to 90 seconds the result is a calendar — every day from today until the exam, populated with one to three concrete study tasks with subject, topic, suggested minutes, and a one-line reason. Hard topics get more time; weak topics receive an additional revision pass closer to the exam. The four agents are the Subject Researcher (which builds a topic list ranked by importance per subject using retrieval), the Strategy Planner (which decides which topics get more time, consulting the mastery snapshot), the Schedule Builder (which maps the strategy to specific calendar dates), and the Output Formatter.

Two design choices lift the feature above generic. The mastery snapshot is a Firestore document containing the student's per-topic mastery scores, populated in particular by Adversarial Examiner answers. It is consulted before the agents run, so the plan is genuinely personalised rather than identical for every student. Calendar anchoring is a guardrail against language-model date hallucination: the date list is pre-computed outside the AI and passed in explicitly, so the Schedule Builder can fill tasks per supplied date but cannot invent or skip dates.

Resources and PDF system. The student picks institution, course, branch, semester, and subject, and lands on a tabbed screen with Notes, Question Papers, Question Banks, and Syllabus tabs. The PDF viewer (built on flutter_pdfview) streams pages from Firebase Cloud Storage, caches files locally for offline reopening, and supports an initial-page-jump parameter (which is what makes Snap a Doubt's clickable citations work). Inside the viewer the user can bookmark, rate, download, share, report, and open AllyBot scoped to that PDF. Bookmarks, recents, and downloads live in user-owned Firestore subcollections under the student's user ID and sync across devices on first sign-in. Search supports multi-field filtering (subject, year, type) backed by Firestore composite indexes. Upload lets a student contribute PDFs through a moderation queue. SeekHub lets a student request resources they cannot find.

Tools and Technologies — Critical Evaluation

The CrewAI four-agent crew for the Study Planner produces personalised, structured output beyond a single-prompt schedule. The trade-off is higher language-model usage than a one-call planner; the result is long-lived (no need to regenerate daily) so this is acceptable.

The mastery-snapshot pre-fetch makes output genuinely personalised. The trade-off is that it requires the student to have used Adversarial Examiner before; new users get a generic plan on day one.

The pre-computed date list passed into the Schedule Builder eliminates an entire class of model bug — wrong dates — by giving the AI the calendar it must fill, not asking it to generate one. The trade-off is one more component to maintain.

flutter_pdfview as the in-app viewer streams large PDFs without re-downloading, supports the initial-page-jump that makes citations work, and caches locally for offline reading. The trade-off is limited annotation support.

Firebase Cloud Storage for PDF hosting provides direct download URLs, auth-gated rules, and integration with Firestore queries. The trade-off is that cost scales with traffic at production scale.

Firestore composite indexes for filtered search produce fast multi-field queries that would otherwise be slow or rejected. The trade-off is that indexes must be declared in advance; adding a new filter means deploying a new index.

User-owned Firestore subcollections under the student's user ID for per-user state give strong isolation by design — security rules can be expressed in a single line. The trade-off is that cross-user analytics queries become awkward and require admin-level access.

Implementation Highlights

Bookmarks survive device changes because they live in Firestore. Downloads work offline once cached. The Upload feature writes to the same Cloud Storage hierarchy that curriculum PDFs use, with three parallel Firestore writes (public library, admin moderation queue, user upload history). The Schedule Builder cannot invent a date; it can only fill or leave blank a date in the supplied list.

Limitations and Trade-offs

New users get a less-personalised first plan because they have no mastery data. If the daily-minutes budget is too small to cover the syllabus before the exam, low-weight topics are dropped; the drop is exposed as prose in the JSON, not as a hard constraint negotiation. Adding a new search filter requires shipping a new composite index. Upload moderation is manual; at scale this would need AI-assisted triage or community moderation.


Giridher — Adversarial Examiner and Firebase Backend Layer

Role In The Project

Giridher owns the Adversarial Examiner AI feature and the Firebase backend layer — the platform infrastructure that holds authentication, the database schema, security rules, push notifications, and the monthly billing cap. Like Kaviya's pairing of an AI feature with foundation work, Giridher's responsibility set crosses the line between user-visible AI and the invisible-but-essential platform plumbing. Every other feature in the app reads or writes through this Firebase layer, and the security rules in particular are what make per-user data isolation real rather than aspirational.

What He Built

Adversarial Examiner. The student picks a subject and taps Generate. About 60 to 90 seconds later, six trap questions appear — questions where most students pick the wrong answer because of a common misconception. Each question carries four multiple-choice options, the correct answer, an explicit description of the common mistake (what most students pick wrong, and why), the correct approach, and the topic and difficulty. When the student answers, wrong answers update their mastery score in Firestore, which feeds back into the Study Planner.

The four agents are the Topic Researcher (which finds topics where students typically struggle, using retrieval and the mastery snapshot), the Trap Designer (which designs questions with one correct answer and three plausible misconception-based wrong options — the creative role), the Verifier (which re-reads each question and rejects ones that are mathematically wrong, ambiguous, or unfair — the critic role), and the Output Formatter. The Trap Designer–Verifier pairing is the generator-critic pattern: splitting creation and review across two specialised prompts produces measurably better output than asking one agent to both create and self-check.

Mastery scores update via an exponential moving average. The new score is 0.7 times the old score plus 0.3 times the current answer, so recent answers weigh more and a student who is improving sees their mastery rise smoothly without single-answer noise dominating.

Firebase backend layer. Authentication via email and password, and Google sign-in, with the user's profile at a path under Users keyed by user ID, and sensitive identity fields under ImmutableUserData. The Firestore database has about 29 collections in four logical groups: public library, per-user state, AI shared state, and community surfaces. Firestore security rules — server-enforced, not application-enforced — limit each user to their own paths and gate admin writes. Cloud Messaging push notifications are topic-based and cohort-scoped (institution plus course plus branch plus semester), with topic names sanitised to remove characters disallowed by the format. The stopBilling Cloud Function listens to a Cloud Billing Pub/Sub topic and disables billing on the project when monthly Firebase spend crosses the configured threshold; this caps Firebase only, with language-model spend monitored separately.

Tools and Technologies — Critical Evaluation

The generator-critic pattern produces higher question quality than a single-agent generator; the Verifier catches errors and ambiguity. The trade-off is two extra agent calls per question, mitigated by being a low-volume feature.

The exponential moving average for mastery scores responds smoothly to improvement and is resilient to single-answer noise. The trade-off is that the weighting choice (0.7 and 0.3) is empirical.

Firestore as both database and vector store gives one platform, one set of rules, one billing relationship, and integrated authentication. The trade-off is that newer Firestore features have rougher tooling than mature alternatives.

Per-user-path security rules give a simple, expressible-in-one-line privacy guarantee. The trade-off is that cross-user analytics queries require special admin pathways.

Topic-based Cloud Messaging scoped to cohort lets notifications reach exactly the right students with no per-user fan-out cost. The trade-off is that topic names must be sanitised — no spaces or special characters.

The stopBilling Cloud Function provides a hard cap on Firebase spend, critical for a student-led project budget. The trade-off is that it caps Firebase only, not the language-model provider, which has to be monitored separately.

The Firestore-document admin claim at ImmutableUserData makes the admin status check expressible inside security rules. The trade-off is that a Firebase Auth Custom Claim would be the production-hardened approach.

Implementation Highlights

The Verifier rejects a measurable proportion of generated trap questions that contain ambiguity or arithmetic errors. Mastery scores written by the Adversarial Examiner are read by the Study Planner, so the two features connect via Firestore as their integration layer rather than via direct API calls. Firestore security rules are deployed and enforced. The stopBilling Cloud Function has been verified end-to-end through IAM, Pub/Sub, and the Cloud Billing API.

Limitations and Trade-offs

The admin claim is a Firestore document field rather than a Firebase Auth Custom Claim — workable for a small admin set but a known production-hardening item. There is no separate language-model cost cap; a second budget alert on the cloud platform is the operational mitigation. Topic-based notifications are coarse — students cannot opt out of a single subject's notifications without unsubscribing from the cohort. Adversarial-question difficulty tuning is an ongoing prompt-engineering exercise.


CROSS-CUTTING ETHICAL AND SOCIAL THEMES

The hooks below are the universal ethical and social angles for the project. Every member's Task 2 (about 1,000 words, 45 percent) can draw from them, in addition to the member-specific hooks in their own sub-section. The writer should select two or three for each report, develop them with depth, and connect them to the member's specific contribution.

Privacy By Architecture

Per-user data isolation is not a policy promise but a server-enforced rule. Every student's bookmarks, recents, downloads, study plans, doubt history, and mastery scores live under user-owned paths and are protected by Firestore security rules. The backend recovers the user's identity from the verified ID token, never from the request body, which closes a common impersonation vector. Doubt photos are stored at user-owned paths under storage rules. The reflective claim is that privacy was treated as an architectural property, not a feature added in app code that an adversary could bypass.

Transparency Through Grounded Retrieval

Retrieval-augmented generation is, by itself, a responsible-AI technique. By forcing every agent to cite a real page from a real PDF, the architecture embeds transparency at the system level. Students can verify the source of any claim. Live progress streaming converts perceived opacity into observable structure. Features are clearly marked as AI-generated; there is no attempt to pass AI output as expert human work.

Auditability Of Autonomous Agents

The hierarchical process produces a visible trace of which agent ran when. This addresses one of the most cited concerns about agentic AI — that automated decisions are made but never explained. The architecture chose a path where the chain of reasoning is recoverable.

Fairness And Equity Of Access

Coaching institutes and senior students at well-connected colleges have always offered exam-pattern analysis to a privileged few. The platform extends similar capabilities to any student with a smartphone. From a stakeholder-impact perspective, this is a positive-equity story. There is, however, a counter-argument the report should engage: if many students in a cohort run the same predictions, study patterns may converge — homogenised preparation is a real risk if the predictions are wrong.

Accountability And Schema Validation

Pydantic schemas enforce a contract on every AI feature's output. Malformed output is rejected before reaching the user. This is a small but real example of holding AI components to a verifiable contract. The generator-critic pattern in Adversarial Examiner generalises this: emerging-tech projects should not deploy single AI components without independent quality checks, whether by another AI, a human review, or a strict schema validator.

Designing Around Known Model Weaknesses

Calendar anchoring (Study Planner) and resource-ID scoping (AllyBot) are concrete examples of designing around documented language-model limitations rather than trusting the model. These are small but real instances of responsible-innovation practice that the rubric specifically rewards.

Vendor Portability And Resilience

The litellm abstraction lets the platform swap the underlying language model with no code change, reducing concentration risk on a single vendor. This is a forward-looking response to vendor-concentration risk in the current AI cycle, and a practical example of designing for the long term rather than the launch.

Cost Cap As Ethical Engineering

A monthly spending cap embodies a real ethical principle: a student-led project must not carry runaway financial risk. This is a forward-looking argument about responsible adoption of cloud-native technology in projects with limited budgets.

Stakeholder Impact

Students are the primary beneficiaries — better preparation, lower search cost, lower preparation anxiety. Faculty are indirect beneficiaries — better-prepared students free time for deeper teaching. Institutions whose intellectual property informs the corpus are stakeholders the architecture explicitly protects. Infrastructure providers are commercial stakeholders, and vendor portability via litellm reduces concentration risk.

Current Trends In Emerging Technology For Project Management

The platform sits at the intersection of three current trends. First, agentic AI — the move from single-call chatbots to coordinated multi-agent systems — is the foreground story. Second, retrieval-augmented generation is the dominant pattern for grounding language models in domain-specific data. Third, vendor-portable AI architecture is a reflection of the industry's maturing concern about lock-in.

Forward-Looking Risks

Hallucination at the long tail: retrieval-augmented generation mitigates but does not eliminate hallucination. Concentration of admin power: a small admin set carries risk, and production hardening is on the roadmap. Student autonomy: AI study companions risk reducing students' own struggle with material; the platform's response is grounded answers with citations, designed to teach and not to substitute. Regulatory uncertainty: data-protection law in many jurisdictions is evolving, including India's recent DPDP Act; the privacy-by-architecture posture is forward-compatible but specific compliance work will be needed at scale.


GLOSSARY

The marker is a project-management academic, not a software engineer. Define these terms on first use.

Agent (in CrewAI): an AI worker with a role, a goal, and a set of tools. In effect, a carefully-prompted call to a language model with permission to invoke specific tools such as retrieval search or web search.

Agentic AI: a class of AI system in which multiple agents collaborate, delegate, and decide. Distinct from a single-call chatbot.

Cosine similarity: a mathematical measure of how close two number lists are.

CrewAI: a Python framework for building teams of AI agents.

Embedding: a list of numbers (768 in this project) that represents the meaning of a piece of text.

Exponential moving average: a weighted average where recent values count more than older ones; used in mastery scores.

FastAPI: a modern Python web framework with built-in support for asynchronous request handling.

FCM (Firebase Cloud Messaging): Firebase's push-notification service; topic-based subscriptions allow broadcasts to logical groups.

Firebase: Google's mobile and web app platform — authentication, database, storage, messaging, and serverless functions in one bundle.

Firestore: Firebase's document database; in this project also the vector store and the live progress tracker.

Firestore Security Rules: server-side rules that decide who can read or write each document; enforced by Firestore itself, not by the app.

Generator-critic pattern: a multi-agent design pattern where one agent creates output and a second agent reviews and rejects bad output.

Hierarchical process (in CrewAI): a mode where a manager agent decides which worker agent runs next, instead of following a fixed order.

JSON: a standard text format for structured data; the output language of every AI feature.

Language model: the general-purpose AI model that produces and reasons over text. The platform uses Gemini at launch but is designed for portability to other providers.

Multimodal model: a model trained on multiple input types — text and images, for example. Multimodality is what enables a model to read photographs.

Pydantic: a Python library for defining and validating data shapes.

PYQ: Previous Year Questions.

RAG (retrieval-augmented generation): a technique that grounds a language model's answer in retrieved real-world content.

Tavily: a search API designed for use by AI agents.

Token: the basic unit a language model reads and produces; roughly a word or part of a word.

Vector Search: a database query that finds documents whose embeddings are closest to a query embedding.


SUGGESTED DIAGRAMS PER MEMBER

The Style mark (10 percent) rewards clean, professional figures. Each report should include two or three. Mermaid, draw.io, Lucidchart, and PowerPoint are all suitable rendering tools.

For Akram

Suggest a system architecture diagram showing the mobile app, the FastAPI backend, the CrewAI crews, and the external services (Firebase, language model, web search), with the bearer-token authentication arrow and the Firestore real-time listener arrow. Suggest a retrieval-augmented generation ingestion pipeline diagram showing PDF, page split, chunking, embedding, and storage in Firestore Vector Search. Suggest a retrieval pipeline diagram showing the agent query, the embedding step, the cosine-similarity search, and the top-K chunks returning to the agent. Suggest a CrewAI hierarchical process diagram with the manager agent at the centre and worker agents around it, showing delegation arrows.

For Tabassum

Suggest a PYQ Analyzer agent flow diagram showing the five workers in their typical order with the manager overseeing them. Suggest a cache hit-or-miss decision diagram (cache fresh leads to cached return; otherwise full crew runs and then stores and returns). Suggest an output schema validation loop diagram (formatter produces JSON, Pydantic validates, accept or retry). Suggest a latency contrast figure comparing cold-start latency of 60 to 120 seconds with cache-hit latency of under one second.

For Farhan

Suggest a Snap a Doubt sequence diagram showing camera capture, upload to user-owned path, vision step, four agents in order (Topic Classifier, Solver, Citation Resolver, Output Formatter), and the result with clickable citations. Suggest a privacy boundary diagram showing the path under Doubts and the user ID, with the storage rule asserting that the requesting user ID matches the path user ID. Suggest an AllyBot scoping diagram showing the PDF in the viewer, AllyBot opening with the resource-ID filter, retrieval scoped to that PDF, and the answer with a page citation. Suggest a latency-design contrast figure comparing the four-agent crew (30 to 60 seconds) with the single call (2 to 5 seconds).

For Kaviya

Suggest a Study Planner data-flow diagram showing inputs, the mastery-snapshot pre-fetch, the four agents, and the JSON plan. Suggest a calendar anchoring guardrail diagram showing what the language model is asked to do (fill tasks per supplied date) versus what it is not asked to do (generate dates). Suggest a resources hierarchy tree showing institution to course to branch to semester to subject to resource type to PDF. Suggest a PDF viewer flow diagram showing tile tap, Firestore lookup, Cloud Storage download URL, viewer, and the optional initial-page jump. Suggest an upload pipeline diagram showing file picked, upload to the resources path, and the three parallel Firestore writes (public library, admin moderation queue, user upload history).

For Giridher

Suggest a generator-critic loop diagram showing the Trap Designer creating a question, the Verifier reviewing, and either accept or reject with reason. Suggest a mastery score update flow diagram showing a wrong answer triggering an exponential-moving-average update at the user's mastery-score path, then consumed by the Study Planner. Suggest a Firebase architecture layers diagram showing Authentication, Firestore (29 collections in four logical groups), Cloud Storage, Cloud Messaging, and Cloud Functions. Suggest a security-rule decision tree showing request arrival, authentication check, path-versus-user-ID match, admin claim check, and allow or deny. Suggest a billing-cap fail-safe diagram showing Cloud Billing publishing to Pub/Sub, the stopBilling Cloud Function consuming the event, and the function calling the Cloud Billing API to disable billing.


QUICK REFERENCE SHEET

Module code: LD7232. Module title: Applied Technologies for Project Management. Word limit: 2,000 words excluding ToC, page numbers, and captions. Submission deadline: 21 May 2026 at 16:00. Application name: Academic Ally. First-deployment universities: Osmania University and JNTUH; the architecture is institution-agnostic. Mobile platform: Flutter (Android primary, iOS supported). Backend: FastAPI on Python 3.12. Multi-agent framework: CrewAI 1.14.3 in hierarchical process. Language model at launch: Gemini 2.5 Flash Lite, with litellm-based portability to Claude, Kimi, Mistral, GPT, and other providers. Embeddings model: gemini-embedding-001 at 768 dimensions. Vector store: Firestore Vector Search. Web search: Tavily. Cloud platform: Firebase on the Blaze plan. Number of AI features live: five (PYQ Analyzer, Study Planner, Adversarial Examiner, Snap a Doubt, AllyBot). Largest crew: PYQ Analyzer with five agents. Smallest AI surface: AllyBot, a single language-model call with retrieval scoping.
