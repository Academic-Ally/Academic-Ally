INDIVIDUAL HACKATHON REFLECTION BRIEFING — GIRIDHER

For module LD7237 (Contemporary Computing and Digital Technologies, Northumbria University).


HOW TO USE THIS DOCUMENT

This briefing is the source material for Giridher's individual reflective report under module LD7237. The report is 3,000 words, weighted at 70 percent of the module mark, and is due 21 May 2026 at 16:00 via Turnitin.

The report is fundamentally different from the LD7232 group-assessment report. LD7232 evaluates the project's tools and their ethical implications. LD7237 evaluates Giridher's own engagement in the hackathon — leadership, teamwork, learning growth, challenges faced, and personal development. It is reflective, not analytical.

The expert writer should select, paraphrase, and condense from this briefing. The document is several times longer than the report so the writer has selection room. The report should read in Giridher's own voice: first-person, reflective, supported by evidence (portfolio items the writer will integrate from materials supplied separately).

The brief permits AI for grammar, structure, idea organisation, and editorial suggestions, but not for generating whole sentences, paragraphs, or sections of substantive content. The writer must record AI-tool usage on the cover sheet at the front of the submission and in a reference declaration in the bibliography.

The report has two weighted parts. Task 1 (about 2,000 words, 70 marks) is a Portfolio of Evidence — evidence-based reflection on engagement with the hackathon, leadership and teamwork specifics, integrated portfolio items, and application to future practice. Task 2 (about 1,000 words, 30 marks) is a Critical Self-Reflection on contributions, learning-contract goals, challenges, and growth as a collaborative team member.


ABOUT THE HACKATHON AND OUR TEAM

The LD7237 hackathon, themed "AI Agents Unleashed — Building the Future of Automation", brought together MSc students from four programmes (Cyber Security Technology, Computing Technology, Big Data and Data Science, and Artificial Intelligence Technology) to design and develop intelligent agent-based solutions. The brief invited teams to apply principles of agent-based system design, work in interdisciplinary teams, prototype intelligent automation, engage with the ethical and social implications of agentic systems, and pitch a solution backed by real experimentation.

Our team of five — Akram (project lead), Tabassum, Farhan, Kaviya, and Giridher — built Academic Ally, a mobile application for engineering undergraduates that combines an organised study library with five AI-powered features driven by multi-agent crews. Four features (PYQ Analyzer, Study Planner, Adversarial Examiner, Snap a Doubt) use four-to-five agent CrewAI hierarchical crews; one (AllyBot) is a single conversational AI call grounded by retrieval. Every answer is grounded in real PDFs the platform has ingested, with cited page numbers — a deliberate response to the hallucination risks of generic chatbots.

Academic Ally fits the AI Agents Unleashed theme directly. The platform itself is a working example of agentic AI: autonomous, goal-driven specialists collaborating under a manager agent, retrieving real-world data, and producing structured outputs validated against schemas.


MY PERSONAL LEARNING CONTRACT

At the start of the hackathon, I set five personal learning goals.

The first goal was to apply the generator-critic pattern in a real product feature — Adversarial Examiner — and reflect on whether two specialised agents (creator and verifier) really do produce measurably better output than one agent asked to both create and self-check.

The second goal was to develop fluency in cloud-platform security — Firestore rules, authentication, per-user isolation — at a level that is server-enforced rather than application-enforced, recognising that application-layer privacy promises are weaker than data-layer enforcement.

The third goal was to build operational discipline in a cloud-native environment — billing caps, IAM, Pub/Sub, Cloud Functions, deployment — for a project on a tight student budget where surprise costs are catastrophic.

The fourth goal was to practise systems thinking — designing Adversarial Examiner so its mastery-score output would feed seamlessly into Kaviya's Study Planner via Firestore, without direct API coupling between the two features.

The fifth goal was to grow as a backend specialist who thinks about user experience, not just data correctness — recognising that backend choices (notification topic granularity, billing-cap behaviour) are felt by users even though they are invisible.


TASK 1 — PORTFOLIO OF EVIDENCE (about 2,000 words)

My Contribution To The Hackathon

I owned the Adversarial Examiner AI feature and the Firebase backend layer — the platform infrastructure that holds authentication, the database schema, security rules, push notifications, and the monthly billing cap. Like Kaviya's pairing of an AI feature with foundation work, my responsibility set crosses the line between user-visible AI and the invisible-but-essential platform plumbing. Every other feature in the app reads or writes through the Firebase layer, and the security rules in particular are what make per-user data isolation real rather than aspirational.

