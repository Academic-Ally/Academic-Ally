*Academic Ally — Project Overview*

A plain-English explainer for presentations. No coding background needed.


*What is Academic Ally?*

Academic Ally is a mobile app that helps engineering students in Hyderabad study smarter. It started as a place where students could download notes, question papers, and syllabi for their subjects — and it went live on the Google Play Store. Now we are relaunching it as an AI-powered learning platform with features that go far beyond just storing files.

Think of it as the one app an engineering student opens every day — to grab study material, ask doubts, plan for exams, chat with classmates, or find internships.


*Who is it for?*

B.E and B.Tech students at Osmania University (OU) and JNTUH (Jawaharlal Nehru Technological University Hyderabad). All branches — CSE, IT, ECE, EEE, MECH, CIVIL, CSE AIML, CSE IOT, and so on. All 8 semesters.

The app is personalised. When a student signs up, they pick their university, course, branch, and semester, and the app shows them only content that matches.


*The problem we solve*

Engineering students in India struggle with three things.

One, scattered study resources. Notes live on random WhatsApp groups, Drive links that expire, and senior-hand-me-down PDFs.

Two, no intelligent study help. Textbooks are thick, the syllabus is vast, and there's no easy way to know what to study first for an exam.

Three, weak connections between students. Finding classmates who have notes for a tough subject, or finding second-hand textbooks cheap, is painful.

Academic Ally fixes all three in one app.


*Features — Part 1: Core Platform*

These features make Academic Ally a proper engineering-student companion.

*1. Onboarding*
Shows 4 welcome slides when students open the app for the first time. Walks them through what Academic Ally does in about 20 seconds.

*2. Login and Signup*
Students sign up with email and password, pick their university, course, branch, and semester. The app remembers them and shows curriculum-matched content from then on.

*3. Home Screen*
The landing page. Shows quick shortcuts, AI Tools, Community features, and Recommended subjects based on the student's profile.

*4. Search and Filters*
Students can search for any subject or resource by name. Filters let them narrow by branch and semester.

*5. Resources*
The heart of the app. Students tap a subject, pick a resource type (Notes, Question Papers, Syllabus, or Other), and see a list of available PDFs.

*6. PDF Viewer*
Tapping any resource opens a full-screen PDF viewer. Students can download, bookmark, share, rate, or ask questions about the PDF using AllyBot.

*7. Bookmarks*
Students save PDFs they want to come back to later. Bookmarks are synced to the cloud, so the list follows them across devices.

*8. Recents*
Shows the last few PDFs the student opened, with a "time ago" label like "2 hours ago". One tap to jump back to anything they were reading.

*9. Downloads*
Anything downloaded is available offline. Useful for students on patchy campus WiFi or long train journeys.

*10. Upload*
Students can contribute their own notes. Uploads go into a review queue first, then get published to the public library after approval.

*11. SeekHub*
A "help wanted" board for resources. If a student can't find notes for a tricky subject, they post a request. Other students can respond with the material.

*12. AllyBot (Chat with PDFs)*
Students tap a PDF and ask questions about it in plain English. The AI reads the PDF and answers — like having a tutor who has already read the book.

*13. Profile*
Shows and edits the student's name, email, college, profile picture, and curriculum details. Also has logout and delete-account options.

*14. Report Abuse*
If a student sees inappropriate content anywhere, they can report it in two taps. Reports go to the Academic Ally team for review.

*15. Push Notifications*
When admins add new resources relevant to a student's curriculum, the student gets a phone notification — for example, "New Compiler Design notes uploaded for CSE Sem 3". Students only get notified about their own branch and semester.


*Features — Part 2: AI Tools (the wedge)*

These features make Academic Ally stand out from every other notes-sharing app. Students open the app for these features even on days when they don't need to download anything.

*16. Knowledge Map*
Shows every topic in a subject as a card with a "mastery bar" that tracks how well the student understands it. Students practice with AI-generated questions, and the mastery bar fills up over time. Makes studying measurable.

*17. Study Planner*
Student picks an exam date and subjects. The AI generates a day-by-day study schedule — what topic to cover, how long to spend, which chapters matter most. Students check off tasks as they complete them. Turns "I have no idea where to start" into a clear path.

*18. Gen UI*
A futuristic feature. Students type any question, and instead of a list of links, the AI decides how to show the answer — as a card, a list, buttons, whatever fits best. The interface itself is generated by AI, uniquely for each question.

*19. PYQ Analyzer*
OU and JNTUH exams repeat questions from past papers — every student knows this. The PYQ Analyzer scans past papers for a subject and predicts which topics are most likely to come up and which specific questions are the highest-probability bets. Our strongest feature for the exam-prep culture in Hyderabad.

*20. Snap a Doubt*
Student takes a photo of any problem from a textbook or from their own handwriting. The AI reads the problem and returns a step-by-step solution. Like having a 24 by 7 tutor who can read your notebook.

*21. Project Copilot*
For final-year students doing major and minor projects. The AI helps at every stage — coming up with ideas, reviewing research papers, structuring the project, and even generating the report template. No Indian edtech company has built this cleanly yet.


*Features — Part 3: Community Features*

These turn Academic Ally from a "study tool" into a "campus hub" — giving students reasons to open the app even when they are not studying.

*22. Jobs and Internships*
Students see job and internship postings on the platform, filtered by type. Tapping a job opens the recruiter's application page. Students can also post jobs themselves.

*23. Communities and Channels*
Topic-based chat rooms. Students join channels like "DBMS Discussion", "Memes and Side-talk", or "Sem 3 CSE Notes Hunt", and chat with classmates in real time. Keeps students in the app every day, not just during exams.

*24. Marketplace*
Students buy and sell used textbooks, calculators, lab manuals, and other campus items. Listings include photos and a price. Tapping "Contact Seller" opens WhatsApp with a pre-filled intro message. Think OLX, but just for engineering campuses.


*Tech Stack*

The app is built with Flutter, a framework by Google that lets us build one app that runs on both Android and iPhone.

The backend is powered by Firebase, also by Google. Firebase handles student login, the database that stores everything, file storage for PDFs and photos, and push notifications.

For AI, we are currently running on realistic mock data that demos exactly like the real thing. The plan is to switch to Google Gemini for the final release — the app is built so this switch is a small change on our end.

The app is live on the Google Play Store under the earlier version, and we are preparing the updated version for release.


*Where things stand right now*

All 24 features above have working screens. Students can sign up, browse resources, chat in communities, list items in the marketplace, post jobs, and explore every AI tool. Push notifications, deep links, profile edits, bookmarks — all working.

What is planned for the final phase is swapping the mock AI for real Google Gemini, tightening security for full public launch, and Play Store submission for the updated version.


*Quick facts for presentations*

What is it — An AI-powered learning app for engineering students in Hyderabad.

Who uses it — B.E and B.Tech students at Osmania University and JNTUH.

What platforms — Android (live on Play Store) and iPhone (built, pending release).

How many features — 24 complete features across 3 categories: Core platform, AI tools, and Community.

What is our edge — The 6 AI features, especially the PYQ Analyzer and Project Copilot, which no other Indian edtech app has built.

What is the tech — Flutter for the app, Firebase for the backend, Google Gemini (planned) for AI.

