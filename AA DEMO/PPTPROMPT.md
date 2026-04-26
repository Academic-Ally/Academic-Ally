# Prompt for Claude.ai — Generate Academic Ally PPTX

Paste everything below into Claude.ai. Make sure Claude has its file-creation / PPTX skill enabled. The output should be a downloadable `.pptx` file.

If Claude.ai responds with HTML or just text instead of a `.pptx`, reply: "Please use your PPTX file creation skill and give me a downloadable .pptx file."

You can also attach the 5 member scripts from the `AA DEMO` folder as supporting context if Claude.ai's input window allows.

---

## ----- COPY EVERYTHING BELOW THIS LINE INTO CLAUDE.AI -----

I need you to create a complete, polished PowerPoint deck (a real downloadable .pptx file — not HTML, not markdown) for a B.Tech major project demo at an engineering university in Hyderabad, India. Use your PPTX file-creation skill so I can download the file.

The audience is a sharp technical professor and an evaluation panel. The deck must look modern, clean, and visually polished — not corporate, not cluttered, not generic Google Slides feel.

The project is called **Academic Ally**. Below is everything you need: the project context, the visual style guide, and a slide-by-slide specification. Stick strictly to the content I give you. Do not invent technical details that are not in this brief.


# 1. PROJECT CONTEXT (use this in slides as needed)

**What Academic Ally Is**

Academic Ally is a mobile app for B.E and B.Tech students at _Osmania University (OU)_ and _Jawaharlal Nehru Technological University Hyderabad (JNTUH)_. It is two things in one product:

1. An **AI-powered education platform** with 4 multi-agent AI features. Each feature runs 4 to 5 specialized AI agents working as a team in the background.
2. The **largest organized library** of Notes, Previous Year Question Papers (PYQs), Question Banks, and Syllabi for these two universities — built over 3 years and exclusive to Academic Ally.

**Why It Matters**

Engineering students in Hyderabad waste days hunting for material in WhatsApp groups, senior's Drive links, and blurry photocopies. Even when they have everything, no one tells them what is important, where they are weak, or what is likely to come in the exam. Generic AI tools like ChatGPT do not know JNTUH or OU syllabi.

Academic Ally solves both halves — the resource problem and the personalization problem — using AI agents that work on real, exclusive PDF data.

**The AI Approach (this is what the professor wants to see)**

Most apps just call ChatGPT once and show the result. Academic Ally uses **multi-agent agentic AI**:

- 4 to 5 specialized AI agents per feature, each with a role, goal, and tools.
- A manager agent coordinates them in **hierarchical mode** (decides who runs next).
- Each agent's output becomes context for the next agent.
- Agents are **grounded in real PDFs** through **RAG (Retrieval-Augmented Generation)** — they cite actual page numbers, not hallucinations.
- Our PDF library is **exclusive to Academic Ally** — this collection is not available anywhere else online.

**Tech Stack**

- App: Flutter (Frontend framework), Riverpod (state management)
- AI Backend: FastAPI (Python web server), CrewAI (manages AI agent teams), Google Gemini API (the AI model), Tavily (web search API), Firestore Vector Search (finds relevant PDF chunks)
- Cloud: Firebase — Authentication, Firestore database, Storage, Cloud Messaging, Cloud Functions

**The Team (5 members)**

- Mohd Mustafa Akram (Project Lead) — Architecture, RAG infrastructure, CrewAI multi-agent setup, Flutter migration
- Tabassum — PYQ Analyzer (5-agent flagship feature)
- Farhan — Snap a Doubt + AllyBot
- Kaviya — Study Planner + Resources / PDF system
- Giridher — Adversarial Examiner + Firebase backend layer


# 2. VISUAL STYLE GUIDE (follow exactly)

**Brand Colors — use these exclusively. No other colors.**

- Primary Purple: `#6360FF` — main accent, headings, primary cards, cover slide background
- Tertiary Coral: `#FF8181` — secondary accents, highlights, callouts
- Light Lavender: `#F1F1FA` — light backgrounds, soft cards
- Dark Text: `#161719` — body text on light backgrounds
- White: `#FFFFFF` — backgrounds and text on color blocks

**Typography**