Adversarial Examiner. The student picks a subject and taps Generate. About 60 to 90 seconds later, six trap questions appear — questions where most students pick the wrong answer because of a common misconception. Each question carries four multiple-choice options, the correct answer, an explicit description of the common mistake (what most students pick wrong, and why), the correct approach, and the topic and difficulty. When the student answers, wrong answers update their mastery score in Firestore, which feeds back into the Study Planner.

The four agents are the Topic Researcher (which finds topics where students typically struggle, using retrieval and the mastery snapshot), the Trap Designer (which designs questions with one correct answer and three plausible misconception-based wrong options — the creative role), the Verifier (which re-reads each question and rejects ones that are mathematically wrong, ambiguous, or unfair — the critic role), and the Output Formatter. The Trap Designer and Verifier pairing is the generator-critic pattern: splitting creation and review across two specialised prompts produces measurably better output than asking one agent to both create and self-check, because the Trap Designer's prompt can be optimised for creativity without diluting it with strict self-checking instructions.

Mastery scores update via an exponential moving average. The new score is 0.7 times the old score plus 0.3 times the current answer, so recent answers weigh more and a student who is improving sees their mastery rise smoothly without single-answer noise dominating.

Firebase backend layer. Authentication via email and password and Google sign-in, with the user's profile at a path under Users keyed by user ID, and sensitive identity fields under ImmutableUserData. The Firestore database has about 29 collections in four logical groups: public library, per-user state, AI shared state, and community surfaces. Firestore security rules — server-enforced, not application-enforced — limit each user to their own paths and gate admin writes. Cloud Messaging push notifications are topic-based and cohort-scoped (institution plus course plus branch plus semester), with topic names sanitised to remove characters disallowed by the format. The stopBilling Cloud Function listens to a Cloud Billing Pub/Sub topic and disables billing on the project when monthly Firebase spend crosses the configured threshold; this caps Firebase only, with language-model spend monitored separately.

Leadership And Teamwork In Action

Several specific moments illustrate how I worked with the team.

Defending the Verifier agent. Early in the hackathon, Akram and I debated whether Adversarial Examiner needed a separate Verifier agent or whether the Trap Designer could be asked to self-check. I argued for separation, citing the generator-critic pattern in the literature. Akram pushed back with the cost concern — two agent calls per question is expensive. I responded by running both versions on a small test set and showing that the single-agent design produced about 40 percent of questions with mathematical errors, ambiguous answers, or unfair traps, while the two-agent design dropped that to under 5 percent. Quantified evidence settled the debate. The lesson was that advocating for an architectural choice requires evidence, not just citation, and that a two-hour evening of running test cases was a much smaller cost than an indefinite design dispute.

Helping Tabassum with Pydantic retry policy. Tabassum hit a wall when her PYQ Analyzer's Pydantic schema kept rejecting model output where topic weights summed to 99 or 101 instead of exactly 100. I walked her through CrewAI's retry policy — that on validation failure, the formatter agent is automatically asked to retry up to a configured number of times. Once that retry policy was in place, the schema acted as a real contract rather than a wish: bad output was caught and re-generated automatically. This was teamwork by adjacency. My expertise on the validation layer made her feature better.

Storage rule debugging with Farhan. Farhan's user-owned doubt-photo path needed a storage rule asserting that the requesting user ID matches the path user ID. The first version blocked legitimate writes because of an off-by-one in path-segment indexing. We debugged it together over a screen-share. The fix was a one-line change. But the debugging required familiarity with Firebase's rule-evaluation semantics that Farhan did not yet have. The teamwork lesson was that security rules are easy to write and hard to test, and that a teammate familiar with the platform layer is a multiplier on getting them right.

The mastery-score schema agreement with Kaviya. Kaviya's Study Planner reads the mastery scores my Adversarial Examiner writes. We agreed on a path under Users keyed by user ID with a MasteryScores subcollection keyed by topic ID, with the score as a single floating-point field. The discussion happened before either of us shipped code; we treated the document shape as a shared interface, not as private storage on either side. The lesson is that Firestore as integration layer needs the same interface discipline as a public API, even when both ends are owned by the same team.

Wiring the billing-cap fail-safe. The stopBilling Cloud Function is a fail-safe against runaway Firebase spend. Wiring it end-to-end took a full day: IAM permissions for the Cloud Function to call the Billing API, Pub/Sub topic linking to the Cloud Billing budget, the Cloud Function code itself, and a test by setting a deliberately-low threshold to confirm billing actually got disabled. I documented each step in a runbook so the team could repeat the setup on a future cloud project. This was infrastructure work that the rest of the team did not see, but the team's confidence to test heavily depended on knowing the cap was real.

