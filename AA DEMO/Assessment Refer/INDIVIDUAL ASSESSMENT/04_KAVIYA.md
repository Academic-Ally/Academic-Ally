INDIVIDUAL HACKATHON REFLECTION BRIEFING — KAVIYA

For module LD7237 (Contemporary Computing and Digital Technologies, Northumbria University).


HOW TO USE THIS DOCUMENT

This briefing is the source material for Kaviya's individual reflective report under module LD7237. The report is 3,000 words, weighted at 70 percent of the module mark, and is due 21 May 2026 at 16:00 via Turnitin.

The report is fundamentally different from the LD7232 group-assessment report. LD7232 evaluates the project's tools and their ethical implications. LD7237 evaluates Kaviya's own engagement in the hackathon — leadership, teamwork, learning growth, challenges faced, and personal development. It is reflective, not analytical.

The expert writer should select, paraphrase, and condense from this briefing. The document is several times longer than the report so the writer has selection room. The report should read in Kaviya's own voice: first-person, reflective, supported by evidence (portfolio items the writer will integrate from materials supplied separately).

The brief permits AI for grammar, structure, idea organisation, and editorial suggestions, but not for generating whole sentences, paragraphs, or sections of substantive content. The writer must record AI-tool usage on the cover sheet at the front of the submission and in a reference declaration in the bibliography.

The report has two weighted parts. Task 1 (about 2,000 words, 70 marks) is a Portfolio of Evidence — evidence-based reflection on engagement with the hackathon, leadership and teamwork specifics, integrated portfolio items, and application to future practice. Task 2 (about 1,000 words, 30 marks) is a Critical Self-Reflection on contributions, learning-contract goals, challenges, and growth as a collaborative team member.


ABOUT THE HACKATHON AND OUR TEAM

The LD7237 hackathon, themed "AI Agents Unleashed — Building the Future of Automation", brought together MSc students from four programmes (Cyber Security Technology, Computing Technology, Big Data and Data Science, and Artificial Intelligence Technology) to design and develop intelligent agent-based solutions. The brief invited teams to apply principles of agent-based system design, work in interdisciplinary teams, prototype intelligent automation, engage with the ethical and social implications of agentic systems, and pitch a solution backed by real experimentation.

Our team of five — Akram (project lead), Tabassum, Farhan, Kaviya, and Giridher — built Academic Ally, a mobile application for engineering undergraduates that combines an organised study library with five AI-powered features driven by multi-agent crews. Four features (PYQ Analyzer, Study Planner, Adversarial Examiner, Snap a Doubt) use four-to-five agent CrewAI hierarchical crews; one (AllyBot) is a single conversational AI call grounded by retrieval. Every answer is grounded in real PDFs the platform has ingested, with cited page numbers — a deliberate response to the hallucination risks of generic chatbots.

Academic Ally fits the AI Agents Unleashed theme directly. The platform itself is a working example of agentic AI: autonomous, goal-driven specialists collaborating under a manager agent, retrieving real-world data, and producing structured outputs validated against schemas.


MY PERSONAL LEARNING CONTRACT

At the start of the hackathon, I set five personal learning goals.

The first goal was to build personalisation that respects user autonomy — designing the Study Planner's mastery-aware logic so the student can see why each topic is allocated time, rather than receiving an opaque schedule from an AI black box.

The second goal was to design and implement the platform's foundation infrastructure — resource browsing, PDF viewing, bookmarks, search, upload, and SeekHub — to a reliability bar that supports every other feature, recognising that foundation work is invisible when it works and catastrophic when it does not.

The third goal was to develop fluency in cross-feature integration — connecting the Study Planner's mastery snapshot to the data Adversarial Examiner produces, making AllyBot accessible from within the PDF viewer, exposing the initial-page-jump that Snap a Doubt's citations need.

The fourth goal was to improve at user-empathy in feature design — offline mode, accessibility under poor network conditions, low-friction bookmarking across devices, search filters that match how students actually look for material.