- Use **Poppins** font family throughout. If unavailable, fall back to Open Sans or Montserrat — never Times or generic Arial.
- Headings: bold (700 weight), Primary Purple `#6360FF` on light backgrounds, White on color backgrounds.
- Body: regular (400 weight), Dark Text `#161719` or White depending on background.
- Maintain clear hierarchy: slide title (28-32pt) > section heading (20-22pt) > body (14-16pt).

**Design Principles**

- **Modern flat design.** No gradients except subtle ones on cover slide. No drop shadows that look 2010-era. No clip-art. No stock photo backgrounds.
- **Whitespace is your friend.** Each slide should breathe.
- **Rounded corners** on all cards and shapes (12-16px radius).
- **Use icons** for sections and bullet markers — pick a single consistent icon style (Material or Feather style preferred). Do not mix icon styles.
- **Diagrams** built with shapes and arrows, in brand colors. No external image dependencies.
- Maximum 6 bullet points per slide. Prefer 3-4 short ones.

**Slide Layout Patterns to Use**

- **Cover slide**: full Primary Purple background, large white title, subtle pattern texture allowed.
- **Section divider**: full-color background (alternate Purple and Coral), large bold heading.
- **Content slide**: white background, color accent stripe at top (4-6px Primary Purple), title at top, content below.
- **Two-column layout**: white background, two equal cards with rounded corners, one Light Lavender filled and one White with Purple border.
- **Diagram slide**: white background, shapes connected by arrows in brand colors.


# 3. SPEAKER NOTES (required on every slide)

Add speaker notes to every single slide. The notes are for team members reading their part. Keep notes 2-4 short sentences. Use the speaker-note text I provide for each slide.


# 4. SLIDE-BY-SLIDE SPECIFICATION (22 slides total)

Generate exactly these 22 slides in this order.


**Slide 1 — Cover**
- Layout: full Primary Purple `#6360FF` background
- Large title (white, bold, centered): "Academic Ally"
- Subtitle (white, lighter weight, centered below title): "An AI-Powered Education Platform for OU and JNTUH Students"
- At the bottom, in smaller white text: team names — "Mohd Mustafa Akram (Project Lead) · Tabassum · Farhan · Kaviya · Giridher"
- Optional: subtle dot pattern or geometric shapes in slightly lighter purple
- Speaker note: "Welcome the panel. Briefly introduce the team. Explain that this is a major project submission combining a resource platform with AI-powered agentic features."


**Slide 2 — The Problem**
- Layout: white background, top accent stripe in Primary Purple
- Title: "The Problem"
- Body — 4 bullet points with simple icons:
  - Engineering students waste days hunting for study material before exams
  - Resources scattered across WhatsApp groups, senior's Drive links, and blurry photocopies
  - No one tells students what is important, where they are weak, or what is likely to come in the exam
  - Generic AI tools like ChatGPT do not know JNTUH or OU syllabi
- Right side: a small illustration or icon-cluster showing chaos (WhatsApp, broken link, PDF with question marks)
- Speaker note: "Set up the pain. Every Hyderabad engineering student has lived this. Make it relatable."


**Slide 3 — Our Solution: Academic Ally**
- Layout: white background, two large rounded cards side by side
- Title: "Our Solution"
- Card 1 (left, Primary Purple background, white text): heading "AI-Powered Education Platform" + body "Teams of AI agents predict exam questions, build study plans, generate trap questions, and solve doubt photos. Answers based on real PDFs — not generic ChatGPT."
- Card 2 (right, Light Lavender background, dark text, Primary Purple heading): heading "Largest Organized Library" + body "Notes, PYQs, Question Banks, Syllabi for OU and JNTUH. Searchable, downloadable, organized."
- Speaker note: "We are two things in one product. Lead with AI — that is the headline."


**Slide 4 — What Makes Us Different**
- Layout: white background, three rounded cards in a row
- Title: "What Makes Us Different"
- Card 1 (Primary Purple top border, white bg): heading "Multi-Agent AI" + body "4 to 5 specialized AI agents per feature, working as a team. Not one ChatGPT call."
- Card 2 (Coral top border, white bg): heading "Grounded in Real PDFs" + body "RAG (Retrieval-Augmented Generation) — answers cite actual page numbers from real material."
- Card 3 (Primary Purple top border, white bg): heading "Exclusive Data" + body "Our PDF library is private to Academic Ally. Built over 3 years. Not available anywhere else online."
- Speaker note: "Three pillars of differentiation. Emphasize data exclusivity — this is our biggest moat."


