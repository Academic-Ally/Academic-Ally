INDIVIDUAL HACKATHON REFLECTION BRIEFING — MOHD MUSTAFA AKRAM

For module LD7237 (Contemporary Computing and Digital Technologies, Northumbria University).


HOW TO USE THIS DOCUMENT

This briefing is the source material for Akram's individual reflective report under module LD7237. The report is 3,000 words, weighted at 70 percent of the module mark, and is due 21 May 2026 at 16:00 via Turnitin.

The report is fundamentally different from the LD7232 group-assessment report. LD7232 evaluates the project's tools and their ethical implications. LD7237 evaluates Akram's own engagement in the hackathon — leadership, teamwork, learning growth, challenges faced, and personal development. It is reflective, not analytical.

The expert writer should select, paraphrase, and condense from this briefing. The document is several times longer than the report so the writer has selection room. The report should read in Akram's own voice: first-person, reflective, supported by evidence (portfolio items the writer will integrate from materials supplied separately).

The brief permits AI for grammar, structure, idea organisation, and editorial suggestions, but not for generating whole sentences, paragraphs, or sections of substantive content. The writer must record AI-tool usage on the cover sheet at the front of the submission and in a reference declaration in the bibliography.

The report has two weighted parts. Task 1 (about 2,000 words, 70 marks total) is a Portfolio of Evidence. It expects an evidence-based reflection on engagement with the hackathon, leadership and teamwork specifics, integrated portfolio items, and application to future practice. Task 2 (about 1,000 words, 30 marks) is a Critical Self-Reflection on contributions, learning-contract goals, challenges, and growth as a collaborative team member. The word count excludes the table of contents, page numbers, and figure or table captions.


ABOUT THE HACKATHON AND OUR TEAM

The LD7237 hackathon, themed "AI Agents Unleashed — Building the Future of Automation", brought together MSc students from four programmes (Cyber Security Technology, Computing Technology, Big Data and Data Science, and Artificial Intelligence Technology) to design and develop intelligent agent-based solutions. The brief invited teams to apply principles of agent-based system design, work in interdisciplinary teams, prototype intelligent automation using code-based or low-code tools, engage with the ethical and social implications of agentic systems, and pitch a solution backed by real experimentation.

Our team of five — Akram (project lead), Tabassum, Farhan, Kaviya, and Giridher — built Academic Ally, a mobile application for engineering undergraduates that combines an organised study library with five AI-powered features driven by multi-agent crews. Four features (PYQ Analyzer, Study Planner, Adversarial Examiner, Snap a Doubt) use four-to-five agent CrewAI hierarchical crews; one (AllyBot) is a single conversational AI call grounded by retrieval. Every answer the AI produces is grounded in real PDFs the platform has ingested, with cited page numbers — a deliberate response to the hallucination risks of generic chatbots.

Academic Ally fits the AI Agents Unleashed theme directly. The platform is, in itself, a working example of agentic AI: autonomous, goal-driven specialists collaborating under a manager agent's coordination, retrieving real-world data, and producing structured outputs validated against schemas. The team chose this submission specifically because it lets the hackathon brief's principles be demonstrated in a single product across multiple agent-based feature crews.


MY PERSONAL LEARNING CONTRACT

