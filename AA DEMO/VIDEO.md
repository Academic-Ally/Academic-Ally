*Academic Ally — Demo Video Script*

*Flow*

Recorded screen appears → intro → open app on Android emulator → login → quick UI tour → 4 AI features (Study Planner, PYQ Analyzer, Adversarial Examiner, Snap a Doubt) → open a resource → AllyBot demo → PDF viewer + Quick Access tiles → Coming Soon features → outro.

Voiceover is recorded after the screen capture and layered on top.

---

*Voiceover Script*

*1. Intro*

On screen: opening title or first frame of the screen recording.

Hi, this is Academic Ally. It is an AI-powered study app built for B.Tech students at Osmania University and JNTUH in Hyderabad.

It solves two problems. First, students lose days hunting for notes scattered across WhatsApp groups, seniors' Drive links, and blurry photocopies. Second, general AI tools like ChatGPT do not know our university syllabus, so the answers are generic. Academic Ally fixes both. One organised library, plus AI agents that understand the actual syllabus and cite real PDF pages.

---

*2. Login*

On screen: the Android emulator opens, the app launches, the login screen appears, email and password are filled in, login is tapped.

I am opening the app on an Android emulator. This is the login screen. I enter my email and password and sign in.

Authentication runs on Firebase Auth. Every user gets a Firebase ID token, and the Python backend verifies that token on every request. No token, no access. The same flow supports Google sign-in.

---

*3. Quick UI tour*

On screen: home screen appears, scroll slowly through the sections.

This is the home screen. It has three sections.

At the top is Quick Access — shortcuts to AllyBot, SeekHub, Recents, and Downloads.

Below that is the AI Tools section with the four AI features.

At the bottom is the Coming Soon section with community features I will mention at the end.

---

*4. Study Planner*

First feature — Study Planner. Most students sit down before exams and have no idea what to study first. The Study Planner takes your exam date and your subjects, and builds a complete day-by-day schedule telling you exactly what to study, when, and for how long. It is personalised — it pays attention to which topics carry more weight in the exam and which topics you have already struggled with.

On screen: tap Study Planner tile, pick exam date and subjects, hit Generate, plan loads.

I pick my exam date and subjects, then tap Generate.

The request goes to a FastAPI Python backend running locally. The backend spins up a CrewAI multi-agent crew with four agents working together. The Topic Importance Analyzer weighs each topic. The Mastery Reader pulls my past mistakes from Firestore. The Effort Estimator decides how long each task should take. The Schedule Planner fits everything into the days I have left.

In about 60 to 90 seconds I get a day-by-day plan — subject, topic, duration, and the reason behind each task. The plan is saved to Firestore under my user ID and regenerates as my mastery improves.

---

*5. PYQ Analyzer*

Next, the flagship — PYQ Analyzer. Every exam season, students try to guess which questions are likely to come, usually by flipping through the last few years of question papers manually. The PYQ Analyzer does this systematically. It studies the syllabus, the past five years of question papers, and current academic trends, and gives you a ranked list of the most likely questions for the upcoming exam. So instead of preparing everything blindly, you know exactly what to focus on.

On screen: tap PYQ Analyzer tile, pick subject, hit Analyze, live agent progress UI appears, results load.

I pick a subject and hit Analyze.

Watch the screen. Five agents tick off live as they work.

The Syllabus Researcher maps the topics. The Web Researcher pulls outside context using the Tavily web search API. The Pattern Analyst studies the last five years of question papers from our Firestore vector database. The Question Predictor ranks which questions are most likely to be repeated. The Output Formatter delivers the final list.

CrewAI runs this in hierarchical mode — a Manager agent decides who runs next. It is not a fixed pipeline. Each agent's output becomes context for the next one.

Live progress streams from the backend to the app through Firestore in real time. Every predicted question cites the actual paper it came from. No hallucination — just real PYQs.

---

*6. Adversarial Examiner*

Third feature — Adversarial Examiner. The idea here is simple. Examiners do not ask straightforward questions. They ask twisted ones — phrased to confuse, full of edge cases, designed to expose whether you actually understand the topic or just memorised it. The Adversarial Examiner generates these trap questions for you on purpose, so you can fail safely at home before failing in the actual exam. Every question comes with the mistake students usually make and the correct way to think about it.

On screen: tap Adversarial Examiner tile, pick subject and topic focus, generate, questions appear with trap labels.

I generate trap questions designed to catch the spots where I am weak.