The notification-topic sanitisation gotcha. Cloud Messaging topic names disallow spaces and certain other characters. The team's branch names include strings like "CSE AIML" with a space. The first push notification attempt failed silently because the topic name violated the format. I built a regex sanitiser that replaces disallowed characters with hyphens and shared a one-line note on the team channel describing the constraint. Small fix, broadly applicable, documented for the team.

Portfolio Items To Include

The writer will integrate these items, supplied separately by Giridher. Insert at the marked positions in the prose.

Insert a generator-critic loop figure showing Trap Designer creates, Verifier reviews, accept or reject with reason. Reference it in My Contribution and in defending the Verifier agent.

Insert a mastery score update flow figure showing wrong answer triggers the exponential-moving-average update, consumed by Study Planner. Reference it in the mastery-score schema agreement.

Insert a Firebase architecture layers figure showing authentication, Firestore, Cloud Storage, Cloud Messaging, and Cloud Functions. Reference it in the Firebase backend layer description.

Insert a security-rule decision tree figure showing authenticated, path-user-ID match, admin claim required, and allow or deny. Reference it in storage rule debugging.

Insert a billing-cap fail-safe figure showing Cloud Billing to Pub/Sub to stopBilling Cloud Function to Cloud Billing API. Reference it in wiring the billing-cap fail-safe.

Insert a screenshot of a real Adversarial Examiner output showing six trap questions with common-mistake explanations. Reference it as evidence of feature working.

Insert a screenshot or chart of the test-set comparison showing 40 percent defect rate with single-agent design versus 5 percent with generator-critic. Reference it in defending the Verifier agent.

Insert a commit-log excerpt showing security rules deployed and verified. Reference it as evidence of server-enforced isolation.

Insert a short peer-feedback quote from Tabassum about the Pydantic retry-policy help. Reference it in helping Tabassum.

Insert a screenshot of stopBilling Cloud Function code or deployment logs. Reference it in wiring the billing-cap fail-safe.

Application To Future Practice

The Adversarial Examiner and Firebase backend experience maps onto three forward-looking trajectories.

Research direction. Multi-agent quality control, generator-critic patterns, and AI accountability are active research areas. The Adversarial Examiner's Verifier is a working instance of AI checking AI — a pattern that generalises far beyond exam question generation, into any domain where AI output needs gating before it reaches a user. If I pursue further research, the lived experience of designing a generator-critic loop, measuring its impact on defect rate, and tuning it to avoid over-rejection is the sort of grounded foundation that turns a thesis idea into something testable.

Industry direction. Backend engineering, cloud security, and machine-learning operations (MLOps) are where the industry is investing. The Firebase backend layer I built is, in miniature, a production-style system: authenticated, rule-protected, observable, cost-capped. The patterns I worked with (server-enforced security rules, IAM-bound Cloud Functions, Pub/Sub event flows) are exactly what production engineers ship. Beyond the technical, the discipline of defending architectural choices with evidence — running test sets to settle design debates rather than relying on argument — is closer to industry engineering practice than typical coursework.

Personal growth. Three things changed in me during the hackathon. I learned that the right way to settle an architectural debate is often a small experiment, not a longer argument — the Verifier-agent test set is the clearest example. I learned that infrastructure work is leadership, even when it is invisible — the team's confidence to test heavily depends on the billing cap being real, not just notional. And I improved at thinking of Firestore as integration layer, treating shared documents as interfaces with the discipline that implies, rather than as convenient storage either side could shape independently.


TASK 2 — CRITICAL SELF-REFLECTION (about 1,000 words)

Achievement Of Learning Contract Goals

Goal one (generator-critic pattern in a real feature) was fully achieved with measurable evidence. The 40-percent versus 5-percent defect-rate comparison is the strongest evidence in any of my hackathon work. The Verifier agent demonstrably produces better output than a self-checking single agent.

Goal two (cloud-platform security fluency) was substantially achieved. Firestore security rules across the per-user-state, public-library, and AI-shared-state collections are deployed and enforced. The caveat is that the admin claim is currently stored as a Firestore document field rather than as a Firebase Auth Custom Claim — a known limitation given hackathon time constraints. Custom Claims via a Cloud Function is a production-hardening item I would prioritise next.

Goal three (operational discipline) was fully achieved. The stopBilling Cloud Function is wired end-to-end, tested, and documented. IAM permissions, Pub/Sub event flows, and the Cloud Billing API integration are each verified independently. The runbook lets the team repeat the setup on a future project.

