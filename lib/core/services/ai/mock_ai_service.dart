import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/ai_models.dart';
import '../../constants/firestore_paths.dart';
import 'ai_service.dart';

/// Mock implementation of [AIService] used for Phase 2 development.
///
/// Responses are hand-constructed but shaped like real LLM output:
///  - latency simulated (1.5–3s) so UI loading states behave the same way
///    they will once the real impl lands
///  - results are realistic-ish (actual OU/JNTUH topics and question stems)
///    so the demo feels alive
///
/// For state that conceptually belongs to the user (study plans, doubt
/// history, mastery scores), this impl **does** persist to Firestore so the
/// UI layer reads the same source of truth it will in Phase 4. The only
/// thing being mocked is the "AI generation" step.
class MockAIService implements AIService {
  MockAIService({FirebaseFirestore? firestore, Random? random})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _rng = random ?? Random();

  final FirebaseFirestore _firestore;
  final Random _rng;

  static const _minLatency = Duration(milliseconds: 1500);
  static const _maxLatency = Duration(milliseconds: 3000);

  Future<void> _simulateLatency() {
    final spread = _maxLatency.inMilliseconds - _minLatency.inMilliseconds;
    final ms = _minLatency.inMilliseconds + _rng.nextInt(spread);
    return Future.delayed(Duration(milliseconds: ms));
  }

  // ---------------------------------------------------------------------------
  // Misconception Graph
  // ---------------------------------------------------------------------------

  @override
  Future<List<Misconception>> tagMisconceptions({
    required String subject,
    required String topic,
    required String questionText,
    required String userAnswer,
    required String correctAnswer,
  }) async {
    await _simulateLatency();
    return [
      Misconception(
        nodeId: _slug(topic),
        description:
            'Confuses "$topic" with a related but distinct concept — user '
            'answered "${_trim(userAnswer)}" where the key distinction was '
            '"${_trim(correctAnswer)}".',
        evidenceIds: const [],
        lastSeen: DateTime.now(),
        strength: 0.6,
      ),
    ];
  }

  @override
  Future<MasteryScore> updateMastery({
    required String uid,
    required String nodeId,
    required bool wasCorrect,
  }) async {
    await _simulateLatency();

    final ref =
        _firestore.doc('${FirestorePaths.user(uid)}/MasteryScores/$nodeId');
    final snap = await ref.get();
    final prev = snap.exists
        ? MasteryScore.fromFirestore(snap)
        : MasteryScore(nodeId: nodeId, score: 0.5, attempts: 0);

    // Simple EMA-ish update: correct pulls score toward 1, wrong toward 0.
    final delta = wasCorrect ? 0.1 : -0.12;
    final newScore = (prev.score + delta).clamp(0.0, 1.0);

    final updated = MasteryScore(
      nodeId: nodeId,
      score: newScore,
      attempts: prev.attempts + 1,
      lastUpdated: DateTime.now(),
    );
    await ref.set(updated.toMap());
    return updated;
  }

  // ---------------------------------------------------------------------------
  // Study Planner
  // ---------------------------------------------------------------------------

