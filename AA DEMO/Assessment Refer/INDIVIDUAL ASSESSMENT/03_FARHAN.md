INDIVIDUAL HACKATHON REFLECTION BRIEFING — FARHAN

For module LD7237 (Contemporary Computing and Digital Technologies, Northumbria University).


HOW TO USE THIS DOCUMENT

This briefing is the source material for Farhan's individual reflective report under module LD7237. The report is 3,000 words, weighted at 70 percent of the module mark, and is due 21 May 2026 at 16:00 via Turnitin.

The report is fundamentally different from the LD7232 group-assessment report. LD7232 evaluates the project's tools and their ethical implications. LD7237 evaluates Farhan's own engagement in the hackathon — leadership, teamwork, learning growth, challenges faced, and personal development. It is reflective, not analytical.

The expert writer should select, paraphrase, and condense from this briefing. The document is several times longer than the report so the writer has selection room. The report should read in Farhan's own voice: first-person, reflective, supported by evidence (portfolio items the writer will integrate from materials supplied separately).

The brief permits AI for grammar, structure, idea organisation, and editorial suggestions, but not for generating whole sentences, paragraphs, or sections of substantive content. The writer must record AI-tool usage on the cover sheet at the front of the submission and in a reference declaration in the bibliography.

The report has two weighted parts. Task 1 (about 2,000 words, 70 marks) is a Portfolio of Evidence — evidence-based reflection on engagement with the hackathon, leadership and teamwork specifics, integrated portfolio items, and application to future practice. Task 2 (about 1,000 words, 30 marks) is a Critical Self-Reflection on contributions, learning-contract goals, challenges, and growth as a collaborative team member.


ABOUT THE HACKATHON AND OUR TEAM

The LD7237 hackathon, themed "AI Agents Unleashed — Building the Future of Automation", brought together MSc students from four programmes (Cyber Security Technology, Computing Technology, Big Data and Data Science, and Artificial Intelligence Technology) to design and develop intelligent agent-based solutions. The brief invited teams to apply principles of agent-based system design, work in interdisciplinary teams, prototype intelligent automation, engage with the ethical and social implications of agentic systems, and pitch a solution backed by real experimentation.

Our team of five — Akram (project lead), Tabassum, Farhan, Kaviya, and Giridher — built Academic Ally, a mobile application for engineering undergraduates that combines an organised study library with five AI-powered features driven by multi-agent crews. Four features (PYQ Analyzer, Study Planner, Adversarial Examiner, Snap a Doubt) use four-to-five agent CrewAI hierarchical crews; one (AllyBot) is a single conversational AI call grounded by retrieval. Every answer is grounded in real PDFs the platform has ingested, with cited page numbers — a deliberate response to the hallucination risks of generic chatbots.

Academic Ally fits the AI Agents Unleashed theme directly. The platform itself is a working example of agentic AI: autonomous, goal-driven specialists collaborating under a manager agent, retrieving real-world data, and producing structured outputs validated against schemas.


MY PERSONAL LEARNING CONTRACT

At the start of the hackathon, I set five personal learning goals.

The first goal was to ship two distinct AI surfaces — one slow and deep (multi-agent), one fast and conversational (single call) — and learn to match architectural shape to user latency context, rather than applying the same pattern indiscriminately.

The second goal was to develop hands-on competence with multimodal AI — vision and text in one model — including its real failure modes (handwriting, lighting, blur, equation recognition) rather than treating it as a black box that always works.

The third goal was to build practical intuition for privacy-by-design — implementing per-user storage paths and rule-enforced isolation that an attacker cannot bypass at the application layer.

The fourth goal was to improve at scope management. I wanted to own two features in hackathon time without cutting the quality of either, by deliberate sequencing and explicit trade-off decisions.

The fifth goal was to practise technical decision-making under contradictory constraints — particularly latency-versus-depth trade-offs, where the best answer depends on the user context.


TASK 1 — PORTFOLIO OF EVIDENCE (about 2,000 words)

