INDIVIDUAL HACKATHON REFLECTION BRIEFING — TABASSUM

For module LD7237 (Contemporary Computing and Digital Technologies, Northumbria University).


HOW TO USE THIS DOCUMENT

This briefing is the source material for Tabassum's individual reflective report under module LD7237. The report is 3,000 words, weighted at 70 percent of the module mark, and is due 21 May 2026 at 16:00 via Turnitin.

The report is fundamentally different from the LD7232 group-assessment report. LD7232 evaluates the project's tools and their ethical implications. LD7237 evaluates Tabassum's own engagement in the hackathon — leadership, teamwork, learning growth, challenges faced, and personal development. It is reflective, not analytical.

The expert writer should select, paraphrase, and condense from this briefing. The document is several times longer than the report so the writer has selection room. The report should read in Tabassum's own voice: first-person, reflective, supported by evidence (portfolio items the writer will integrate from materials supplied separately).

The brief permits AI for grammar, structure, idea organisation, and editorial suggestions, but not for generating whole sentences, paragraphs, or sections of substantive content. The writer must record AI-tool usage on the cover sheet at the front of the submission and in a reference declaration in the bibliography.

The report has two weighted parts. Task 1 (about 2,000 words, 70 marks) is a Portfolio of Evidence — evidence-based reflection on engagement with the hackathon, leadership and teamwork specifics, integrated portfolio items, and application to future practice. Task 2 (about 1,000 words, 30 marks) is a Critical Self-Reflection on contributions, learning-contract goals, challenges, and growth as a collaborative team member.


ABOUT THE HACKATHON AND OUR TEAM

The LD7237 hackathon, themed "AI Agents Unleashed — Building the Future of Automation", brought together MSc students from four programmes (Cyber Security Technology, Computing Technology, Big Data and Data Science, and Artificial Intelligence Technology) to design and develop intelligent agent-based solutions. The brief invited teams to apply principles of agent-based system design, work in interdisciplinary teams, prototype intelligent automation, engage with the ethical and social implications of agentic systems, and pitch a solution backed by real experimentation.

Our team of five — Akram (project lead), Tabassum, Farhan, Kaviya, and Giridher — built Academic Ally, a mobile application for engineering undergraduates that combines an organised study library with five AI-powered features driven by multi-agent crews. Four features (PYQ Analyzer, Study Planner, Adversarial Examiner, Snap a Doubt) use four-to-five agent CrewAI hierarchical crews; one (AllyBot) is a single conversational AI call grounded by retrieval. Every answer is grounded in real PDFs the platform has ingested, with cited page numbers — a deliberate response to the hallucination risks of generic chatbots.

Academic Ally fits the AI Agents Unleashed theme directly. The platform itself is a working example of agentic AI: autonomous, goal-driven specialists collaborating under a manager agent, retrieving real-world data, and producing structured outputs validated against schemas.


MY PERSONAL LEARNING CONTRACT

At the start of the hackathon, I set five personal learning goals.

The first goal was to build and own a flagship multi-agent AI feature end-to-end — from agent design through prompt engineering to schema validation and demo delivery — without leaning on someone else to make the architectural choices for me.

The second goal was to develop deep practical fluency in retrieval-augmented generation. I wanted to understand chunking, embeddings, vector search, and the data-quality pre-conditions for grounded answers, to a level where I could reason about retrieval failures rather than just calling the tool and hoping for the best.

The third goal was to improve at translating ambiguous specifications into concrete agent definitions, particularly when each agent's role must be small enough to be focused but rich enough to contribute distinct value to the chain.

The fourth goal was to grow as a technical presenter — owning the most complex AI feature in the team's demo and being able to explain the five-agent flow to a non-technical audience without losing the technical substance.

The fifth goal was to practise giving and receiving structured peer feedback during agent prompt iteration, and accepting that the first prompt is rarely the right one.


TASK 1 — PORTFOLIO OF EVIDENCE (about 2,000 words)

My Contribution To The Hackathon

I owned the PYQ Analyzer — Academic Ally's flagship AI feature and the largest agent crew in the platform, with five worker agents plus the manager. PYQ stands for Previous Year Questions. The feature predicts which topics and which exam-style questions are most likely to appear in the next paper for a given subject, based on the past decade of question papers, the official syllabus, and any recent online updates. It is the only feature with a 24-hour shared cache, and it became the centrepiece of the team's demo.

