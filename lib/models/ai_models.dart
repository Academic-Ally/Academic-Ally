import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// AI data models for Academic Ally's Phase 2 AI features.
// -----------------------------------------------------------------------------
// Every model has JSON (client-runtime) and Firestore (persistence) flavours.
// The Firestore shape is authoritative — see `docs/FIRESTORE_SCHEMA.md` for
// paths. JSON shape is what the LLM returns once Phase 4 wires Gemini up;
// during Phase 2 the MockAIService hand-constructs instances directly.
// =============================================================================

// -----------------------------------------------------------------------------
// Misconception Graph
// -----------------------------------------------------------------------------

/// One topic node in the knowledge graph.
/// Stored at `KnowledgeGraph/{university}/{course}/{subject}/nodes/{nodeId}`.
class KnowledgeNode {
  final String id;
  final String topic;
  final String subject;
  final List<String> prerequisites;
  final List<String> commonMisconceptions;

  const KnowledgeNode({
    required this.id,
    required this.topic,
    required this.subject,
    this.prerequisites = const [],
    this.commonMisconceptions = const [],
  });

  factory KnowledgeNode.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return KnowledgeNode(
      id: doc.id,
      topic: d['topic'] ?? '',
      subject: d['subject'] ?? '',
      prerequisites: List<String>.from(d['prerequisites'] ?? const []),
      commonMisconceptions:
          List<String>.from(d['commonMisconceptions'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
        'topic': topic,
        'subject': subject,
        'prerequisites': prerequisites,
        'commonMisconceptions': commonMisconceptions,
      };
}

/// A misconception the user holds, tied to a knowledge-graph node.
/// Stored at `Users/{uid}/Misconceptions/{nodeId}`.
class Misconception {
  final String nodeId;
  final String description;
  final List<String> evidenceIds;
  final DateTime? lastSeen;
  final double strength;

  const Misconception({
    required this.nodeId,
    required this.description,
    this.evidenceIds = const [],
    this.lastSeen,
    this.strength = 0.0,
  });

  factory Misconception.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Misconception(
      nodeId: doc.id,
      description: d['description'] ?? '',
      evidenceIds: List<String>.from(d['evidenceIds'] ?? const []),
      lastSeen: (d['lastSeen'] as Timestamp?)?.toDate(),
      strength: (d['strength'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'description': description,
        'evidenceIds': evidenceIds,
        'lastSeen': lastSeen != null
            ? Timestamp.fromDate(lastSeen!)
            : FieldValue.serverTimestamp(),
        'strength': strength,
      };
}

/// Per-topic mastery tracked as the user answers questions over time.
/// Stored at `Users/{uid}/MasteryScores/{nodeId}`.
class MasteryScore {
  final String nodeId;
  final double score;
  final int attempts;
  final DateTime? lastUpdated;

  const MasteryScore({
    required this.nodeId,
    required this.score,
    required this.attempts,
    this.lastUpdated,
  });

  factory MasteryScore.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MasteryScore(
      nodeId: doc.id,
      score: (d['score'] as num?)?.toDouble() ?? 0.0,
      attempts: (d['attempts'] as num?)?.toInt() ?? 0,
      lastUpdated: (d['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'score': score,
        'attempts': attempts,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
}

// -----------------------------------------------------------------------------
// Study Planner
// -----------------------------------------------------------------------------

/// A single day's set of study tasks within a plan.
class StudyDay {
  final DateTime date;
  final List<StudyTask> tasks;

  const StudyDay({required this.date, required this.tasks});

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'tasks': tasks.map((t) => t.toMap()).toList(),
      };

  factory StudyDay.fromMap(Map<String, dynamic> m) => StudyDay(
        date: (m['date'] as Timestamp).toDate(),
        tasks: (m['tasks'] as List<dynamic>? ?? const [])
            .map((t) => StudyTask.fromMap(t as Map<String, dynamic>))
            .toList(),
      );
}

class StudyTask {
  final String subject;
  final String topic;
  final int durationMinutes;
  final String rationale;
  final bool completed;

  const StudyTask({
    required this.subject,
    required this.topic,
    required this.durationMinutes,
    required this.rationale,
    this.completed = false,
  });

  StudyTask copyWith({bool? completed}) => StudyTask(
        subject: subject,
        topic: topic,
        durationMinutes: durationMinutes,
        rationale: rationale,
        completed: completed ?? this.completed,
      );

  Map<String, dynamic> toMap() => {
        'subject': subject,
        'topic': topic,
        'durationMinutes': durationMinutes,
        'rationale': rationale,
        'completed': completed,
      };

  factory StudyTask.fromMap(Map<String, dynamic> m) => StudyTask(
        subject: m['subject'] ?? '',
        topic: m['topic'] ?? '',
        durationMinutes: (m['durationMinutes'] as num?)?.toInt() ?? 0,
        rationale: m['rationale'] ?? '',
        completed: m['completed'] ?? false,
      );
}

/// Full study plan.
/// Stored at `Users/{uid}/StudyPlans/{planId}`.
class StudyPlan {
  final String id;
  final DateTime examDate;
  final List<String> subjects;
  final List<StudyDay> days;
  final DateTime? createdAt;

  const StudyPlan({
    required this.id,
    required this.examDate,
    required this.subjects,
    required this.days,
    this.createdAt,
  });

  /// Progress as fraction of completed tasks across all days.
  double get progress {
    final all = days.expand((d) => d.tasks).toList();
    if (all.isEmpty) return 0;
    final done = all.where((t) => t.completed).length;
    return done / all.length;
  }

  factory StudyPlan.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return StudyPlan(
      id: doc.id,
      examDate: (d['examDate'] as Timestamp).toDate(),
      subjects: List<String>.from(d['subjects'] ?? const []),
      days: (d['days'] as List<dynamic>? ?? const [])
          .map((x) => StudyDay.fromMap(x as Map<String, dynamic>))
          .toList(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'examDate': Timestamp.fromDate(examDate),
        'subjects': subjects,
        'days': days.map((d) => d.toMap()).toList(),
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}

// -----------------------------------------------------------------------------
// PYQ Analyzer
// -----------------------------------------------------------------------------

class PredictedQuestion {
  final String question;
  final String topic;
  final int expectedMarks;
  final double likelihood;
  final List<String> sourcePaperIds;

  const PredictedQuestion({
    required this.question,
    required this.topic,
    required this.expectedMarks,
    required this.likelihood,
    this.sourcePaperIds = const [],
  });

  Map<String, dynamic> toMap() => {
        'question': question,
        'topic': topic,
        'expectedMarks': expectedMarks,
        'likelihood': likelihood,
        'sourcePaperIds': sourcePaperIds,
      };

  factory PredictedQuestion.fromMap(Map<String, dynamic> m) =>
      PredictedQuestion(
        question: m['question'] ?? '',
        topic: m['topic'] ?? '',
        expectedMarks: (m['expectedMarks'] as num?)?.toInt() ?? 0,
        likelihood: (m['likelihood'] as num?)?.toDouble() ?? 0.0,
        sourcePaperIds: List<String>.from(m['sourcePaperIds'] ?? const []),
      );
}

/// Cached PYQ analysis output.
/// Stored at `PyqAnalysis/{university}/{course}/{branch}/{sem}/{subject}`.
class PyqAnalysis {
  final String subject;
  final Map<String, double> topicWeights;
  final List<PredictedQuestion> predictedQuestions;
  final List<String> sourceResourceIds;
  final DateTime? lastAnalyzed;

  const PyqAnalysis({
    required this.subject,
    required this.topicWeights,
    required this.predictedQuestions,
    this.sourceResourceIds = const [],
    this.lastAnalyzed,
  });

  factory PyqAnalysis.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PyqAnalysis(
      subject: d['subject'] ?? '',
      topicWeights: Map<String, double>.from(
        (d['topicWeights'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
      predictedQuestions:
          (d['predictedQuestions'] as List<dynamic>? ?? const [])
              .map((x) =>
                  PredictedQuestion.fromMap(x as Map<String, dynamic>))
              .toList(),
      sourceResourceIds:
          List<String>.from(d['sourceResourceIds'] ?? const []),
      lastAnalyzed: (d['lastAnalyzed'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'subject': subject,
        'topicWeights': topicWeights,
        'predictedQuestions':
            predictedQuestions.map((p) => p.toMap()).toList(),
        'sourceResourceIds': sourceResourceIds,
        'lastAnalyzed': lastAnalyzed != null
            ? Timestamp.fromDate(lastAnalyzed!)
            : FieldValue.serverTimestamp(),
      };
}

// -----------------------------------------------------------------------------
// Adversarial Examiner
// -----------------------------------------------------------------------------

/// One trap question generated by the Adversarial Examiner crew.
class AdversarialQuestion {
  final String topic;
  final String question;
  final String trapType;
  final String commonMistake;
  final String correctApproach;
  final int expectedMarks;
  final String difficulty; // 'medium' | 'hard' | 'very_hard'
  final List<String> sourcePaperIds;

  const AdversarialQuestion({
    required this.topic,
    required this.question,
    required this.trapType,
    required this.commonMistake,
    required this.correctApproach,
    required this.expectedMarks,
    required this.difficulty,
    this.sourcePaperIds = const [],
  });

  factory AdversarialQuestion.fromMap(Map<String, dynamic> m) =>
      AdversarialQuestion(
        topic: m['topic'] ?? '',
        question: m['question'] ?? '',
        trapType: m['trapType'] ?? '',
        commonMistake: m['commonMistake'] ?? '',
        correctApproach: m['correctApproach'] ?? '',
        expectedMarks: (m['expectedMarks'] as num?)?.toInt() ?? 0,
        difficulty: m['difficulty'] ?? 'medium',
        sourcePaperIds: List<String>.from(m['sourcePaperIds'] ?? const []),
      );
}

/// Output of one adversarial-examiner run.
class AdversarialExam {
  final String subject;
  final String overallFocus;
  final List<AdversarialQuestion> questions;

  const AdversarialExam({
    required this.subject,
    required this.overallFocus,
    required this.questions,
  });

  factory AdversarialExam.fromMap(Map<String, dynamic> m) => AdversarialExam(
        subject: m['subject'] ?? '',
        overallFocus: m['overallFocus'] ?? '',
        questions: (m['questions'] as List<dynamic>? ?? const [])
            .map((x) => AdversarialQuestion.fromMap(x as Map<String, dynamic>))
            .toList(),
      );
}

// -----------------------------------------------------------------------------
// Snap-a-Doubt
// -----------------------------------------------------------------------------

/// Citation tying a solution step to a specific page of a source PDF.
class SolutionCitation {
  final String filename;
  final int pageStart;
  final int pageEnd;
  final String? storageId; // resolved by backend; null if unresolved
  final String? resourceId;
  final String? category; // 'Notes' | 'QuestionPapers' | 'Syllabus' | 'OtherResources'

  const SolutionCitation({
    required this.filename,
    required this.pageStart,
    required this.pageEnd,
    this.storageId,
    this.resourceId,
    this.category,
  });

  /// True if the citation has enough info to open the PDF on tap.
  bool get isClickable =>
      storageId != null && storageId!.isNotEmpty;

  String get pageLabel =>
      pageStart == pageEnd ? 'p.$pageStart' : 'pp.$pageStart-$pageEnd';

  Map<String, dynamic> toMap() => {
        'filename': filename,
        'pageStart': pageStart,
        'pageEnd': pageEnd,
        if (storageId != null) 'storageId': storageId,
        if (resourceId != null) 'resourceId': resourceId,
        if (category != null) 'category': category,
      };

  factory SolutionCitation.fromMap(Map<String, dynamic> m) => SolutionCitation(
        filename: m['filename'] ?? '',
        pageStart: (m['pageStart'] as num?)?.toInt() ?? 1,
        pageEnd: (m['pageEnd'] as num?)?.toInt() ??
            (m['pageStart'] as num?)?.toInt() ??
            1,
        storageId: m['storageId'],
        resourceId: m['resourceId'],
        category: m['category'],
      );
}

class SolutionStep {
  final int index;
  final String description;
  final String? latex;
  final List<SolutionCitation> citations;

  const SolutionStep({
    required this.index,
    required this.description,
    this.latex,
    this.citations = const [],
  });

  Map<String, dynamic> toMap() => {
        'index': index,
        'description': description,
        if (latex != null) 'latex': latex,
        'citations': citations.map((c) => c.toMap()).toList(),
      };

  factory SolutionStep.fromMap(Map<String, dynamic> m) => SolutionStep(
        index: (m['index'] as num?)?.toInt() ?? 0,
        description: m['description'] ?? '',
        latex: m['latex'],
        citations: (m['citations'] as List<dynamic>? ?? const [])
            .map((c) => SolutionCitation.fromMap(c as Map<String, dynamic>))
            .toList(),
      );
}

/// Solution returned for a snapped doubt.
/// Stored at `Users/{uid}/DoubtHistory/{doubtId}`.
class DoubtSolution {
  final String id;
  final String imageUrl;
  final String extractedQuestion;
  final List<SolutionStep> steps;
  final String finalAnswer;
  final String topic;
  final String? subject;
  final DateTime? createdAt;

  const DoubtSolution({
    required this.id,
    required this.imageUrl,
    required this.extractedQuestion,
    required this.steps,
    required this.finalAnswer,
    required this.topic,
    this.subject,
    this.createdAt,
  });

  factory DoubtSolution.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DoubtSolution(
      id: doc.id,
      imageUrl: d['imageUrl'] ?? '',
      extractedQuestion: d['extractedQuestion'] ?? '',
      steps: (d['steps'] as List<dynamic>? ?? const [])
          .map((x) => SolutionStep.fromMap(x as Map<String, dynamic>))
          .toList(),
      finalAnswer: d['finalAnswer'] ?? '',
      topic: d['topic'] ?? '',
      subject: d['subject'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'imageUrl': imageUrl,
        'extractedQuestion': extractedQuestion,
        'steps': steps.map((s) => s.toMap()).toList(),
        'finalAnswer': finalAnswer,
        'topic': topic,
        if (subject != null) 'subject': subject,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}

// -----------------------------------------------------------------------------
// Project Copilot
// -----------------------------------------------------------------------------

enum ProjectPhase { ideation, litReview, scaffolding, report }

extension ProjectPhaseX on ProjectPhase {
  String get wire {
    switch (this) {
      case ProjectPhase.ideation:
        return 'ideation';
      case ProjectPhase.litReview:
        return 'litReview';
      case ProjectPhase.scaffolding:
        return 'scaffolding';
      case ProjectPhase.report:
        return 'report';
    }
  }

  static ProjectPhase fromWire(String? raw) {
    switch (raw) {
      case 'litReview':
        return ProjectPhase.litReview;
      case 'scaffolding':
        return ProjectPhase.scaffolding;
      case 'report':
        return ProjectPhase.report;
      case 'ideation':
      default:
        return ProjectPhase.ideation;
    }
  }
}

class ProjectGuidance {
  final ProjectPhase phase;
  final String summary;
  final List<String> bullets;
  final List<String> nextSteps;
  final List<String> references;
  final String? codeSnippet;

  const ProjectGuidance({
    required this.phase,
    required this.summary,
    required this.bullets,
    required this.nextSteps,
    this.references = const [],
    this.codeSnippet,
  });

  Map<String, dynamic> toMap() => {
        'phase': phase.wire,
        'summary': summary,
        'bullets': bullets,
        'nextSteps': nextSteps,
        'references': references,
        if (codeSnippet != null) 'codeSnippet': codeSnippet,
      };
}