The fifth goal was to grow as a contributor who works comfortably across both user-interface and backend layers, rather than retreating into a single layer of comfort.


TASK 1 — PORTFOLIO OF EVIDENCE (about 2,000 words)

My Contribution To The Hackathon

I owned two responsibilities. The first is the Study Planner, an AI feature with four agents that produces a personalised day-by-day study schedule. The second is the Resources and PDF system — the foundation infrastructure through which every student in the app browses, reads, bookmarks, and downloads study material. The AI features are the marketing-visible novelty, but the resources system is the everyday backbone (the most-used surface in the app) and is the substrate the AI features depend on, since every PDF the agents retrieve was browsed and ingested through this system.

Study Planner. The student enters their exam date, the list of subjects, optional weak topics, and a daily-minutes budget. They tap Generate. After 60 to 90 seconds the result is a calendar — every day from today until the exam, populated with one to three concrete study tasks with subject, topic, suggested minutes, and a one-line reason. Hard topics get more time; weak topics receive an additional revision pass closer to the exam. The four agents are the Subject Researcher (which builds a topic list ranked by importance per subject using retrieval), the Strategy Planner (which decides which topics get more time, consulting the mastery snapshot), the Schedule Builder (which maps the strategy to specific calendar dates), and the Output Formatter.

Two design choices lift the feature above generic. The mastery snapshot is a Firestore document with per-topic mastery scores populated by Adversarial Examiner answers; it is consulted before the agents run, so the plan is genuinely personalised rather than identical for every student. Calendar anchoring is a guardrail against language-model date hallucination: the date list is pre-computed outside the AI and passed in explicitly, so the Schedule Builder fills tasks per supplied date but cannot invent or skip dates.