My Contribution To The Hackathon

I owned two AI features — Snap a Doubt and AllyBot — that share infrastructure (the same backend, the same retrieval-augmented generation system) but differ deliberately in design.

Snap a Doubt. A student is stuck on a textbook problem. They open Snap a Doubt, take a photo of the problem (handwritten or printed, with diagrams or equations), pick the relevant subject, and submit. Roughly 30 to 60 seconds later they see the question as the system read it from the photo (so they can verify recognition was correct), a step-by-step solution with reasoning, the final answer, and citations — clickable links that open the relevant page in their own course PDF. The pipeline begins with a vision pre-step. The photo is uploaded to Firebase Cloud Storage at a user-owned path (the path layout is Doubts, then the user ID, then the doubt ID, with a jpg extension; storage rules enforce that the path's user-ID segment matches the requester's authenticated user-ID), and the multimodal language model reads the image and the prompt together — there is no separate optical-character-recognition stage. After extraction, four agents take over: a Topic Classifier identifies the topic, a Solver solves the problem step by step using retrieval-supplied PDF context, a Citation Resolver finds the relevant page numbers for each step, and an Output Formatter builds the final JSON.

AllyBot. While reading any PDF in the app, the student taps the AllyBot floating action button. A chat opens. They ask plain-English questions; AllyBot answers based on that specific PDF only, with page citations, in two to five seconds. AllyBot is a single language-model call wrapped with retrieval context — not an agent crew, deliberately. Conversation has a different latency budget; a four-agent team would be too slow. The cleverness is in the scoping. Every chunk in the vector store carries the resource ID of the PDF it came from, the shared retrieval tool accepts an optional resource-ID filter parameter, and AllyBot always passes the current PDF's ID, so retrieval is restricted to chunks from that PDF only.

The contrast between the two features is itself a design lesson. Snap a Doubt can spend 30-plus seconds because the user already expects a wait; AllyBot cannot, because chat needs to feel instant. Matching architecture to latency budget is not a user-experience decision dressed up as engineering — it is engineering driven by a user-facing constraint.

Beyond the features themselves, I worked closely with Akram on the chunking parameters that govern citation quality, and with Giridher on the storage rules that make per-user privacy server-enforced rather than application-enforced. AllyBot also replaces an earlier external dependency (a third-party document-chat service called via a serverless cloud function); bringing chat in-house was cheaper, faster, and aligned with the rest of the platform's retrieval infrastructure.

Leadership And Teamwork In Action

Several specific moments illustrate how I worked with the team.

The latency-budget pivot. My first AllyBot implementation was a four-agent crew, modelled on Tabassum's PYQ Analyzer architecture. In testing, chat felt sluggish. A four-agent team takes 30 seconds or more, and a chat that takes 30 seconds per reply does not feel like chat. I raised this in a stand-up. Kaviya pointed out that AllyBot was the only feature where the user is already inside a reading flow — they want a quick clarification, not a deep analysis. That conversation reframed the design: AllyBot needed a different latency budget, which meant a different architecture. I rebuilt it as a single language-model call with retrieval scoping. This was teamwork making my work better — a teammate noticing a constraint I had not registered.

Vision quality on real student photos. Early Snap a Doubt testing used clean printed problems. The first time we tested with a real handwritten photo (taken in dim dorm-room light, on a phone with a smudged camera), recognition dropped sharply. I added the verification step where the user sees the recognised question before the solver runs, so the user can tell the system that it has misread the question without wasting the 30-second solver run. This was not an architectural change but a small user-experience choice that changed the feature's failure mode from frustrating to recoverable. Tabassum reviewed my verification-step prompt; her feedback was that my version was too apologetic and was confusing the model. I revised it; recognition rate improved.