The five agents I designed are organised as follows. The Syllabus Researcher uses the retrieval-augmented generation tool against the syllabus PDF and Tavily web search to enumerate every topic in the subject. The Web Researcher calls Tavily for current information not in the local corpus — university announcements, recent syllabus revisions, examination-pattern circulars. The Pattern Analyst, the analytical core, queries the retrieval tool against the past-question-paper corpus to produce a topic-frequency profile by reasoning over the top five matching chunks per query. The Question Predictor combines the syllabus, the web updates, and the historical patterns into eight to twelve predicted exam questions written in the style of the past papers. The Output Formatter converts everything into a strictly-typed JSON object — topic weights summing to 100, predictions as a non-empty list — validated against a Pydantic schema. A manager agent decides the running order under CrewAI's hierarchical process.

I deliberately split the work across five agents instead of using one bigger prompt. The reasoning was three-fold. Each agent's prompt is small and focused, so it does its one job well. The architecture is modular, so one agent can be replaced without touching the others. And a five-agent team is more demonstrable than one opaque AI call when explaining the system to stakeholders.

Beyond the agent design, I worked on the 24-hour caching layer (keyed at a stable institution-and-subject path so two students from the same cohort and subject share the result), the Pydantic schema that enforces topic weights summing to exactly 100, and the live progress writes that drive the run-tracker UI showing each agent ticking off as it finishes.

Leadership And Teamwork In Action

Several specific moments illustrate how I worked with the team.

The role-overload diagnosis. My first attempt at the PYQ Analyzer was a single big agent that tried to enumerate topics, search the web, find patterns, predict questions, and format the output. The output was plausible-sounding but unreliable — predictions changed every run, topics were missed, and the JSON often failed validation. Akram and I sat together for two hours, stepping through the prompts. He asked the question that flipped the design: "What if each of these jobs were a separate agent?" That conversation is the origin of the five-agent crew. The lesson for me was that the right answer was not in the prompt I had written; it was in the structure I had not yet seen. It also illustrated how a teammate's clarifying question can be more useful than their direct advice.

The Pydantic schema iteration. The first version of the schema simply checked that topic weights were all greater than zero. The model would then emit weights summing to 99 or 101 — close but not actually 100. I tightened the schema to enforce exact sum-to-100, which initially produced a cascade of validation failures. Giridher walked me through the retry policy in CrewAI — that on validation failure, the formatter agent is asked to retry up to a configured number of times. Once that retry policy was in place, the schema acted as a real contract rather than a wish: bad output was caught and re-generated automatically. This was teamwork by adjacency. Giridher's expertise on the validation layer made my feature better.

Cost discipline in testing. Five-agent crews are expensive when you re-run them frequently. Mid-hackathon I learned to test individual agents in isolation (calling the agent directly with a fixed input) before triggering full-crew runs. This took my testing-loop cost from many language-model calls per change to a small handful, which let me iterate on prompts without anxiety about quota. I shared this practice with Farhan and Kaviya in a stand-up, and both adopted it.

Caching trade-off discussion. When I proposed the 24-hour cache, Kaviya raised a concern: a real syllabus change would not be picked up for up to 24 hours. The team discussed this in stand-up. We agreed that for the hackathon timeline, time-based invalidation was the right balance — a smarter invalidation (event-driven, triggered when the syllabus PDF changes) was a known follow-up but not worth the complexity in the first build. I documented the trade-off in a comment so a future maintainer would understand the choice, not just the code.

The demo presentation. I presented the PYQ Analyzer in our team demo. Owning the most complex AI feature in the demo meant I had to explain five collaborating agents, retrieval-augmented generation, and the schema-validation loop, all in roughly four minutes, to a panel that included non-AI specialists. I rehearsed the explanation with Kaviya twice. She pushed back when I used jargon (embedding, cosine similarity) without defining it. The final delivery defined the technical terms first, then used them — a discipline I had not previously practised.

Portfolio Items To Include

The writer will integrate these items, supplied separately by Tabassum. Insert at the marked positions in the prose.

Insert a PYQ Analyzer agent flow figure showing the five workers and the manager. Reference it in My Contribution and again in the role-overload diagnosis anecdote.

Insert a screenshot of the run-tracker UI showing each agent ticking off live during a real PYQ run. Reference it when explaining the demo.

Insert a screenshot of a sample output (topic weights and predicted questions for a real subject). Reference it as evidence of the feature working.

Insert a screenshot of the Pydantic schema definition with the sum-to-100 constraint. Reference it in the Pydantic schema iteration anecdote.

Insert a commit-log excerpt showing the agent crew evolving from one big agent to five separate ones. Reference it as evidence of the role-overload diagnosis.

Insert a short peer-feedback quote from Akram or Kaviya about the feature presentation. Reference it in the demo presentation anecdote.

Insert a screenshot of the testing-in-isolation note shared in stand-up about reducing language-model calls. Reference it in cost discipline in testing.

Insert a screenshot of the cache-staleness trade-off comment in code or notes. Reference it in caching trade-off discussion.