**Slide 5 — Tech Stack**
- Layout: white background, three vertical color blocks
- Title: "Tech Stack"
- Block 1 (Primary Purple background, white text): heading "App" + bullets "Flutter (Frontend framework)" and "Riverpod (State management)"
- Block 2 (Coral background, white text): heading "AI Backend" + bullets "FastAPI (Python web server)", "CrewAI (manages AI agent teams)", "Google Gemini API (the AI model)", "Tavily (web search API)", "Firestore Vector Search (finds relevant PDF chunks)"
- Block 3 (Primary Purple background, white text): heading "Cloud" + bullets "Firebase Authentication", "Firestore Database", "Firebase Storage", "Firebase Cloud Messaging", "Firebase Cloud Functions"
- Speaker note: "Brief overview of the tech stack. We will go deeper on the AI parts in the next slides."


**Slide 6 — System Architecture**
- Layout: white background, full-slide diagram
- Title: "System Architecture"
- Diagram: top-down flow with rounded boxes connected by arrows
  - Top: "Flutter App" (Primary Purple)
  - Arrow down labeled "HTTPS request + Firebase ID Token"
  - Middle: "FastAPI Backend" (Coral)
  - From FastAPI, three arrows branching out to:
    - "CrewAI Multi-Agent Crew" (Primary Purple)
    - "Tavily Web Search" (Light Lavender)
    - "Gemini API" (Light Lavender)
  - From CrewAI: arrow to "RAG Search Tool" → "Firestore Vector Search (RagChunks)"
  - Side arrow: FastAPI → "Firestore (AnalysisRuns)" with label "writes live progress"
  - Side arrow back from Firestore (AnalysisRuns) → Flutter App labeled "real-time listener"
- Speaker note: "End-to-end flow. The student taps a button. The request goes through the backend. Agents do the work. Results come back. The live progress is what makes the multi-agent visible to the user."


**Slide 7 — RAG: Grounding the AI in Real PDFs**
- Layout: white background, two-stage diagram
- Title: "RAG: Grounding the AI in Real PDFs"
- Top half — "Ingestion": flow from left to right
  - "PDF" → "Split into 800-char chunks (100-char overlap)" → "Convert each chunk to 768-number embedding using gemini-embedding-001" → "Store in Firestore Vector Search with citations (PDF name + page)"
- Bottom half — "Retrieval": flow from left to right
  - "Agent's Query" → "Convert to 768-number embedding" → "Firestore Vector Search returns top-5 closest chunks (cosine similarity)" → "Chunks injected into agent's prompt with citations"
- Use Coral arrows on white background, Primary Purple boxes
- Speaker note: "RAG is the most important technical concept. Walk slowly through both stages. Emphasize: agents see real PDF chunks, not made-up text."


**Slide 8 — Multi-Agent Pattern (How CrewAI Works)**
- Layout: white background, hierarchy diagram
- Title: "How CrewAI Orchestrates AI Agents"
- Diagram: a "Manager Agent" box on top (Coral) with arrows down to 4 "Worker Agent" boxes below (Primary Purple). Horizontal arrows between worker boxes labeled "context passes to next agent".
- Caption below the diagram: "Each agent has a Role, a Goal, and Tools. Manager decides who runs next (hierarchical mode). Each agent's output becomes context for the next."
- Speaker note: "This is the pattern all 4 AI features share. The manager decides delegation order. Workers do specialized work. Context flows from one to the next."


**Slide 9 — Section Divider**
- Layout: full Primary Purple background
- Large white centered text: "The 4 AI Features"
- Subtitle: "Each one a multi-agent system"
- Speaker note: "Pause here. We are about to walk through each AI feature."


**Slide 10 — AI Feature 1: PYQ Analyzer**
- Layout: white background, top accent stripe in Coral
- Title: "PYQ Analyzer — Predict Exam Questions"
- Subtitle in smaller text: "Owned by Tabassum"
- Pipeline diagram (5 boxes left to right with arrows): "Syllabus Researcher" → "Web Researcher" → "Pattern Analyst" → "Question Predictor" → "Output Formatter"
- Below the pipeline, two small info boxes:
  - "Output: Topic Weights (e.g. ER Modeling 18%, Normalization 22%) + 8 to 12 predicted exam questions"
  - "Time: 60 to 120 seconds | Tools: RAG Search + Tavily Web Search"