Citation quality tuning. The Citation Resolver agent sometimes picked less helpful chunks for a step. I worked with Akram on chunking parameters — specifically, the 800-character chunk size and 100-character overlap. We landed on those values after testing 600-character and 1,200-character variants. Smaller chunks gave more precise citations but missed multi-paragraph concepts; larger chunks captured concepts but made citations vaguer. The 800-character middle was a compromise. This was paired engineering work with the platform foundation owner — a kind of cross-feature collaboration that made my feature's quality directly dependent on Akram's substrate.

Storage rule debugging with Giridher. The user-owned doubt-photo path required a storage rule that asserted that the requesting user ID matches the path user ID. The first version of the rule blocked legitimate writes because of an off-by-one in the path-segment indexing. Giridher and I debugged it together over a screen-share. The fix was a one-line change. The teamwork lesson was that security rules are easy to write and hard to test, and that having a teammate familiar with the platform layer (Giridher) is a multiplier on getting them right.

Privacy walkthrough in stand-up. Halfway through the hackathon I walked the team through how the doubt-photo path layout makes a privacy violation impossible by construction, not just by convention. The walkthrough was partly to socialise the privacy posture (so other features could follow the same pattern) and partly to test my own understanding by explaining it. Two teammates asked questions that made me realise I had not thought carefully about photo retention — they are stored indefinitely. I added that as a known follow-up item.

Portfolio Items To Include

The writer will integrate these items, supplied separately by Farhan. Insert at the marked positions in the prose.

Insert a Snap a Doubt sequence figure showing camera, upload, vision, four agents, and the result with citations. Reference it in My Contribution.

Insert an AllyBot scoping figure showing the PDF in the viewer, the resource-ID filter, the retrieval, and the response with citation. Reference it in My Contribution.

Insert a privacy boundary figure showing the path under Doubts and the user ID, with the storage rule. Reference it in storage rule debugging and privacy walkthrough.

Insert a screenshot of a real Snap a Doubt run on a handwritten problem, showing the recognition step and the solution. Reference it in vision quality anecdote.

Insert a screenshot of an AllyBot conversation showing PDF-scoped answers with page citations. Reference it as evidence of working in-PDF chat.

Insert a commit-log excerpt showing the AllyBot architecture changing from a 4-agent crew to a single call. Reference it in the latency-budget pivot.

Insert a short peer-feedback quote from Kaviya or Tabassum about working on the verification step or chunking parameters. Reference it as evidence of teamwork.

Insert a screenshot of the storage rule code showing the path-match assertion. Reference it in storage rule debugging.

Application To Future Practice

The Snap a Doubt and AllyBot experience maps onto three forward-looking trajectories.

Research direction. Multimodal AI, conversational agents, and grounded retrieval are active research areas. Working through the practical detail of vision-plus-text in one call, of single-call-versus-multi-agent design, and of per-PDF retrieval scoping has given me concrete familiarity with the trade-offs that appear in the literature only at a high level. If I pursue further research, I would do so with a working sense of how these design decisions actually feel in production conditions, not just on paper.

Industry direction. Application-level AI engineering — building features around language models — is where the industry is hiring. Snap a Doubt is the kind of feature production engineers ship: a clear user value (solve my doubt), a clear pipeline (image to text to reasoning to citations), and a clear privacy posture (per-user storage, server-enforced rules). AllyBot is the contrasting feature — a chat surface scoped to context — that illustrates a different production pattern. Owning two contrasting AI surfaces is closer to an industry brief than a single-feature student project.

Personal growth. Three things changed in me during the hackathon. I learned that the right architecture for a feature depends on the user's context, not on the team's pattern — applying the four-agent template to AllyBot was a default decision that broke down on contact with chat latency. I improved at failure-mode design — adding the recognition-verification step is a small user-experience change but it converted a frustrating failure into a recoverable one. And I built practical intuition for privacy-by-architecture rather than privacy-by-policy. The path-and-rule combination genuinely cannot be circumvented from the application layer, which is a different kind of guarantee from "we promise we do not read your photos".


TASK 2 — CRITICAL SELF-REFLECTION (about 1,000 words)

Achievement Of Learning Contract Goals