At the start of the hackathon, I set five personal learning goals. The writer should treat these as my own objectives for the experience. They should appear early in the report (likely in Task 1's introduction) and be returned to in Task 2's critical self-reflection.

The first goal was to lead an interdisciplinary team of five through an ambitious agentic AI build under hackathon time pressure, while keeping each member empowered to make technical decisions in their own area rather than centralising authority. The intent was to be a coordinator and shaper, not a bottleneck.

The second goal was to deepen my practical mastery of multi-agent orchestration patterns — CrewAI hierarchical processes, retrieval-augmented generation pipelines, and vector-search infrastructure — to a level where I could design conventions other team members could independently build against, rather than re-explaining choices in every conversation.

The third goal was to develop my technical-communication ability by explaining architectural decisions to teammates with different specialisms (cybersecurity, AI, data science backgrounds) so each could contribute confidently within shared conventions, even when their own expertise was orthogonal to the choice being explained.

The fourth goal was to practise integration discipline. That meant defining authentication, progress streaming, and output validation conventions before features were built rather than after, then enforcing them across five independent feature crews so the platform held together as one product rather than five disconnected demos.

The fifth goal was to deliver a demo-ready, multi-feature agentic AI system that meaningfully showcases the hackathon's AI Agents Unleashed theme, end-to-end, in working order, by the demo deadline.


TASK 1 — PORTFOLIO OF EVIDENCE (about 2,000 words)

My Contribution To The Hackathon

I served as the project lead and designed the platform's shared technical foundation: the FastAPI backend service, the retrieval-augmented generation pipeline, and the multi-agent orchestration pattern using CrewAI. These pieces established the conventions the team agreed on collectively — authentication via Firebase ID tokens, live progress streaming through Firestore real-time listeners, and output validation through Pydantic schemas at the end of every agent crew. The four AI feature crews and the chat assistant are built on these foundations, each independently designed and owned by a different teammate.

The technical work fell into three pillars. The shared AI backend service is a single FastAPI service in Python 3.12 that exposes one HTTPS endpoint per AI feature. It handles four cross-cutting concerns (authentication, lifecycle management, live progress streaming, and caching policy) so that no individual feature has to. The retrieval-augmented generation pipeline has an offline ingestion script that splits each PDF page-by-page into 800-character chunks (with a 100-character overlap so meaning is not cut at chunk boundaries), converts each chunk into a 768-dimension embedding vector, and writes a Firestore document containing the chunk text, page number, embedding, and metadata. The retrieval half is a custom CrewAI tool that any agent can call: it embeds the query, asks Firestore Vector Search for the top five chunks by cosine similarity, and returns those chunks with their page numbers. The CrewAI multi-agent pattern uses CrewAI's hierarchical process — a manager agent decides which worker runs next instead of following a hard-coded sequence — which gives the system flexibility (the manager can skip cached steps) and observability (the manager's decisions are visible in the run trace).

Beyond the code, I served as the integration owner. That meant insisting on the same authentication pattern, the same progress-tracker shape, the same Pydantic schema discipline, even when a feature could have shipped slightly faster by skipping one of those. The compounding payoff was a platform that genuinely held together rather than five disconnected demos.

Leadership And Teamwork In Action

Several specific moments illustrate how leadership and teamwork played out on this team.

The agent-pattern proof of concept. Before any feature was built, I prototyped the CrewAI hierarchical pattern end-to-end on a throwaway example. Then I walked the team through it on a screen-share, showing the agent definitions, the task chain, the manager agent, and the Pydantic validation. By choosing to spend two days on a proof-of-concept rather than going straight into feature work, I made it possible for Tabassum, Farhan, Kaviya, and Giridher to start their features on day three with a clear template instead of having to reinvent orchestration logic from scratch.

The shared backend convention session. In the first week we held a 90-minute session where I proposed the four cross-cutting conventions (auth, progress, validation, caching) and invited push-back. Giridher argued for a stricter Pydantic schema policy than I had drafted. Kaviya raised the concern that the progress-tracker shape needed to support partial progress for her Study Planner. Both points became part of the final convention. Treating my draft as a proposal, not a decree, made the conventions stronger and the team's ownership of them deeper.

Unblocking the Pattern Analyst. Tabassum hit a wall when her Pattern Analyst agent kept producing plausible-sounding but unreliable trend predictions. I sat with her for two hours, looked at the prompts, and identified that the agent was being asked to do too much — spotting patterns and writing them up and tagging topics. We split the work into the sequence of agents that became the final five-agent crew. This was leadership of a particular kind — not telling someone what to build, but helping them see the structural problem in what they had.

The free-tier rate-limit incident. Mid-hackathon, the team hit the language-model provider's daily request quota during heavy testing. Three members were blocked simultaneously. Rather than escalating into panic, I documented two mitigations on a shared note (switch to a different model via the abstraction layer, or wait until the quota window reset), confirmed both worked, and shared the runbook to the team. This is the kind of operational moment that, in a longer project, would be specialist work; in a hackathon it has to be improvised by whoever is closest.