Goal four (systems thinking via Firestore as integration layer) was fully achieved. The mastery-score document is the integration interface between Adversarial Examiner (writer) and Study Planner (reader), with no direct API coupling. The schema was agreed in writing before either of us shipped code.

Goal five (backend specialist who thinks about user experience) was partially achieved. I noticed the Cloud Messaging topic-name issue (which would have produced a silent user-experience failure for any branch with a space in its name) and fixed it before it reached users. But I did not initially consider that topic-based notifications are too coarse — students cannot opt out of a single subject's notifications without unsubscribing from the cohort. This is a user-experience limitation I now see but did not anticipate.

Challenges I Faced And How I Addressed Them

Generator-critic loop tuning. Early Verifier prompts rejected too aggressively, including good questions whose wrong options were merely creative rather than misleading. I addressed this by iterating the Verifier prompt to specify the rejection criteria precisely — mathematically wrong, multiple valid answers, or unfair difficulty band — and by running the comparison test set to confirm the Verifier was rejecting bad questions while accepting good ones. The deeper challenge was distinguishing strict from fair — the Verifier should be strict on errors but fair on creative wrong-options. Iterating to that balance took several rounds.

Firestore security rules debugging. The admin claim helper functions had a subtle bug — the document placeholder in a security rule function body is treated as literal text, not a variable binding, so admin writes always evaluated false. I addressed this in the short term by using inline rules rather than helper functions for admin checks, and documented the limitation as a known item for production hardening. The lesson is that security-rule helper functions have non-intuitive semantics; defaulting to inline rules until the helper-function syntax is understood deeply is the safer pattern in a hackathon.

Cloud Messaging topic-name sanitisation. Topic names disallow spaces and certain other characters. The first push notification attempt failed silently. I addressed it by writing a regex sanitiser that replaces disallowed characters with hyphens and sharing a one-line note on the team channel. The lesson is that silent failures are dangerous in a hackathon — the bug had been live for two days before it was noticed; observability must be built in, not added later.

Billing-cap end-to-end wiring. IAM permissions, Pub/Sub topic linking, Cloud Function deployment, and the Cloud Billing API call were each a separate failure mode. I addressed this by debugging each piece in turn, isolated, before connecting them. I tested the chain by setting a deliberately-low threshold and confirming billing actually got disabled. The lesson is that cloud-native operational systems are sequences of small integrations, each of which can fail; isolation testing is the only reliable way to debug them.

Mastery-score formula tuning. The first weighting (50-50) felt too volatile — a single wrong answer dropped the mastery score sharply, which produced jumpy Study Planner outputs. I tested multiple values (60-40, 70-30, 80-20) on simulated answer sequences. The 70-30 split felt most natural — recent answers matter but no single answer dominates. The lesson is that empirical hyperparameter tuning matters even at small scale; defaulting to 50-50 and shipping it would have produced a worse user experience.

Growth As A Collaborative Team Member

Three things changed in me. First, I learned that evidence beats argument in architectural debates — the test-set comparison settled the Verifier-agent question in a way no amount of citation could have. Second, I learned that infrastructure work is leadership — the team's confidence depends on the security rules being right and the billing cap being real, even when no one talks about either. Third, I improved at interface thinking — treating shared Firestore documents as interfaces with the discipline of negotiating shape before either side ships, rather than treating them as convenient storage.

If I were to do this hackathon again, I would invest in observability earlier (catching silent failures like the Cloud Messaging sanitisation issue before they ran for two days), learn the security-rule helper-function syntax properly rather than working around it, and design the notification topic granularity for opt-out flexibility from the start.


THEORETICAL FRAMEWORKS THE WRITER CAN REFERENCE

For academic credibility, anchor reflections in established frameworks.

Gibbs' reflective cycle (Gibbs, 1988): description, feelings, evaluation, analysis, conclusion, action plan. Best fit for Task 2's deeper self-reflection on the Verifier-agent debate.

Kolb's experiential learning cycle (Kolb, 1984): concrete experience (single-agent design with high defect rate), reflective observation (40 percent of questions have errors), abstract conceptualisation (generator-critic separates creativity from criticism), active experimentation (two-agent design with 5 percent defect rate).

Belbin's team roles (Belbin, 1981). Giridher's role is closest to Monitor Evaluator (the Verifier mindset, looking for what could be wrong) and Implementer (the operational discipline of wiring billing caps and security rules end-to-end).