- Speaker note: "Flagship feature. 5 specialized agents. The most impressive demo of multi-agent AI."


**Slide 11 — AI Feature 2: Study Planner**
- Layout: white background, top accent stripe in Primary Purple
- Title: "Study Planner — Personalized Day-by-Day Plan"
- Subtitle: "Owned by Kaviya"
- Pipeline diagram (4 boxes): "Subject Researcher" → "Strategy Planner" → "Schedule Builder" → "Output Formatter"
- Below: two info boxes
  - "Output: Day-by-day plan with subject, topic, minutes, and rationale per task"
  - "Personalized: Pulls student's mastery snapshot from past mistakes (e.g. trap questions they got wrong)"
- "Time: 60 to 90 seconds"
- Speaker note: "Personalized. Uses past Adversarial Examiner mistakes to give weak topics extra time. Pre-computed dates prevent calendar bugs."


**Slide 12 — AI Feature 3: Adversarial Examiner**
- Layout: white background, top accent stripe in Coral
- Title: "Adversarial Examiner — Trap Questions"
- Subtitle: "Owned by Giridher"
- Pipeline diagram (4 boxes): "Topic Researcher" → "Trap Designer" → "Verifier" → "Output Formatter"
- Highlighted callout: "Generator-Critic Pattern — Trap Designer creates, Verifier checks for math errors and ambiguity"
- Bottom info box: "Each question has: 4 options, correct answer, common mistake, correct approach, topic, difficulty"
- Speaker note: "The Verifier agent is what separates this from a generic MCQ generator. Generator-critic pattern produces measurably better questions."


**Slide 13 — AI Feature 4: Snap a Doubt**
- Layout: white background, top accent stripe in Primary Purple
- Title: "Snap a Doubt — Photo to Step-by-Step Solution"
- Subtitle: "Owned by Farhan"
- Pipeline diagram: starts with "Photo" → "Gemini Vision (multimodal — reads handwriting and equations)" then 4 boxes "Topic Classifier" → "Solver" → "Citation Resolver" → "Output Formatter"
- Bottom info: "Output: Step-by-step solution with clickable PDF citations | Time: 30 to 60 seconds"
- Speaker note: "Multimodal AI. Gemini reads the image directly — no separate OCR step. Citations are clickable and open the PDF at the right page."


**Slide 14 — Bonus AI Feature: AllyBot**
- Layout: white background, top accent stripe in Coral
- Title: "AllyBot — Chat with Any PDF"
- Subtitle: "Also owned by Farhan"
- Diagram: simpler — "User Question" → "Gemini API (single call) + RAG Context (scoped to one PDF)" → "Answer with Page Citations"
- Why simpler callout: "Chat needs to be fast (2 to 5 seconds). Multi-agent would be too slow."
- Speaker note: "Simpler than the 4-agent features because chat needs speed. Replaced an old external ChatPDF + Netlify dependency."


**Slide 15 — Live Multi-Agent Progress UI**
- Layout: white background
- Title: "Live Multi-Agent Progress UI"
- Center: a mock UI showing 5 agents in a vertical list with status icons
  - Syllabus Researcher — checkmark (done)
  - Web Researcher — checkmark (done)
  - Pattern Analyst — spinner (in progress)
  - Question Predictor — empty circle (waiting)
  - Output Formatter — empty circle (waiting)
- Caption below: "Backend writes progress to Firestore. Flutter app subscribes via real-time listeners. No WebSockets needed."
- Speaker note: "This is the visual proof that multi-agent AI is actually running. Students see the team working in real time."


**Slide 16 — Firebase Backend Layer**
- Layout: white background, four equal quadrants
- Title: "Firebase Backend Layer"
- Subtitle: "Owned by Giridher"
- Quadrant 1 (top-left, Primary Purple bg, white text): "Authentication" — "Email + Google sign-in. ID tokens for backend."
- Quadrant 2 (top-right, Coral bg, white text): "Firestore Database" — "29 collections: Public Library, Per-User State, AI State, Community"
- Quadrant 3 (bottom-left, Coral bg, white text): "Storage" — "PDFs and doubt photos with auth-gated rules"
- Quadrant 4 (bottom-right, Primary Purple bg, white text): "Cloud Messaging" — "Topic-based push notifications"
- Speaker note: "Firebase is the spine. Everything user-facing depends on these 4 services."