Daily 15-minute stand-ups. I introduced a daily 15-minute synchronous stand-up — what each person did yesterday, what they would do today, any blockers. The blockers part was the point. Surfacing them daily, with the whole team listening, made it cheap for someone to ask for help instead of struggling alone. After the first week, the stand-ups had a noticeable effect on velocity and on team cohesion.

Portfolio Items To Include

The writer will integrate these items, supplied separately by Akram. Insert at the marked positions in the prose.

Insert a system architecture figure showing app to backend to CrewAI crews to Firebase, language model, and web search, with bearer-token authentication and real-time-listener arrows. Reference it in My Contribution.

Insert a CrewAI hierarchical-process figure showing the manager agent and five workers. Reference it when explaining the agent pattern.

Insert a screenshot of the whiteboard or diagram from the convention session in week one. Reference it in The Shared Backend Convention Session anecdote.

Insert a screenshot of stand-up notes from one representative day mid-hackathon. Reference it in the Daily Stand-Ups anecdote.

Insert a commit-log excerpt showing the backend skeleton landing first, then each member's feature commits stacking on top. Reference it as evidence of the foundation-first approach.

Insert short peer-feedback quotes from teammates about working under shared conventions. Reference them as evidence of leadership style.

Insert a screenshot of the run-trace UI showing the manager and worker agents ticking off in real time. Reference it when discussing observability.

Insert a screenshot of the language-model rate-limit incident log and the runbook note. Reference it in The Free-Tier Rate-Limit Incident.

Application To Future Practice

The hackathon experience maps onto three forward-looking trajectories.

Research direction. Agentic AI architectures, multi-agent system design, and the engineering of grounded retrieval are active research areas. Working through the practical detail of a hierarchical agent crew with Pydantic-validated outputs has given me concrete familiarity with the failure modes (hallucination, malformed JSON, free-tier rate limits, vector index management) that academic papers tend to abstract away. If I pursue further research, this lived experience is the sort of grounded foundation that turns a hand-wavy thesis idea into something testable.

Industry direction. The hackathon was, in effect, a compressed simulation of building production AI infrastructure: shared conventions across multiple feature owners, observable agent runs, schema-validated outputs, vendor-portable model abstractions, and operational discipline (billing caps, rate-limit runbooks). These are the problems organisations are paying engineers to solve right now. Beyond the technical, the practice of leading an interdisciplinary team of five — with different academic backgrounds and different working styles — is closer to real-world engineering management than any solo coursework can be.

Personal growth. Three things changed in me during the hackathon. I became more comfortable making architectural decisions in front of teammates, taking the discomfort of being wrong in public as the cost of moving the team forward. I improved at separating the what of a problem from the how of a solution when helping someone debug — not telling them my fix, but asking the questions that helped them see the structural issue. And I learned the discipline of making conventions cheap to follow: if the shared rule is annoying to comply with it will be ignored, regardless of how senior the person is who wrote it down.


TASK 2 — CRITICAL SELF-REFLECTION (about 1,000 words)

Achievement Of Learning Contract Goals

Goal one (lead a team of five) was substantially achieved, with caveats. The team shipped five working AI features and a coherent platform. No member was bottlenecked on me for more than a day at any point. The caveat is that the hackathon's compressed timeline meant some leadership decisions I would normally take collaboratively (the choice of CrewAI over LangChain, for example) were made unilaterally to save time. With more days, those should have been team decisions. The pattern of unilateral early decisions is something to be more careful about in future projects.

Goal two (multi-agent orchestration mastery) was fully achieved. Designing the hierarchical pattern from scratch, debugging it under pressure, and explaining it to four teammates with different backgrounds gave me the kind of practical depth that no tutorial could have. The proof is concrete: I can now reason about agent failure modes (manager agent looping, worker agent producing valid-but-wrong output, schema retry exhaustion) in a way I could not before the hackathon.

Goal three (technical communication) was partially achieved. I improved at explaining architectural decisions to teammates with different specialisms, and the convention session in week one is the strongest evidence. But I caught myself mid-hackathon assuming Tabassum understood vector search the way I did; she had asked about it twice and I had not noticed. The lesson is that checking understanding is a separate skill from explaining, and I need to develop the checking discipline more.