Goal one (ship two contrasting AI surfaces) was fully achieved. Snap a Doubt and AllyBot both demoed live, end-to-end, on real photos and real PDFs. The contrast in their architecture (4-agent crew versus single call) is the substantive deliverable, not just the count of features.

Goal two (multimodal competence) was substantially achieved, with caveats. I now have a real sense of vision quality on actual student photos — handwriting, lighting, equation recognition. I also know the failure modes (very blurry images, complex equations with multiple subscripts) that the platform's verification step is designed to catch. The caveat is that I have not yet explored the model's failure modes on diagrams (circuit schematics, organic chemistry structures), which would matter for a wider deployment.

Goal three (privacy-by-design intuition) was fully achieved. The doubt-photo path layout, combined with the storage rule, is a concrete example of architecture-level privacy. I can now explain why rule-enforced isolation is stronger than application-layer isolation, and I would default to this pattern in any future feature handling user-uploaded media.

Goal four (scope management) was partially achieved. I shipped both features, but the AllyBot rebuild (from 4-agent crew to single call) cost about three days of work that, in retrospect, should have been a smaller pivot. I should have prototyped the single-call version first to test the latency budget before committing to the 4-agent design.

Goal five (technical decision-making under contradictory constraints) was fully achieved. The Snap a Doubt versus AllyBot architectural contrast is itself the achievement. Two features with overlapping constraints, resolved differently because the user contexts differed.

Challenges I Faced And How I Addressed Them

Vision quality on real student photos. Early testing used clean printed problems; real handwriting in dim dorm-room light produced sharply lower recognition rates. I addressed this by adding the verification step where the recognised question is shown to the user before the 30-second solver run, converting a frustrating failure into a recoverable one. The deeper lesson was that user-facing recovery is sometimes a better fix than improving the underlying model, especially when the underlying model is not under your control.

Latency budget for AllyBot. The first chat implementation was a 4-agent crew, modelled on the team pattern. In testing, chat felt sluggish; Kaviya's stand-up observation reframed the design constraint. I rebuilt AllyBot as a single language-model call with retrieval scoping. The challenge was as much about un-learning the team's default pattern as about learning a new one. The lesson is that architectural patterns are tools, not templates — applying the four-agent crew where it does not fit is a category error.

Citation quality. The Citation Resolver sometimes picked less helpful chunks for a step. I addressed this in collaboration with Akram by tuning the chunking parameters — testing 600, 800, and 1,200-character chunk sizes and settling on 800 with 100-character overlap as the best balance. This was paired engineering with the platform foundation owner, and it taught me that feature quality often depends on substrate quality, which I now take as a default mental model.