  @override
  Future<StudyPlan> generateStudyPlan({
    required String uid,
    required DateTime examDate,
    required List<String> subjects,
    required String university,
    required String course,
    required String branch,
    required String sem,
    List<String> weakTopics = const [],
    int dailyStudyMinutes = 120,
  }) async {
    await _simulateLatency();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(examDate.year, examDate.month, examDate.day);
    final dayCount = targetDay.difference(today).inDays.clamp(1, 60);

    final rotation = [
      ...subjects,
      ...weakTopics.map((t) => 'Weak: $t'),
    ];
    if (rotation.isEmpty) rotation.add('General Revision');

    final days = <StudyDay>[];
    for (var i = 0; i < dayCount; i++) {
      final date = today.add(Duration(days: i));
      final tasks = <StudyTask>[];
      final slotCount = (dailyStudyMinutes / 45).ceil().clamp(2, 4);
      for (var s = 0; s < slotCount; s++) {
        final subject = rotation[(i * slotCount + s) % rotation.length];
        tasks.add(StudyTask(
          subject: subject.startsWith('Weak: ') ? 'Revision' : subject,
          topic: subject.startsWith('Weak: ')
              ? subject.substring(6)
              : _topicFor(subject, s),
          durationMinutes: (dailyStudyMinutes / slotCount).round(),
          rationale: subject.startsWith('Weak: ')
              ? 'Flagged as weak — reinforce before exam.'
              : 'Covers a high-weight chapter for this subject.',
        ));
      }
      days.add(StudyDay(date: date, tasks: tasks));
    }

    final planRef =
        _firestore.collection('${FirestorePaths.user(uid)}/StudyPlans').doc();
    final plan = StudyPlan(
      id: planRef.id,
      examDate: examDate,
      subjects: subjects,
      days: days,
      createdAt: DateTime.now(),
    );
    await planRef.set(plan.toMap());
    return plan;
  }

  // ---------------------------------------------------------------------------
  // Adversarial Examiner
  // ---------------------------------------------------------------------------

  @override
  Future<AdversarialExam> generateAdversarialExam({
    required String university,
    required String course,
    required String branch,
    required String sem,
    required String subject,
    List<String> focusTopics = const [],
    int questionCount = 6,
  }) async {
    await _simulateLatency();
    final topics = focusTopics.isNotEmpty ? focusTopics : _topicsFor(subject);
    final qs = <AdversarialQuestion>[];
    for (var i = 0; i < questionCount; i++) {
      final topic = topics[i % topics.length];
      qs.add(AdversarialQuestion(
        topic: topic,
        question: 'Differentiate clearly between $topic and a closely related '
            'concept, explaining edge cases.',
        trapType: 'common confusion',
        commonMistake: 'Students conflate $topic with the related concept.',
        correctApproach: 'Apply the canonical definition step-by-step.',
        expectedMarks: i.isEven ? 10 : 5,
        difficulty: i % 3 == 0 ? 'very_hard' : 'hard',
      ));
    }
    return AdversarialExam(
      subject: subject,
      overallFocus: 'Mock adversarial probe across $subject core topics.',
      questions: qs,
    );
  }

  // ---------------------------------------------------------------------------
  // PYQ Analyzer
  // ---------------------------------------------------------------------------

  @override
  Future<PyqAnalysis> analyzePyq({
    required String university,
    required String course,
    required String branch,
    required String sem,
    required String subject,
    required List<String> pyqResourceIds,
  }) async {
    await _simulateLatency();

    final topics = _topicsFor(subject);
    final weights = <String, double>{};
    double remaining = 1.0;
    for (var i = 0; i < topics.length; i++) {
      final take = i == topics.length - 1
          ? remaining
          : remaining * (0.35 + _rng.nextDouble() * 0.25);
      weights[topics[i]] = double.parse(take.toStringAsFixed(2));
      remaining -= take;
    }

    final predicted = <PredictedQuestion>[];
    for (var i = 0; i < 5; i++) {
      final topic = topics[i % topics.length];
      predicted.add(PredictedQuestion(
        question: _questionStem(subject, topic, i),
        topic: topic,
        expectedMarks: [2, 5, 10, 10, 16][i],
        likelihood: 0.95 - (i * 0.12),
        sourcePaperIds: pyqResourceIds.take(2).toList(),
      ));
    }

    final analysis = PyqAnalysis(
      subject: subject,
      topicWeights: weights,
      predictedQuestions: predicted,
      sourceResourceIds: pyqResourceIds,
      lastAnalyzed: DateTime.now(),
    );

    final ref = _firestore.doc(
      'PyqAnalysis/$university/$course/$branch/$sem/$subject',
    );
    await ref.set(analysis.toMap());
    return analysis;
  }