Application To Future Practice

The PYQ Analyzer experience maps onto three forward-looking trajectories.

Research direction. Multi-agent system design, prompt engineering, and grounded retrieval are active research areas. Working through five agents in production conditions has given me concrete familiarity with practical failure modes (agents producing valid-looking-but-wrong output, schema-retry loops, manager-agent coordination overhead) that academic descriptions tend to abstract away. If I pursue further research in agentic AI, I would do so with the lived experience of having built a real crew from a problem statement to a working demo.

Industry direction. AI product engineering — building features around language models in production environments — is where the industry is investing right now. The PYQ Analyzer illustrates the practical patterns of that work: agent-as-prompt design, schema-validated outputs, retrieval-augmented grounding, caching for cost control. These are the day-to-day concerns of an AI engineer. Beyond the technical, owning a feature end-to-end (including its public-facing demo) is a closer match to industry product responsibility than typical coursework.

Personal growth. Three things changed in me during the hackathon. I became more comfortable iterating publicly — sharing a half-formed agent design and asking the team to break it, rather than refining it alone before showing anyone. I learned that structure is often the right intervention when the prompt is not working. The role-overload diagnosis is the clearest example. And I improved at presenting technical work to mixed audiences, including the discipline of defining terms before using them.


TASK 2 — CRITICAL SELF-REFLECTION (about 1,000 words)

Achievement Of Learning Contract Goals

Goal one (build a flagship multi-agent feature end-to-end) was substantially achieved. The PYQ Analyzer ships in the demo as a five-agent crew with cache, validation, and live progress. The caveat is that the original architectural insight (five agents instead of one) came from the conversation with Akram, not from me alone. I would not have got there in the time available without that conversation. That is a healthy outcome for a peer team and not a failure of independence — but I want to be the person spotting the structure-versus-prompt problem next time, not the person being shown it.

Goal two (RAG fluency) was fully achieved. I can now reason about retrieval failures (chunking too coarse, query embedding mismatched to corpus embedding, top-K too small to capture context) in a way I could not before the hackathon. The Pattern Analyst's reliance on retrieval forced this fluency, because every prompt iteration was also implicitly an iteration on retrieval quality.

Goal three (translating ambiguous specs into concrete agents) was partially achieved. The five-agent split is, in retrospect, the right shape. But the path to it was longer than it needed to be — I spent over a day on the single-agent version before recognising the structural problem. The lesson is that I should be quicker to reach for role decomposition as a debugging tool, rather than treating prompt iteration as the only knob.

Goal four (presenter growth) was fully achieved. Defining technical terms before using them, rehearsing with a teammate who pushed back on jargon, and owning the demo of the most complex feature were all firsts for me. The recorded demo (if available as portfolio evidence) is the proof.

Goal five (peer feedback) was fully achieved. I asked for feedback from teammates explicitly during the iteration phase, and the prompts improved as a direct result. I also gave feedback to Farhan during his Snap a Doubt vision-step debugging, where I noticed that his verification-step prompt was too apologetic and was confusing the model. He revised it; the recognition rate improved.

Challenges I Faced And How I Addressed Them

Pattern Analyst quality — early prompts produced plausible-but-unreliable trend predictions. This is the role-overload story above. I addressed it by splitting the original single-agent design into five specialised agents, after the conversation with Akram. The deeper challenge was learning to recognise when the right intervention was structural (split the agent) rather than prompt-tuning (rewrite the words). I would now reach for the structural option earlier.

