# Academic Ally — Video Pitch Script

6-minute product demo for the LD7237 group project ("AI Agents Unleashed"). Pre-recorded, screen-recorded demos with voiceover. Speakable lines, timing markers, rubric mapping.

---

## Problem & approach — 60 seconds

> Eight million B.Tech students sit university exams in India every year. They study from a corpus that is uniquely theirs — their professor's notes, their university's past papers, scanned handouts shared between batches. None of this is on the open internet.
>
> When these students turn to AI tools — ChatGPT, Gemini, Claude — the assistants confidently answer questions they have no business answering. They don't know which university the student belongs to. They've never seen a JNTUH or Osmania paper. Every response is unsourced.
>
> Our project, **Academic Ally**, takes a different approach. Instead of one general-purpose chatbot, we deploy **coordinated teams of specialist AI agents**, each grounded in the student's actual academic material through retrieval-augmented generation. Five features. Around fourteen distinct agents. One shared platform.

---

## Architecture — 45 seconds

(Layered architecture diagram on screen.)

> The platform has four layers. PDFs uploaded to **Firebase Storage**. Chunks embedded with Gemini's `gemini-embedding-001` model at 768 dimensions and stored in **Firestore Vector Search**. CrewAI **hierarchical agent crews** — manager plus specialist workers — that consume retrieved chunks through a single search tool. A **Flutter** client surfaces the live agent progress and the structured outputs.
>
> Every feature reuses the same RAG layer. New features cost a new agent crew, not new infrastructure.

---

## Demonstration 1 — PYQ Analyzer (75 seconds)

> First feature: predicting likely exam questions. The student picks a subject — here, English for Semester 2 IT.

(Screen recording of the run.)

> Five agents start working. **Syllabus Researcher** reads the official curriculum. **Web Researcher** pulls community context. **Pattern Analyst** mines the indexed past papers — these PDFs are the student's own uploads. **Question Predictor** drafts new questions in the exact style of the indexed papers. **Output Formatter** packages the result.
>
> The agents check off in real time. Roughly ninety seconds later, six questions appear. Each one carries a likelihood score and a citation. Tap the citation — the original past paper opens on the cited page.

(Show the tap → PDF jumps to page 33.)

> No hallucination. No invented sources. Every prediction traceable to a real document.

---

## Demonstration 2 — Snap-a-Doubt (90 seconds)

> Second feature: visual question answering grounded in the student's notes.

(Show the photo capture flow.)

> The student snaps a printed past-paper question. Four agents run.
>
> A **Vision Extractor**, powered by Gemini multimodal, reads the question off the image and produces structured text. A **Notes Retriever** does a vector search filtered to the student's English notes — not the entire web. A **Step Solver** writes a worked solution that cites specific note pages. A **Solution Validator** acts as a second opinion, checking each step's logic.

(Show the resulting solution panel with citation chips.)

> The output: a step-by-step answer where each citation is interactive. Tap a chip — the cited PDF opens on the cited page. The system distinguishes between content drawn from the student's notes and content drawn from general knowledge, and flags both honestly.

---

## Demonstration 3 — Adversarial Examiner (45 seconds)

(Quick screen recording.)

> Most AI tools wait for the student to ask. This one inverts that.
>
> The Adversarial Examiner is a four-agent crew that reads past papers, identifies the phrasings examiners use as traps — questions that target known student confusions — and generates new ones calibrated to expose blind spots.
>
> Each generated question is annotated with the trap type, the common student mistake it tests, and the correct approach. The system probes for weakness rather than waiting to be asked.

---

## Ethics & responsible design — 30 seconds

> Three principles built into the architecture, not added afterwards.
>
> **Source attribution** — every claim points to a specific page of a specific PDF. Students can verify any output.
>
> **Honest refusal** — when the retrieved corpus does not cover the question, the system says so explicitly rather than fabricating an answer.
>
> **Privacy** — data is scoped per user via Firebase authentication. No cross-student access. No training on student-uploaded material.

---

## Closing — 30 seconds

> Academic Ally treats AI agents the way they should be treated for education: as **specialists grounded in real material**, not generalists pretending to know everything.
>
> The contribution of this project is the platform pattern. Once the RAG layer exists, additional features become orchestration of new agent crews, not new infrastructure. Five features today. The architecture supports many more, on the same foundation.

---

## Timing budget

| Section | Duration |
|---|---|
| Problem & approach | 1:00 |
| Architecture | 0:45 |
| Demo 1 — PYQ Analyzer | 1:15 |
| Demo 2 — Snap-a-Doubt | 1:30 |
| Demo 3 — Adversarial Examiner | 0:45 |
| Ethics | 0:30 |
| Closing | 0:30 |
| **Total** | **6:15** |

Trim transitions and you fit comfortably under 6 minutes. Buffer for editing breath / b-roll cuts.

---

## Rubric coverage

| Criterion | Weight | What the script does |
|---|---|---|
| Problem Relevance & Innovation | 25% | Names the gap precisely (*"None of this is on the open internet"*). Frames the originality as a platform pattern, not a feature list. |
| Technical Design & Execution | 30% | Architecture section names concrete primitives: Gemini `gemini-embedding-001` 768-d, Firestore Vector Search, CrewAI hierarchical, FastAPI, Flutter. Three demos visibly multi-agent. |
| Presentation & Communication | 20% | Demos lead, narration supports. Strongest moment — citation tap opening the actual PDF page — slowed down deliberately. |
| Teamwork & Collaboration | 15% | Different team members can voice different demo sections; visually obvious in editing. |
| Ethical & Responsible Design | 10% | Three principles each tied to a concrete architectural decision (citations, honest refusal, per-user scoping). Not slogans. |

---

## Filming notes

- **Demo subject: English, Sem 2 IT.** Best indexed in our dataset (~25 PDFs, 4 past papers, 17 notes). Topics are accessible to non-CS judges.
- **Pre-warm caches.** Run each feature once on the demo subject before recording so live takes hit Firestore cache.
- **Capture the citation tap deliberately.** Slow on the moment the chip opens the source PDF on the cited page — this is the most distinctive moment.
- **Use one architecture diagram, not slides.** Layered diagram — PDFs → vector index → agents → app. Thirty seconds max.
- **Voice the demos in third person** ("the student picks a subject…") for academic tone, not first-person marketing speak.

---

## Pocket sentence

If asked *"what's different about your approach?"*:

> Most AI assistants are generalists trained on the public web. Ours is a coordinated team of specialists trained on the student's own academic corpus.