Resources and PDF system. The student picks institution, course, branch, semester, and subject, and lands on a tabbed screen with Notes, Question Papers, Question Banks, and Syllabus tabs. The PDF viewer (built on flutter_pdfview) streams pages from Firebase Cloud Storage, caches files locally for offline reopening, and supports an initial-page-jump parameter (which is what makes Snap a Doubt's clickable citations work). Inside the viewer, the user can bookmark, rate, download, share, report, and open AllyBot scoped to that PDF. Bookmarks, recents, and downloads live in user-owned Firestore subcollections and sync across devices on first sign-in. Search supports multi-field filtering (subject, year, type) backed by Firestore composite indexes. Upload lets a student contribute PDFs through a moderation queue. SeekHub lets a student request resources they cannot find.

Leadership And Teamwork In Action

Several specific moments illustrate how I worked with the team.

The calendar-anchoring discovery. My first Study Planner generation produced a schedule with skipped days, repeated dates, and one task scheduled for a date in the wrong month. The agent had hallucinated dates. I raised this with Akram at our daily stand-up. He suggested the principled separation: pre-compute the date list outside the AI and pass it in explicitly. We worked through what that should look like together. The agent now fills tasks per supplied date but cannot invent or delete dates. This was teamwork at its best — a problem I had identified, a structural response Akram contributed, and a working guardrail neither of us could have shipped alone.

Connecting the Study Planner to Adversarial Examiner data. The mastery snapshot was the integration point. Giridher's Adversarial Examiner writes mastery scores when a student answers; my Study Planner reads them before the agents run. Getting the document path and shape compatible required sustained back-and-forth. We agreed on a path under Users keyed by user ID with a MasteryScores subcollection keyed by topic ID, with the score as a single floating-point field updated via exponential moving average. This was cross-feature integration via Firestore as a shared interface, and it makes the two AI features feel connected in a way they would not if each had its own private storage.

Pushing back on jargon during Tabassum's demo rehearsal. Tabassum rehearsed the PYQ Analyzer demo with me. She used embedding and cosine similarity without defining them. I pushed back — the demo audience would include non-AI specialists. She revised to define the terms first, then use them. This was a small teamwork moment but it illustrated the discipline of peer review across features — not just reviewing each other's code, but reviewing how each other communicates the work.

The bookmarks-sync edge case. Bookmarks live in Firestore at a path under the student's user ID with a NotesBookmarked subcollection. The first version had a race condition: a student who bookmarked a PDF while offline, then signed into a second device while still offline, saw inconsistent state. I addressed this by settling on a Firestore-truth model with last-write-wins, documented in code so a future maintainer would understand the trade-off rather than rediscovering it. This is the kind of decision that does not produce visible user-experience but matters when the app is used in real conditions.

The composite-index iteration. Firestore rejected my first multi-field search query (subject plus year plus type). I learned that composite indexes must be declared in advance, then I shipped them as part of the same change as the new filter. After two iterations, the search screen worked at the speed users expect. The lesson, documented for the team, was that any new filter on a Firestore query is also a deployment step, not just a code change.

Designing the Upload moderation flow. Anyone in the team could have designed Upload as a direct write to the public library. I argued in stand-up that this would compromise content quality, since uploads of unknown provenance could pollute the library that the AI agents retrieve from. The team agreed. Upload now writes three Firestore documents in parallel — public library (with a pending flag), admin moderation queue, user upload history. Akram (as admin) reviews the queue before content goes live. This is project-management thinking expressed in feature design: the cost of pollution is high, the cost of moderation friction is low, so the architecture should make moderation default.

Portfolio Items To Include

The writer will integrate these items, supplied separately by Kaviya. Insert at the marked positions in the prose.

Insert a Study Planner data flow figure showing inputs, mastery-snapshot pre-fetch, four agents, and the JSON plan. Reference it in My Contribution.

Insert a calendar anchoring guardrail figure showing what the AI is asked versus not asked to do. Reference it in the calendar-anchoring discovery.

Insert a screenshot of a real Study Planner output for a student with weak-topic data. Reference it as evidence of personalisation working.

Insert a resources hierarchy figure showing institution to course to branch to semester to subject to resource type to PDF. Reference it in the Resources and PDF system description.

Insert a screenshot of the in-app PDF viewer with bookmark, rating, share, and AllyBot button visible. Reference it as evidence of the foundation features.

Insert an Upload pipeline figure showing file picked, upload to path, and three parallel Firestore writes. Reference it in designing the Upload moderation flow.

Insert a commit-log excerpt showing the calendar-anchoring guardrail evolving from hallucinated dates to supplied dates. Reference it in the calendar-anchoring discovery.

Insert a short peer-feedback quote from Giridher about cross-feature integration via mastery snapshot. Reference it in connecting the Study Planner to Adversarial Examiner data.

Insert a screenshot of the Firestore composite index declaration for the search query. Reference it in the composite-index iteration.

Application To Future Practice

The Study Planner and Resources system experience maps onto three forward-looking trajectories.

Research direction. Human-centred AI, personalisation, and the interaction between AI and traditional infrastructure are active research areas. The mastery-snapshot pattern (read traditional database state, feed it into the AI, write the AI's output back as state for other features to read) is a concrete instance of the broader question of how AI features compose with each other. If I pursue further research, I would do so with the lived experience of having built two systems where AI is one part of a larger composition, not the whole feature.

Industry direction. Full-stack mobile and web product engineering — features that span user-interface, backend, and AI — is where industry is investing right now. Owning the Study Planner end-to-end (interface plus backend plus AI integration) and the Resources system end-to-end (interface plus Firestore plus Cloud Storage plus AI integration points) is closer to industry product responsibility than typical layer-specific coursework. The cross-cutting concerns I worked on (offline support, bookmarks sync, composite indexes for search, upload moderation) are exactly the unglamorous correctness problems that distinguish a working product from a demo.

Personal growth. Three things changed in me during the hackathon. I became more comfortable working across both interface and backend layers in the same feature, rather than retreating into one layer. I learned that foundation work is leadership — the team's velocity depends on the resources system being reliable, even when no one explicitly thanks the foundation owner. And I improved at cross-feature thinking — recognising that the Study Planner's mastery snapshot is not just an input to my feature but an interface to Giridher's, with all the discipline that implies.


TASK 2 — CRITICAL SELF-REFLECTION (about 1,000 words)

Achievement Of Learning Contract Goals

Goal one (personalisation that respects user autonomy) was fully achieved. The Study Planner's mastery snapshot is visible to the student in their profile screen, and each task carries a one-line reason explaining why this topic is allocated this much time. Personalisation is not a black box; the student can see the inputs and the rationale.

Goal two (foundation infrastructure to a reliability bar) was substantially achieved. Resources browsing, PDF viewing, bookmarks, search, upload, and SeekHub all demoed live and worked under real network conditions. The caveat is that I discovered the bookmarks-sync race condition only because I tested with two devices; if I had tested only with one, the bug would have shipped. I should have planned multi-device testing from the start, not as an afterthought.

Goal three (cross-feature integration) was fully achieved. The mastery snapshot connects Adversarial Examiner to Study Planner via Firestore. The initial-page-jump in the PDF viewer is consumed by Snap a Doubt's citations. AllyBot opens scoped to the PDF the student is viewing. Each integration point was discussed with the relevant teammate before being implemented.

Goal four (user empathy in feature design) was substantially achieved. Offline support, bookmark sync, and low-friction search filters all reflect user empathy. The caveat is that my first Upload moderation flow had higher friction than necessary (three required fields the user could not skip). Akram pointed this out; I revised. Empathy is a discipline I am still building.

Goal five (cross-layer comfort) was fully achieved. I worked across interface, Firestore, Cloud Storage, and the AI backend integration points. No layer felt off-limits by the end of the hackathon.

Challenges I Faced And How I Addressed Them

Calendar anchoring discovery. The first Study Planner generation produced wrong dates. I addressed this by collaborating with Akram to design the pre-computed-dates guardrail. The deeper challenge was recognising that the AI was not being told to do something it could do — date arithmetic is a known weakness — and that the right architectural response was to not ask the AI to do it. The lesson is that designing around model weaknesses is a category of feature design distinct from prompt engineering.

Bookmarks sync edge case. The offline-write-then-online-conflict scenario was not in any tutorial. I addressed it by settling on a Firestore-truth model with last-write-wins, documented in code. The lesson is that foundation features have edge cases that only appear under realistic use, which is why multi-device testing matters earlier rather than later.

Composite-index iteration for search. Firestore rejected my first multi-field query. I addressed it by learning the composite-index declaration syntax and shipping the index as part of each filter change. The lesson is that database constraints are part of the feature surface, not infrastructure to be solved later.

Upload moderation flow design. Without moderation, the public library would be polluted by uploads of unknown provenance. I addressed this by arguing for parallel writes to a moderation queue and a public-library-with-pending-flag, with admin review before publication. The challenge was less technical than design — convincing the team that adding a step (moderation) was the right call. The lesson is that project-management thinking belongs in feature design, not just in scheduling.

Mastery snapshot integration with Giridher. Getting the document path and shape compatible required sustained back-and-forth. I addressed it by treating the snapshot as a shared interface and discussing the schema before either of us shipped the code that wrote or read it. The lesson is that Firestore as integration layer needs the same interface discipline as a public API, even when both ends are owned by the same team.

Growth As A Collaborative Team Member

Three things changed in me. First, I learned that foundation work is leadership — the resources system being reliable is what made Snap a Doubt's citations work, what made AllyBot scopable, what made the Study Planner's mastery snapshot integratable. The foundation is invisible when it works, and that is the point. Second, I learned that cross-feature integration is interface design, with all the discipline that implies — agreeing on the shape before either side ships, treating the integration point as a shared deliverable. Third, I improved at advocating for design choices that add friction in service of correctness, the Upload moderation flow being the clearest example, where I pushed back against the simpler direct-write design.

If I were to do this hackathon again, I would plan multi-device testing from the start (catching the bookmark-sync race earlier), agree on integration interfaces in writing before either side ships, and lean more on Akram for early architecture conversations rather than discovering structural issues only after the first version is built.


THEORETICAL FRAMEWORKS THE WRITER CAN REFERENCE

For academic credibility, anchor reflections in established frameworks.

Gibbs' reflective cycle (Gibbs, 1988): description, feelings, evaluation, analysis, conclusion, action plan. Best fit for Task 2's deeper self-reflection on the calendar-anchoring discovery.

Kolb's experiential learning cycle (Kolb, 1984): concrete experience (first Study Planner generation with wrong dates), reflective observation (the AI is hallucinating dates), abstract conceptualisation (designing around model weaknesses), active experimentation (the pre-computed-dates guardrail).

Belbin's team roles (Belbin, 1981). Kaviya's role is closest to Teamworker (collaborative across feature owners) and Completer Finisher (the foundation system's edge cases caught before they became problems).

Tuckman's stages (Tuckman, 1965): the team's transition through storming (debate over Upload moderation flow) into norming (agreed integration interfaces) into performing.

Schön's reflective practitioner (Schön, 1983): both reflection-in-action (the bookmarks edge case caught during testing) and reflection-on-action (the post-hoc analysis of the Upload moderation argument).

Donald Norman's user-centred design principles — visible affordances, immediate feedback, clear mental models — particularly relevant to the Resources system's interface choices.


SUGGESTED DIAGRAMS FOR KAVIYA'S REPORT

Suggest a Study Planner data-flow diagram showing inputs, mastery-snapshot pre-fetch, four agents, and the JSON plan output.

Suggest a calendar anchoring guardrail diagram showing what the AI is asked to do (fill tasks per supplied date) versus not asked to do (generate dates).

Suggest a resources hierarchy tree showing institution to course to branch to semester to subject to resource type to PDF.

Suggest an upload pipeline diagram showing file picked, upload to path, and three parallel Firestore writes (public library with pending flag, admin queue, user history).

Suggest a mastery snapshot as integration interface diagram: Adversarial Examiner writes, Study Planner reads, and Firestore is the shared layer.


GLOSSARY

Agentic AI: a class of AI system in which multiple agents collaborate, delegate, and decide.

Calendar anchoring: the practice of pre-computing date lists outside the AI and passing them in, rather than asking the AI to generate dates (which it does poorly).

Composite index (Firestore): a database index that supports multi-field filter queries.

CrewAI: the Python framework used for the platform's multi-agent crews.

Embedding: a list of numbers (768 in this project) representing the meaning of a piece of text.

flutter_pdfview: the Flutter plugin used to view PDFs in the app, with support for streaming, caching, and initial-page-jump.

Foundation infrastructure: the resources, viewer, bookmarks, search, upload, and SeekHub systems that underpin every other feature.

Last-write-wins: a conflict-resolution policy where the most recent write replaces previous values; used in bookmark sync.

Learning contract: a written set of personal goals identified at the start of a learning experience.

Mastery snapshot: a Firestore document with per-topic mastery scores; written by Adversarial Examiner, read by Study Planner.

RAG (retrieval-augmented generation): a technique that grounds a language model's answer in retrieved real-world content.

SeekHub: a feature where students post requests for resources they cannot find; other students or admins fulfil the request.


QUICK REFERENCE SHEET

Module code: LD7237. Module title: Contemporary Computing and Digital Technologies. Word limit: 3,000 words excluding ToC, page numbers, and captions. Submission deadline: 21 May 2026 at 16:00. Hackathon theme: AI Agents Unleashed — Building the Future of Automation. Team submission: Academic Ally. Kaviya's responsibilities: Study Planner (AI feature) and Resources/PDF system (foundation). Study Planner agents: Subject Researcher, Strategy Planner, Schedule Builder, Output Formatter. Belbin roles most fitting: Teamworker and Completer Finisher. Task 1 weighting: about 2,000 words, 70 marks. Task 2 weighting: about 1,000 words, 30 marks. Reflective frameworks: Gibbs, Kolb, Schön, Tuckman, Belbin, Norman's user-centred design.