Pydantic schema enforcement — getting topic weights to actually sum to exactly 100. Initially the model would emit values like 99.7 or 100.3, which broke validation. I addressed this in two ways: tightened the schema to enforce exact sum-to-100 (with Giridher's help on the retry policy so failures triggered re-generation), and added an instruction to the formatter prompt that explicitly told the agent the constraint. The combination worked. The lesson is that schema and prompt are complementary, not redundant — the schema enforces what the prompt requests.

Five-agent orchestration debugging. When one agent produced malformed output, downstream agents would misinterpret it and the failure mode was opaque. I addressed this by learning to read CrewAI's verbose-mode trace, which shows each agent's input and output in the run log. Once I could see the chain, debugging became tractable. The deeper takeaway is that observability is a debugging tool, not a luxury.

Cache-staleness trade-off. The 24-hour cache is a known compromise — a real syllabus change inside the window is not picked up. I addressed this by surfacing it explicitly to the team for discussion, documenting the trade-off in code comments, and noting event-driven invalidation as a follow-up item. The lesson is that some trade-offs cannot be eliminated within a hackathon, only acknowledged.

Cost discipline during testing. Five-agent crews are expensive when re-run. I addressed this by adopting agent-in-isolation testing — calling each agent directly with a fixed input before triggering full crews. This collapsed the per-iteration cost and let me iterate without quota anxiety. I shared this practice with the team. The lesson is that hackathon-time cost discipline is a leadership-style behaviour even when not titled as such.

Growth As A Collaborative Team Member

Three things changed in me. First, I stopped treating the prompt as the only knob. I now think about role structure as a first-class design question, not as something to consider only when prompt-tuning fails. Second, I learned that asking for help is faster than struggling alone in a hackathon, and that peer feedback (Akram on structure, Giridher on validation, Kaviya on jargon) was a multiplier on my own work rather than a substitute for it. Third, I improved at presenting under pressure — the discipline of defining terms first, of rehearsing with someone who would push back, of owning the most complex feature in the demo without trying to oversimplify it.

If I were to do this hackathon again, I would split agents earlier (skipping the single-mega-agent dead end), invest in observability tooling on day one (rather than discovering CrewAI's verbose trace mid-debug), and ask for structural feedback before I spent two days iterating on prompts that were chasing the wrong problem.


THEORETICAL FRAMEWORKS THE WRITER CAN REFERENCE

For academic credibility, anchor reflections in established frameworks.

Kolb's experiential learning cycle (Kolb, 1984): concrete experience (the single-agent attempt), reflective observation (the output is plausible but unreliable), abstract conceptualisation (the role-overload pattern), active experimentation (split into five). This cycle ran multiple times in the PYQ Analyzer's evolution.

Gibbs' reflective cycle (Gibbs, 1988): description, feelings, evaluation, analysis, conclusion, action plan. Best fit for Task 2's deeper self-reflection on the Pattern Analyst journey.

Belbin's team roles (Belbin, 1981). Tabassum's role in the team is closest to Plant (creative agent design and the schema-tightening intuition) and Specialist (deep ownership of the most complex feature).

Schön's reflective practitioner (Schön, 1983): both reflection-in-action (mid-debug observability work) and reflection-on-action (post-iteration analysis of what was wrong with the single-agent design).

Tuckman's stages (Tuckman, 1965): the team's transition through storming (debate over agent count and agent boundaries) into norming (the agreed pattern) into performing (each member shipping their feature).

Design Thinking (IDEO, Stanford d.school): empathise, define, ideate, prototype, test. The PYQ Analyzer's evolution roughly tracks these stages, especially the iteration between prototype and test.


SUGGESTED DIAGRAMS FOR TABASSUM'S REPORT

Suggest a PYQ Analyzer agent flow diagram showing the five workers in their typical order with the manager overseeing them.

Suggest a Kolb's cycle diagram applied to the role-overload diagnosis: concrete experience (single-agent attempt), reflection (output unreliable), abstract conceptualisation (role-overload pattern), experimentation (five-agent split).

Suggest a schema-as-contract loop diagram: the formatter agent produces JSON, Pydantic validates, accept or retry — illustrating the schema-and-prompt complementary fix.

Suggest a cache hit-or-miss decision diagram: a fresh cache returns instantly, a stale or missing cache triggers a full crew run.


GLOSSARY

Agentic AI: a class of AI system in which multiple agents collaborate, delegate, and decide.

CrewAI: the Python framework used for the platform's multi-agent crews.

Embedding: a list of numbers (768 in this project) representing the meaning of a piece of text.

Hierarchical process: an orchestration mode where a manager agent decides which worker runs next.

Learning contract: a written set of personal goals identified at the start of a learning experience.

Manager agent: the CrewAI agent that decides delegation order under hierarchical process.

Pydantic: a Python library for defining and validating data shapes; used to enforce the PYQ Analyzer's output contract.

PYQ: Previous Year Questions.

RAG (retrieval-augmented generation): a technique that grounds a language model's answer in retrieved real-world content.

Top-K retrieval: the database query that returns the K closest chunks to a query embedding (K equals five in this project).


QUICK REFERENCE SHEET

Module code: LD7237. Module title: Contemporary Computing and Digital Technologies. Word limit: 3,000 words excluding ToC, page numbers, and captions. Submission deadline: 21 May 2026 at 16:00. Hackathon theme: AI Agents Unleashed — Building the Future of Automation. Team submission: Academic Ally. Tabassum's feature: PYQ Analyzer (the five-agent flagship crew). Agent names: Syllabus Researcher, Web Researcher, Pattern Analyst, Question Predictor, Output Formatter. Belbin roles most fitting: Plant and Specialist. Task 1 weighting: about 2,000 words, 70 marks. Task 2 weighting: about 1,000 words, 30 marks. Reflective frameworks: Gibbs, Kolb, Schön, Tuckman, Belbin, Design Thinking.