Replacing the legacy serverless ChatPDF service with the in-house retrieval pipeline. AllyBot replaces an earlier dependency. The challenge was technical (understanding Akram's retrieval infrastructure deeply enough to integrate AllyBot into it) and project-management (coordinating the cutover so the legacy service could be retired without breaking anything). I addressed this by pairing with Akram on the integration and writing a runbook describing the cutover for the rest of the team.

Storage rule correctness. The first version of the user-owned doubt-photo storage rule blocked legitimate writes because of a path-segment indexing bug. Giridher and I debugged it together. The fix was one line. The deeper challenge — and lesson — is that storage rules are easy to write and hard to test; relying on a teammate's familiarity with the platform layer paid off and made me realise I should learn the security rule syntax better myself.

Growth As A Collaborative Team Member

Three things changed in me. First, I stopped applying patterns by default. The four-agent crew is the team's default but it is not always the right shape, and AllyBot is the proof. Second, I learned that user context is an architectural input — a chat needs a different latency budget from a deep solver, and that constraint produces a different architecture. Third, I improved at pair-debugging — working with Akram on chunking and with Giridher on storage rules was faster and produced better outcomes than either of us alone, and I now reach for paired work more readily.

If I were to do this hackathon again, I would prototype the simplest version of each feature first to test the latency budget before committing to a shape, and I would learn the security-rule syntax myself rather than leaning on a teammate to debug a rule I wrote.


THEORETICAL FRAMEWORKS THE WRITER CAN REFERENCE

For academic credibility, anchor reflections in established frameworks.

Gibbs' reflective cycle (Gibbs, 1988): description, feelings, evaluation, analysis, conclusion, action plan. Best fit for Task 2's deeper self-reflection on the AllyBot rebuild.

Kolb's experiential learning cycle (Kolb, 1984): concrete experience (4-agent AllyBot), reflective observation (chat felt sluggish), abstract conceptualisation (latency budget is an architectural input), active experimentation (single-call rebuild). The cycle ran cleanly.

Schön's reflective practitioner (Schön, 1983): both reflection-in-action (the verification-step user-experience response to vision failures) and reflection-on-action (the post-hoc analysis of why the 4-agent template was wrong for chat).

Belbin's team roles (Belbin, 1981). Farhan's role is closest to Implementer (turning ideas into working features) and Resource Investigator (exploring multimodal AI capabilities and bringing what worked back into the team).

Tuckman's stages (Tuckman, 1965): the team's transition through storming (debate over AllyBot's architecture) into norming (the consensus that latency budgets dictate architecture) into performing.

Privacy by design or privacy by architecture (Cavoukian, 1995, expanded in many regulatory contexts): the storage-rule pattern as a working example of the principle.


SUGGESTED DIAGRAMS FOR FARHAN'S REPORT

Suggest a Snap a Doubt sequence diagram showing camera, upload to user-owned path, vision step, four agents, and result with clickable citations.

Suggest an AllyBot scoping diagram showing the PDF in viewer, AllyBot opening with the resource-ID filter, retrieval scoped, and answer with page citation.

Suggest a latency-design contrast figure showing why Snap a Doubt's 4-agent crew (30 to 60 second budget) and AllyBot's single call (2 to 5 second budget) are differently shaped.

Suggest a privacy boundary figure showing the path layout under Doubts with the user ID and the storage rule asserting that the requesting user ID matches.


GLOSSARY

Agentic AI: a class of AI system in which multiple agents collaborate, delegate, and decide.

Citation Resolver: the agent in Snap a Doubt that finds the relevant PDF page for each reasoning step.

CrewAI: the Python framework used for the platform's multi-agent crews.

Embedding: a list of numbers (768 in this project) representing the meaning of a piece of text.

Initial-page-jump: a parameter on the PDF viewer that opens a PDF at a specified page; used by Snap a Doubt's clickable citations.

Multimodal model: a language model trained on multiple input types — text and images, for example. The platform's launch model is multimodal.

OCR (optical character recognition): the process of extracting text from an image. The platform does not use a separate OCR step because the multimodal model performs OCR and reasoning together.

Privacy by architecture: the principle that privacy guarantees should be enforced at the data layer (storage rules, server-side checks), not at the application layer.

RAG (retrieval-augmented generation): a technique that grounds a language model's answer in retrieved real-world content.

Resource ID: a unique identifier attached to every ingested PDF chunk; used by AllyBot's resource-ID filter to scope retrieval to a single PDF.

Storage rules: server-enforced rules in Firebase Cloud Storage that decide who can read or write each path.


QUICK REFERENCE SHEET

Module code: LD7237. Module title: Contemporary Computing and Digital Technologies. Word limit: 3,000 words excluding ToC, page numbers, and captions. Submission deadline: 21 May 2026 at 16:00. Hackathon theme: AI Agents Unleashed — Building the Future of Automation. Team submission: Academic Ally. Farhan's features: Snap a Doubt (vision plus 4-agent solver) and AllyBot (single-call PDF chat). Snap a Doubt agents: Topic Classifier, Solver, Citation Resolver, Output Formatter. Belbin roles most fitting: Implementer and Resource Investigator. Task 1 weighting: about 2,000 words, 70 marks. Task 2 weighting: about 1,000 words, 30 marks. Reflective frameworks: Gibbs, Kolb, Schön, Tuckman, Belbin, Privacy by Design.