Goal four (integration discipline) was fully achieved. The four cross-cutting conventions held across all five features. Every feature passes a Firebase ID token in the same header, writes progress in the same shape, validates output against a Pydantic schema, and returns structured JSON. This is the goal that paid the highest dividend; five disconnected feature crews would have been a much weaker demo.

Goal five (demo-ready system) was fully achieved. All five AI features demoed live on the deadline day, end-to-end, on real cohort data, with no fallback to mocked screens.

Challenges I Faced And How I Addressed Them

Coordinating five people with different schedules and skill levels under hackathon pressure. Two of the team members are stronger on backend, two on user interface, and one on operations. Time-zone differences (some sessions were virtual) added asynchronous coordination overhead. I addressed this with the daily stand-ups, an asynchronous shared-notes channel, and explicit role assignment — each member owned their feature top-to-bottom rather than splitting features by layer. The result was cleaner ownership and fewer hand-offs.

Designing the AI backend's interface before fully understanding feature requirements. The conventions for auth, progress, validation, and caching had to land before any feature was built — but at that point I did not yet know the exact shapes the five features would need. I addressed this by deliberately over-specifying the shape of conventions while leaving room to extend (a progress tracker that could carry arbitrary key-value state per agent, for example, rather than a fixed schema). Two later extensions (Kaviya's partial-progress field and Giridher's mastery-snapshot read) fit cleanly into the original shape because of this. The lesson is that interface design under uncertainty is about leaving the right things flexible, not about anticipating every requirement.

Free-tier rate limits on the language-model provider. Hit during a heavy testing day; three members blocked at once. I addressed this by writing a runbook on a shared note (switch to a different model in the same family via the abstraction layer, or wait for the quota window reset), validating both mitigations, and sharing them. The deeper lesson was that the model abstraction we had built specifically for vendor portability paid off operationally, not just architecturally. Switching the model became a one-line change anyone on the team could perform.

Vector-search index manual creation friction. Each subject key requires a separate Firestore Vector Search index, created via the cloud console (no command-line support yet at the time of the hackathon). When new subjects were ingested, retrieval would fail silently until the index was created. I addressed this in the short term by maintaining a shared spreadsheet of indexes-needed and checking it whenever a teammate added a subject. The proper fix — automating index creation via a script — is on the post-hackathon hardening list.

Balancing leadership with hands-on building. When both were needed at the same time, I sometimes deferred my own coding to unblock teammates. This was usually the right call but it occasionally left the foundation work behind schedule. I addressed it by paired-working on Sundays — sitting next to one teammate while making backend progress in parallel. Imperfect, but better than choosing one over the other.

Growth As A Collaborative Team Member

Three things changed. First, I learned that making conventions cheap to follow is more important than making them strict. A convention that adds friction will be circumvented, and I noticed myself rewriting two conventions mid-hackathon to make them lower-friction without losing rigour. Second, I learned that the role of a project lead in a peer team is closer to coordinator than commander — facilitating decisions rather than making them, and unblocking rather than directing. The Belbin coordinator and shaper pairing fit my actual behaviour better than I had expected. Third, I learned that observability is not just an engineering concern. When teammates can see what is happening (the run trace, the stand-up notes, the rate-limit runbook), they can self-correct without waiting for me, which scales the team in a way command-and-control cannot.

If I were to do this hackathon again, I would invest more time earlier in checking rather than just telling, and I would budget explicit time for hands-on coding rather than letting it leak around the edges of leadership work.


THEORETICAL FRAMEWORKS THE WRITER CAN REFERENCE

For the report's academic credibility, the writer should anchor reflections in established frameworks. The most relevant for Akram's leadership-and-foundation role are the following.

Tuckman's stages of group development (Tuckman, 1965; Tuckman and Jensen, 1977): forming, storming, norming, performing, adjourning. The team moved through storming (debates over agent design and convention choices in week one) into norming (the shared conventions session) into performing (each member shipping their feature). Akram's role was particularly visible in pulling the team from storming into norming.