**Slide 17 — Security and Data Privacy**
- Layout: white background, two large cards side by side
- Title: "Security and Data Privacy"
- Card 1 (Primary Purple top border): heading "Firestore Security Rules" + body "Server-side rules per user ID. A student can only read or write under their own UID. Cross-user reads rejected at Firebase level — even if app is bypassed."
- Card 2 (Coral top border): heading "Backend Authorization" + body "Every request needs a Firebase ID token. Backend extracts UID from verified token. Never trusts request body."
- Bottom callout (Light Lavender background): "Billing safety: stopBilling Cloud Function auto-disables Firebase if monthly spend exceeds ₹200."
- Speaker note: "Two layers of defense. Firestore rules are server-side, so even if the app is compromised, the database stays safe."


**Slide 18 — The Moat**
- Layout: white background, three large rounded cards in a row
- Title: "The Moat — Why This Cannot Be Easily Copied"
- Card 1 (Primary Purple bg, white text): heading "Data" + body "Largest organized OU and JNTUH collection. 3 years of curation. Exclusive to Academic Ally — not available anywhere else online."
- Card 2 (Coral bg, white text): heading "System Design" + body "4 to 5 agents per feature. RAG-grounded. With 24h cache and live progress UI."
- Card 3 (Primary Purple bg, white text): heading "Focus" + body "Tuned for two specific universities. Outputs match exactly what those professors expect."
- Speaker note: "Anyone can call Gemini. Not anyone has our data, our agent design, and our deep university focus."


**Slide 19 — Comparison Table**
- Layout: white background, table-style comparison
- Title: "Why Not Just Use ChatGPT or Khan Academy?"
- Table with 5 columns and 5 rows:
  - Header row: empty | "Academic Ally" | "ChatGPT" | "Khan Academy" | "Brainly"
  - Row 1: "Knows your university syllabus" | check (green) | cross | cross | cross
  - Row 2: "Grounded in real PYQs" | check | cross | cross | partial
  - Row 3: "Multi-agent reasoning" | check | cross | cross | cross
  - Row 4: "Cites actual page numbers" | check | cross | cross | cross
- Use Primary Purple for the Academic Ally column header
- Use simple checkmark and X icons in cells (green check, gray X)
- Speaker note: "Visual comparison. We win on every axis the technical professor cares about."


**Slide 20 — Coming Soon**
- Layout: white background, three rounded cards in a row
- Title: "Coming Soon"
- Card 1: "Communities — topic-based chat channels for students"
- Card 2: "Jobs and Internships — campus job board"
- Card 3: "Marketplace — student-to-student buying and selling"
- Caption below cards: "Built in the codebase. Hidden from the home screen for the major project demo. Database rules and indexes already deployed."
- Speaker note: "We have more than what we are showing today. These are ready, just not the focus of this demo."


**Slide 21 — Live Demo**
- Layout: full Primary Purple background
- Center: large white text "Live Demo"
- Below: "Switching to the running app"
- Speaker note: "Cue: switch to the phone or emulator. Show home screen → tap PYQ Analyzer → live progress UI → final result."


**Slide 22 — Thank You**
- Layout: full Primary Purple background
- Large white centered text: "Thank You"
- Subtitle: "Questions?"
- Smaller text at bottom: "Academic Ally — Built by Akram, Tabassum, Farhan, Kaviya, Giridher"
- Speaker note: "Open the floor for the panel's questions. Refer to your team-member-specific Q&A notes for technical follow-ups."


# 5. OUTPUT REQUIREMENTS

- A single downloadable `.pptx` file with exactly 22 slides in the order above.
- Speaker notes on every slide (use the text I provided).
- Use the brand colors (`#6360FF` purple, `#FF8181` coral, `#F1F1FA` lavender) consistently. No other colors except white, black, and standard checkmark green.
- Use Poppins font (or fall back to Open Sans / Montserrat).
- Build all diagrams with native PowerPoint shapes and arrows — do not embed external images.
- Modern flat design — no clip-art, no stock backgrounds, no 2010-era drop shadows.
- No more than 6 bullet points per content slide.

Generate the .pptx now.