Schön's reflective practitioner (Schön, 1983): both reflection-in-action (the Cloud Messaging topic-name sanitisation noticed mid-debug) and reflection-on-action (the post-hoc analysis of the security-rule helper-function bug).

Tuckman's stages (Tuckman, 1965): the team's transition through storming (debate over Verifier-agent necessity) into norming (the agreed pattern across all features) into performing.

FATE — Fairness, Accountability, Transparency, Explainability (a common AI ethics framework). The Verifier agent is, in effect, an accountability check on another AI; the report can position it as a small instance of broader AI-governance practice.

Privacy by design or privacy by architecture (Cavoukian, 1995): the per-user-path security rule pattern as a working example of the principle.


SUGGESTED DIAGRAMS FOR GIRIDHER'S REPORT

Suggest a generator-critic loop diagram showing Trap Designer creates, Verifier reviews, accept or reject with reason; defect-rate metrics overlaid.

Suggest a mastery score update diagram showing a wrong answer triggering the exponential-moving-average update at the user's mastery-score path, consumed by Study Planner.

Suggest a Firebase architecture layers diagram showing authentication, Firestore (29 collections in four logical groups), Cloud Storage, Cloud Messaging, and Cloud Functions.

Suggest a security-rule decision tree diagram showing request arrival, authentication check, path-user-ID match, admin claim check, and allow or deny.

Suggest a billing-cap fail-safe diagram showing Cloud Billing publishing to Pub/Sub, the stopBilling Cloud Function consuming, and if threshold crossed, calling the Cloud Billing API to disable billing.

Suggest a Cloud Messaging topic-name sanitisation figure showing input branch name (for example "CSE AIML") to the regex sanitiser to safe topic name (for example "CSE-AIML").


GLOSSARY

Agentic AI: a class of AI system in which multiple agents collaborate, delegate, and decide.

Cloud Functions: Firebase serverless functions triggered by events; the platform uses one to enforce a monthly billing cap.

CrewAI: the Python framework used for the platform's multi-agent crews.

Custom Claims (Firebase Auth): a feature that attaches admin or role flags to a user's authentication token; the platform currently uses a Firestore-document equivalent and is migrating to Custom Claims as a hardening item.

EMA (exponential moving average): a weighted average where recent values count more than older ones; used in mastery scores.

FATE: Fairness, Accountability, Transparency, Explainability — a common AI-ethics framework.

FCM (Firebase Cloud Messaging): Firebase's push-notification service; topic-based subscriptions allow broadcasts to logical groups.

Firestore: Firebase's document database; in this project also the vector store and the per-user state store.

Firestore Security Rules: server-side rules that decide who can read or write each document; enforced by Firestore itself, not by the app.

Generator-critic pattern: a multi-agent design pattern where one agent creates output and a second agent reviews and rejects bad output.

IAM (Identity and Access Management): the cloud platform's permissions system; the stopBilling Cloud Function needs IAM permissions to call the Cloud Billing API.

Learning contract: a written set of personal goals identified at the start of a learning experience.

Mastery score: a per-topic measure of how well a student has answered questions on that topic.

Pub/Sub: Google Cloud's messaging system; the Cloud Billing publishes to a Pub/Sub topic that the stopBilling function consumes.

stopBilling: the Cloud Function that auto-disables Firebase billing when monthly spend crosses the configured threshold.

Trap question: a question where most students pick the wrong answer because of a common misconception.

Verifier agent: the critic agent in Adversarial Examiner that rejects mathematically wrong, ambiguous, or unfair questions before they reach the student.


QUICK REFERENCE SHEET

Module code: LD7237. Module title: Contemporary Computing and Digital Technologies. Word limit: 3,000 words excluding ToC, page numbers, and captions. Submission deadline: 21 May 2026 at 16:00. Hackathon theme: AI Agents Unleashed — Building the Future of Automation. Team submission: Academic Ally. Giridher's responsibilities: Adversarial Examiner (AI feature) and Firebase backend layer (foundation). Adversarial Examiner agents: Topic Researcher, Trap Designer, Verifier, Output Formatter. Adversarial Examiner pattern: generator-critic (Trap Designer creates, Verifier reviews and rejects). Mastery-score formula: new equals 0.7 times old plus 0.3 times this answer. Belbin roles most fitting: Monitor Evaluator and Implementer. Task 1 weighting: about 2,000 words, 70 marks. Task 2 weighting: about 1,000 words, 30 marks. Reflective frameworks: Gibbs, Kolb, Schön, Tuckman, Belbin, FATE, Privacy by Design.