Four agents work together. The Topic Selector picks what to test. The Trap Pattern Miner finds common tricks from past papers — phrases like "differentiate", "state the conditions", or "what happens if". The Question Generator builds the questions. The Verifier rejects any question with ambiguity, math errors, or unfair traps before it reaches me.

Each question comes with the common mistake students make and the correct approach. Getting it wrong here actually teaches me, and my mastery score updates so the Study Planner adapts.

---

*7. Snap a Doubt*

Fourth feature — Snap a Doubt. Every student has had the moment of being stuck on a single problem at midnight, with no one to ask. Snap a Doubt fixes that. Take a photo of any problem you cannot solve — handwritten in your notebook, printed in a textbook, anything — and the app gives you a step-by-step solution grounded in your own course material, with clickable links back to the exact PDF page each step came from.

On screen: tap Snap a Doubt tile, pick or capture a photo of a problem, upload, solution loads with citation chips, tap a chip to open the PDF at the cited page.

I take a photo of any problem — handwritten, printed, from a textbook.

The image goes to Firebase Storage. The backend pulls it down and sends it to Gemini Vision, which reads the question directly from the image. No separate OCR step.

Then a four-agent crew takes over. The Notes Retriever pulls relevant pages from my own PDFs using vector search. The Step Solver works through the maths. The Validator checks every step. The Formatter writes the final solution.

The chips below each step are clickable. Tap one and the source PDF opens at the exact page that the answer came from.

---

*8. AllyBot*

Fifth feature — AllyBot. Think of AllyBot as a study buddy that has read every page of the PDF you are currently looking at. Open any resource in the app, ask AllyBot anything about that document — a definition, a summary, a clarification, an example — and it answers with citations to the exact page numbers it pulled the answer from. So you can verify, every time, that the answer came from your actual notes and not from somewhere on the open internet.

On screen: open a resource (a PDF), tap the AllyBot button inside the PDF viewer, type a question, response loads with page citations.

Now I open a resource. Here is a PDF from my notes. Inside the PDF I tap AllyBot.

I can ask anything about this document. My question is converted into a 768-dimension embedding using Gemini's embedding model. A vector search runs over Firestore Vector Search, scoped to just this one PDF. A single Gemini call generates the reply.

The whole round trip takes 3 to 5 seconds. The reply comes back with inline page citations. No multi-agent crew here, because chat needs to be fast — agents would be too slow.

---

*9. PDF Viewer and Quick Access Tiles*

On screen: scroll through the PDF, show bookmark, share, rate, then go back to home and point to each Quick Access tile.

The PDF viewer is built with flutter_pdfview. The PDF itself is stored in Firebase Storage and streamed to the app through a signed download URL. From here I can bookmark the resource, rate it, share it, or report it.

Back on the home screen, the Quick Access tiles. AllyBot opens a general chat. SeekHub is a board where students can request resources we do not have yet. Recents shows what I last viewed. Downloads keeps PDFs available offline.

---

*10. Coming Soon*

On screen: scroll to the Coming Soon section, point to each card.

Three more features are built into the codebase but hidden from the home screen for this demo.

Communities — topic-based chat channels for students. Jobs and Internships — a campus job board. Marketplace — student-to-student buying and selling. All three are wired in code, with Firestore security rules and indexes already deployed.

---

*11. Outro*

On screen: closing card with team names and the Academic Ally logo.

That is Academic Ally. Multi-agent AI grounded in real PDFs, built for OU and JNTUH students by a team of five. The frontend is Flutter, the backend is FastAPI with CrewAI, the AI model is Google Gemini, and everything is backed by Firebase. Thank you.

---

*Before You Record*

- Start the backend: `cd backend && ./run.sh`. Confirm `/health` returns OK.
- Run the Android emulator at 1080p with the status bar in demo mode (clean clock, full battery, full signal).
- Sign in with a demo account that already has a Study Plan and a few Bookmarks, so the screens are not empty.
- Pre-pick a subject that has indexed PDFs (any IT / Sem 2 subject works).
- Pre-warm AllyBot once before recording so the first message latency is acceptable.
- Disable host machine notifications so nothing pops up on screen.

*While Recording*

- Move the cursor slowly and deliberately.
- Pause for 1 to 2 seconds after each tap before moving on.
- If an AI run fails on camera, cut, retry off-camera, and re-record that section.

*Post*

- Record voiceover separately, then layer it over the screen capture.
- Light instrumental music bed at around -22 dB. Voiceover at -6 to -3 dB above the music.
- Add lower-third text labels in brand purple (#6360FF) when each agent name is mentioned.
- Export 1080p H.264 MP4.