  // ---------------------------------------------------------------------------
  // Snap-a-Doubt
  // ---------------------------------------------------------------------------

  @override
  Future<DoubtSolution> solveDoubtFromImage({
    required String uid,
    required String imagePath,
    required String subject,
    required String university,
    required String course,
    required String branch,
    required String sem,
  }) async {
    await _simulateLatency();

    final ref = _firestore
        .collection('${FirestorePaths.user(uid)}/DoubtHistory')
        .doc();

    final solution = DoubtSolution(
      id: ref.id,
      imageUrl: imagePath,
      extractedQuestion: 'Evaluate the integral ∫(2x + 3) dx from 0 to 5.',
      steps: const [
        SolutionStep(
            index: 1,
            description: 'Apply the power rule term-by-term.',
            latex: r'\int (2x + 3)\,dx = x^2 + 3x + C'),
        SolutionStep(
            index: 2,
            description: 'Evaluate at upper bound x = 5.',
            latex: r'(5)^2 + 3(5) = 25 + 15 = 40'),
        SolutionStep(
            index: 3,
            description: 'Evaluate at lower bound x = 0.',
            latex: r'(0)^2 + 3(0) = 0'),
        SolutionStep(
            index: 4,
            description: 'Subtract to get the definite integral.',
            latex: r'40 - 0 = 40'),
      ],
      finalAnswer: '40',
      topic: 'Definite Integrals',
      subject: subject,
      createdAt: DateTime.now(),
    );

    await ref.set(solution.toMap());
    return solution;
  }

  // ---------------------------------------------------------------------------
  // Project Copilot
  // ---------------------------------------------------------------------------