Belbin's team roles (Belbin, 1981). Akram's behaviour fits the Coordinator and Shaper pairing: clarifying goals, organising tasks, delegating effectively, while also driving the team forward and challenging stagnation.

Hersey and Blanchard's situational leadership (Hersey and Blanchard, 1969): adapting leadership style to follower readiness. Akram applied directive leadership early (the proof-of-concept walkthrough), then shifted to coaching (sitting with Tabassum on the Pattern Analyst), and finally to delegating (trusting each member with their feature end-to-end).

Schön's reflective practitioner (Schön, 1983), particularly reflection-in-action, which describes the rate-limit incident: noticing the problem, switching to a workaround, and documenting it for the team in real time.

Kolb's experiential learning cycle (Kolb, 1984): concrete experience (building), reflective observation (the Pattern Analyst debugging session), abstract conceptualisation (recognising the role-overload pattern), active experimentation (splitting the agent into five). This cycle ran multiple times across the hackathon.

Gibbs' reflective cycle (Gibbs, 1988): a structured framework for the report's overall reflective passages, with description, feelings, evaluation, analysis, conclusion, and action plan. Most useful for Task 2's deeper self-reflection.


SUGGESTED DIAGRAMS FOR AKRAM'S REPORT

Two or three figures are appropriate. The Style mark rewards clean, professional rendering.

Suggest a system architecture diagram showing the mobile app, the FastAPI backend, the CrewAI crews, and the external services. Useful in Task 1 when describing what was built.

Suggest a CrewAI hierarchical-process diagram showing the manager agent at the centre and four to five worker agents around it, with delegation arrows.

Suggest a Tuckman's stages diagram mapped to the hackathon timeline, with forming in week one, storming mid-week-one, norming around the convention session, performing mid-hackathon to demo, and adjourning in the post-demo retrospective. Mark Akram's leadership interventions at the transitions.

Suggest a Kolb's experiential learning cycle figure applied to a single Akram-led debugging incident (for instance the Pattern Analyst restructuring with Tabassum).


GLOSSARY

Agentic AI: a class of AI system in which multiple agents collaborate, delegate, and decide; distinct from a single-call chatbot.

Belbin team roles: a framework that classifies how individuals contribute to teams (Coordinator, Shaper, Plant, Resource Investigator, Monitor Evaluator, Teamworker, Implementer, Completer Finisher, Specialist).

CrewAI: a Python framework for building teams of AI agents; used for the platform's multi-agent crews.

Embedding: a list of numbers (768 in this project) representing the meaning of a piece of text.

Forming, Storming, Norming, Performing, Adjourning: Tuckman's five stages of group development.

Hierarchical process (in CrewAI): an orchestration mode where a manager agent decides which worker agent runs next.

Learning contract: a written set of personal goals identified at the start of a learning experience, used as a reflection anchor afterwards.

Portfolio of evidence: the collection of artefacts (screenshots, commits, peer feedback, diagrams) that supports an evidence-based reflective report.

RAG (retrieval-augmented generation): a technique that grounds a language model's answer in retrieved real-world content.

Reflection-in-action: Schön's term for noticing and adjusting in real time, mid-task, rather than only after the fact.


QUICK REFERENCE SHEET

Module code: LD7237. Module title: Contemporary Computing and Digital Technologies. Word limit: 3,000 words excluding ToC, page numbers, and captions. Submission deadline: 21 May 2026 at 16:00. Hackathon theme: AI Agents Unleashed — Building the Future of Automation. Team submission: Academic Ally. Team size: five. Akram's role: project lead; architecture, retrieval-augmented generation pipeline, CrewAI multi-agent foundation. Belbin roles most fitting: Coordinator and Shaper. Task 1 weighting: about 2,000 words, 70 marks (Evidence-Based Reflection 40 plus Application to Future Practice 30). Task 2 weighting: about 1,000 words, 30 marks (Critical Self-Reflection). Reflective frameworks to anchor against: Gibbs, Kolb, Schön, Tuckman, Belbin, Hersey-Blanchard. AI use disclosure required on the cover sheet at the front of the submission and in a reference declaration in the bibliography.