  @override
  Future<ProjectGuidance> getProjectGuidance({
    required String uid,
    required String projectId,
    required ProjectPhase phase,
    required Map<String, dynamic> projectContext,
    String? userQuery,
  }) async {
    await _simulateLatency();

    switch (phase) {
      case ProjectPhase.ideation:
        return const ProjectGuidance(
          phase: ProjectPhase.ideation,
          summary:
              'Strong fit for a campus scope: combines a real student-life '
              'problem with a tractable AI/ML component you can demo live.',
          bullets: [
            'Problem is narrow enough that 2 people can ship in 12 weeks.',
            'Dataset is either public or collectable in <1 week.',
            'Core AI model can run on-device or via free-tier API.',
          ],
          nextSteps: [
            'Write a one-pager: problem, user, solution, why-now.',
            'Validate with 5 target users before committing to scope.',
            'Draft an architecture sketch before writing code.',
          ],
        );
      case ProjectPhase.litReview:
        return const ProjectGuidance(
          phase: ProjectPhase.litReview,
          summary:
              'Three papers to anchor the review; together they give enough '
              'ground to justify novelty and pick a baseline.',
          bullets: [
            'Start with a 2017 paper for the canonical formulation.',
            'Pair it with a 2022 paper that updates the approach.',
            'Find a very recent (2024-25) paper on your exact domain.',
          ],
          nextSteps: [
            'Tabulate: paper, dataset, approach, reported metric, limitation.',
            'Pick the ONE limitation you plan to address.',
            'Draft a 200-word "gap" paragraph for the report.',
          ],
          references: [
            'https://arxiv.org/abs/example1',
            'https://arxiv.org/abs/example2',
          ],
        );
      case ProjectPhase.scaffolding:
        return const ProjectGuidance(
          phase: ProjectPhase.scaffolding,
          summary:
              'Starter structure for a Flutter + Firebase + Python ML backend '
              'with a clear split between UI, API, and model code.',
          bullets: [
            'Flutter app talks to a single REST endpoint.',
            'Python FastAPI server hosts the ML inference.',
            'Model weights live in a `/models` folder, loaded once on start.',
          ],
          nextSteps: [
            'Get a "hello world" request/response round-trip working first.',
            'Only then swap the mock response for the real model.',
            'Add caching so repeated requests don\'t re-run inference.',
          ],
          codeSnippet:
              '# FastAPI skeleton\nfrom fastapi import FastAPI\napp = FastAPI()\n\n@app.post("/predict")\nasync def predict(input: dict):\n    return {"result": "mock"}',
        );
      case ProjectPhase.report:
        return const ProjectGuidance(
          phase: ProjectPhase.report,
          summary:
              'Seven-section report template aligned with what most Indian '
              'engineering universities expect for a major project.',
          bullets: [
            'Abstract (150 words) — problem, approach, result.',
            'Introduction, Lit Review, Methodology, Implementation.',
            'Results with at least one table and one graph.',
            'Conclusion + Future Scope.',
          ],
          nextSteps: [
            'Draft the abstract LAST — easier once the rest is written.',
            'Add a diagram for the methodology (judges love these).',
            'End with a clear "what we could not do, and why" paragraph.',
          ],
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Gen UI
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> generateUIResponse({
    required String prompt,
    required Map<String, dynamic> context,
  }) async {
    await _simulateLatency();

    // Placeholder JSON tree. The Gen UI feature will define the formal
    // schema; this mock returns a simple card + list so the renderer has
    // something to chew on during early development.
    return {
      'type': 'Column',
      'children': [
        {
          'type': 'Card',
          'title': 'Here\'s what I found',
          'body': 'Results for: "$prompt"',
        },
        {
          'type': 'List',
          'items': [
            {'label': 'Chapter 4 — Trees', 'onTapRoute': '/resources-list'},
            {'label': 'Chapter 5 — Graphs', 'onTapRoute': '/resources-list'},
            {'label': 'Past questions', 'onTapRoute': '/resources-list'},
          ],
        },
      ],
    };
  }

  // ---------------------------------------------------------------------------
  // AllyBot
  // ---------------------------------------------------------------------------

  @override
  Future<String> chatAboutPdf({
    required String uid,
    required String pdfUrl,
    required String question,
    List<Map<String, String>> priorTurns = const [],
  }) async {
    await _simulateLatency();
    return 'Based on the document, "$question" relates to the section '
        'on foundational concepts. The key idea is that X depends on Y '
        'because of Z — see page 4 for the derivation.';
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _slug(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  String _trim(String s) => s.length > 60 ? '${s.substring(0, 60)}…' : s;

  String _topicFor(String subject, int slot) {
    final topics = _topicsFor(subject);
    return topics[slot % topics.length];
  }

  List<String> _topicsFor(String subject) {
    switch (subject.toLowerCase()) {
      case 'data structures':
      case 'ds':
        return const [
          'Arrays & Linked Lists',
          'Stacks & Queues',
          'Trees',
          'Graphs',
          'Hashing',
        ];
      case 'dbms':
        return const [
          'ER Model',
          'Normalization',
          'SQL & Relational Algebra',
          'Transactions',
          'Indexing',
        ];
      case 'operating systems':
      case 'os':
        return const [
          'Process Management',
          'Scheduling',
          'Memory Management',
          'File Systems',
          'Concurrency & Deadlocks',
        ];
      case 'computer networks':
      case 'cn':
        return const [
          'OSI & TCP/IP',
          'Data Link Layer',
          'Network Layer',
          'Transport Layer',
          'Application Layer',
        ];
      default:
        return const [
          'Unit 1: Foundations',
          'Unit 2: Core Concepts',
          'Unit 3: Applications',
          'Unit 4: Advanced Topics',
          'Unit 5: Case Studies',
        ];
    }
  }

  String _questionStem(String subject, String topic, int index) {
    final stems = [
      'Define $topic and give two real-world examples.',
      'Explain $topic with a suitable diagram and example.',
      'Compare and contrast $topic with its closest alternative.',
      'Derive the key result for $topic; state assumptions clearly.',
      'Discuss $topic in depth with applications to $subject.',
    ];
    return stems[index % stems.length];
  }
}
