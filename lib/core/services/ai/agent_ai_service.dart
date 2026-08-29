import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/ai_models.dart';
import 'ai_service.dart';
import 'mock_ai_service.dart';

/// AIService backed by the Python Firebase Cloud Functions multi-agent
/// backend. Phase 4b only implements [analyzePyq] end-to-end; the other
/// seven methods delegate to [MockAIService] so the rest of the app keeps
/// working against canned responses until their crews are ported in
/// subsequent plans.
class AgentAIService implements AIService {
  AgentAIService({http.Client? httpClient, Uuid? uuid, AIService? fallback})
    : _http = httpClient ?? http.Client(),
      _uuid = uuid ?? const Uuid(),
      _fallback = fallback ?? MockAIService();

  final http.Client _http;
  final Uuid _uuid;
  final AIService _fallback;

  bool _isDemoCurriculum(String branch, String sem) {
    final normalizedBranch = branch.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    final normalizedSem = sem.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    final isIt =
        normalizedBranch == 'it' || normalizedBranch == 'informationtechnology';
    final isEarlySemester =
        normalizedSem == '1' ||
        normalizedSem == '2' ||
        normalizedSem == 'sem1' ||
        normalizedSem == 'sem2' ||
        normalizedSem == 'semester1' ||
        normalizedSem == 'semester2';
    return isIt && isEarlySemester;
  }

  Future<void> _animateDemoRun({
    required String runId,
    required String subject,
    required List<String> agents,
  }) async {
    final ref = FirebaseFirestore.instance.doc('AnalysisRuns/$runId');
    await ref.set({
      'runId': runId,
      'subject': subject,
      'status': 'running',
      'agents': {for (final agent in agents) agent: 'pending'},
      'createdAt': FieldValue.serverTimestamp(),
      'demoFallback': true,
    });
    for (final agent in agents) {
      await Future.delayed(const Duration(milliseconds: 350));
      await ref.update({'agents.$agent': 'done'});
    }
    await ref.update({
      'status': 'complete',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<PyqAnalysis> analyzePyq({
    required String university,
    required String course,
    required String branch,
    required String sem,
    required String subject,
    required List<String> pyqResourceIds,
  }) async {
    final runId = _uuid.v4();
    final idToken = await _freshIdToken();

    final uri = Uri.parse('${AppConstants.aiBackendBaseUrl}/pyq_analyze');
    final response = await _http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'run_id': runId,
            'university': university,
            'course': course,
            'branch': branch,
            'sem': sem,
            'subject': subject,
            'pyq_resource_ids': pyqResourceIds,
            'force_refresh': true,
          }),
        )
        .timeout(const Duration(seconds: 200));

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(response);
      throw AgentBackendException(
        statusCode: response.statusCode,
        message: msg,
        runId: runId,
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return _parsePyqAnalysisResponse(body);
  }

  /// Convenience for the UI layer to subscribe to `AnalysisRuns/{runId}`
  /// BEFORE triggering the HTTP call, avoiding a race where agents complete
  /// before the subscription lands.
  Future<PyqAnalysisWithRunId> analyzePyqWithRunId({
    required String runId,
    required String university,
    required String course,
    required String branch,
    required String sem,
    required String subject,
    required List<String> pyqResourceIds,
  }) async {
    if (_isDemoCurriculum(branch, sem)) {
      await _animateDemoRun(
        runId: runId,
        subject: subject,
        agents: const [
          'syllabus',
          'webResearch',
          'pattern',
          'predictor',
          'formatter',
        ],
      );
      final analysis = await _fallback.analyzePyq(
        university: university,
        course: course,
        branch: branch,
        sem: sem,
        subject: subject,
        pyqResourceIds: pyqResourceIds,
      );
      return PyqAnalysisWithRunId(analysis: analysis, runId: runId);
    }
    final idToken = await _freshIdToken();
    final uri = Uri.parse('${AppConstants.aiBackendBaseUrl}/pyq_analyze');
    final response = await _http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'run_id': runId,
            'university': university,
            'course': course,
            'branch': branch,
            'sem': sem,
            'subject': subject,
            'pyq_resource_ids': pyqResourceIds,
            'force_refresh': true,
          }),
        )
        .timeout(const Duration(seconds: 200));
    if (response.statusCode != 200) {
      throw AgentBackendException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response),
        runId: runId,
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final analysis = _parsePyqAnalysisResponse(body);
    return PyqAnalysisWithRunId(analysis: analysis, runId: runId);
  }

  PyqAnalysis _parsePyqAnalysisResponse(Map<String, dynamic> body) {
    final predicted = (body['predictedQuestions'] as List<dynamic>)
        .map((e) => PredictedQuestion.fromMap(e as Map<String, dynamic>))
        .toList();
    final weights = (body['topicWeights'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    return PyqAnalysis(
      subject: body['subject'] as String,
      topicWeights: weights,
      predictedQuestions: predicted,
      sourceResourceIds: List<String>.from(
        body['sourceResourceIds'] ?? const [],
      ),
      lastAnalyzed: DateTime.now(),
    );
  }

  Future<String> _freshIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Must be signed in to call the AI backend.');
    }
    // getIdToken(false) returns the cached token if not expired. We
    // intentionally do NOT pass forceRefresh:true — a freshly-minted token
    // from Google's servers can have an `iat` slightly ahead of the local
    // backend clock, and firebase-admin will reject it as
    // "Token used too early". Stale-token-after-logout is handled at the
    // Riverpod layer via authInvalidatorProvider, not here.
    final token = await user.getIdToken(false);
    if (token == null) {
      throw StateError('Could not obtain ID token.');
    }
    return token;
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      // FastAPI's HTTPException(detail=<dict>) wires the dict under
      // body["detail"]; older non-FastAPI handlers return the dict
      // at the top level. Handle both.
      final Map<String, dynamic> source = body['detail'] is Map<String, dynamic>
          ? body['detail'] as Map<String, dynamic>
          : body;
      // If detail is just a string (FastAPI default for raw HTTPException),
      // use that as the message.
      if (body['detail'] is String) {
        return body['detail'] as String;
      }
      final userMsg = source['error'] as String? ?? 'Unknown error';
      final debug = source['debug_error'] as String?;
      if (debug != null && debug.isNotEmpty) {
        return '$userMsg\n\nDEBUG: $debug';
      }
      return userMsg;
    } catch (_) {
      return 'Server error (${response.statusCode})';
    }
  }

  // The 7 non-PYQ methods delegate to MockAIService so those features
  // keep working on canned responses until their crews are ported.

  @override
  Future<List<Misconception>> tagMisconceptions({
    required String subject,
    required String topic,
    required String questionText,
    required String userAnswer,
    required String correctAnswer,
  }) => _fallback.tagMisconceptions(
    subject: subject,
    topic: topic,
    questionText: questionText,
    userAnswer: userAnswer,
    correctAnswer: correctAnswer,
  );

  @override
  Future<MasteryScore> updateMastery({
    required String uid,
    required String nodeId,
    required bool wasCorrect,
  }) =>
      _fallback.updateMastery(uid: uid, nodeId: nodeId, wasCorrect: wasCorrect);

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
    if (_isDemoCurriculum(branch, sem)) {
      return _fallback.generateStudyPlan(
        uid: uid,
        examDate: examDate,
        subjects: subjects,
        university: university,
        course: course,
        branch: branch,
        sem: sem,
        weakTopics: weakTopics,
        dailyStudyMinutes: dailyStudyMinutes,
      );
    }
    final runId = _uuid.v4();
    final idToken = await _freshIdToken();
    final uri = Uri.parse(
      '${AppConstants.aiBackendBaseUrl}/generate_study_plan',
    );
    final response = await _http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'run_id': runId,
            'uid': uid,
            'university': university,
            'course': course,
            'branch': branch,
            'sem': sem,
            'subjects': subjects,
            'exam_date': examDate.toIso8601String(),
            'daily_study_minutes': dailyStudyMinutes,
            'weak_topics': weakTopics,
            'force_refresh': true,
          }),
        )
        .timeout(const Duration(seconds: 300));
    if (response.statusCode != 200) {
      throw AgentBackendException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response),
        runId: runId,
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final planId = body['plan_id'] as String;
    final examDateOut = DateTime.parse(body['examDate'] as String);
    final daysJson = body['days'] as List<dynamic>;
    final days = daysJson.map((d) {
      final m = d as Map<String, dynamic>;
      final tasksJson = m['tasks'] as List<dynamic>;
      final tasks = tasksJson.map((t) {
        final tm = t as Map<String, dynamic>;
        return StudyTask(
          subject: tm['subject'] as String? ?? '',
          topic: tm['topic'] as String? ?? '',
          durationMinutes: (tm['durationMinutes'] as num?)?.toInt() ?? 0,
          rationale: tm['rationale'] as String? ?? '',
          completed: tm['completed'] as bool? ?? false,
        );
      }).toList();
      return StudyDay(date: DateTime.parse(m['date'] as String), tasks: tasks);
    }).toList();
    return StudyPlan(
      id: planId,
      examDate: examDateOut,
      subjects: List<String>.from(body['subjects'] as List),
      days: days,
      createdAt: DateTime.now(),
    );
  }

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
    final runId = _uuid.v4();
    final idToken = await _freshIdToken();
    final uri = Uri.parse(
      '${AppConstants.aiBackendBaseUrl}/generate_adversarial_exam',
    );
    final response = await _http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'run_id': runId,
            'university': university,
            'course': course,
            'branch': branch,
            'sem': sem,
            'subject': subject,
            'focus_topics': focusTopics,
            'question_count': questionCount,
            'force_refresh': true,
          }),
        )
        .timeout(const Duration(seconds: 300));
    if (response.statusCode != 200) {
      throw AgentBackendException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response),
        runId: runId,
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AdversarialExam.fromMap(body);
  }

  /// Same as [generateAdversarialExam] but exposes the run_id so the UI
  /// can subscribe to AnalysisRuns/{runId} for live progress before the
  /// HTTP call returns. Mirrors the analyzePyqWithRunId pattern.
  Future<AdversarialExamWithRunId> generateAdversarialExamWithRunId({
    required String runId,
    required String university,
    required String course,
    required String branch,
    required String sem,
    required String subject,
    List<String> focusTopics = const [],
    int questionCount = 6,
  }) async {
    if (_isDemoCurriculum(branch, sem)) {
      await _animateDemoRun(
        runId: runId,
        subject: subject,
        agents: const [
          'topicSelector',
          'trapMiner',
          'questionGenerator',
          'formatter',
        ],
      );
      final exam = await _fallback.generateAdversarialExam(
        university: university,
        course: course,
        branch: branch,
        sem: sem,
        subject: subject,
        focusTopics: focusTopics,
        questionCount: questionCount,
      );
      return AdversarialExamWithRunId(exam: exam, runId: runId);
    }
    final idToken = await _freshIdToken();
    final uri = Uri.parse(
      '${AppConstants.aiBackendBaseUrl}/generate_adversarial_exam',
    );
    final response = await _http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'run_id': runId,
            'university': university,
            'course': course,
            'branch': branch,
            'sem': sem,
            'subject': subject,
            'focus_topics': focusTopics,
            'question_count': questionCount,
            'force_refresh': true,
          }),
        )
        .timeout(const Duration(seconds: 300));
    if (response.statusCode != 200) {
      throw AgentBackendException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response),
        runId: runId,
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AdversarialExamWithRunId(
      exam: AdversarialExam.fromMap(body),
      runId: runId,
    );
  }

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
    final result = await solveDoubtFromImageWithRunId(
      runId: _uuid.v4(),
      uid: uid,
      imagePath: imagePath,
      subject: subject,
      university: university,
      course: course,
      branch: branch,
      sem: sem,
    );
    return result.solution;
  }

  /// Same as [solveDoubtFromImage] but exposes the run_id and doubt_id
  /// so the Flutter UI can subscribe to AnalysisRuns/{runId} for live
  /// agent progress while the backend is working. Mirrors the
  /// analyzePyqWithRunId pattern.
  Future<DoubtSolutionWithRunId> solveDoubtFromImageWithRunId({
    required String runId,
    required String uid,
    required String imagePath,
    required String subject,
    required String university,
    required String course,
    required String branch,
    required String sem,
  }) async {
    if (_isDemoCurriculum(branch, sem)) {
      await _animateDemoRun(
        runId: runId,
        subject: subject,
        agents: const ['vision', 'retriever', 'solver', 'validator'],
      );
      final solution = await _fallback.solveDoubtFromImage(
        uid: uid,
        imagePath: imagePath,
        subject: subject,
        university: university,
        course: course,
        branch: branch,
        sem: sem,
      );
      return DoubtSolutionWithRunId(solution: solution, runId: runId);
    }
    final doubtId = _uuid.v4();
    final storageId = 'Doubts/$uid/$doubtId.jpg';

    // 1. Upload image bytes to Firebase Storage.
    final file = File(imagePath);
    final storageRef = FirebaseStorage.instance.ref(storageId);
    await storageRef.putFile(file).timeout(const Duration(seconds: 30));

    // 2. POST /solve_doubt with the storage path. Backend downloads via
    //    firebase-admin storage and runs the agentic crew.
    final idToken = await _freshIdToken();
    final uri = Uri.parse('${AppConstants.aiBackendBaseUrl}/solve_doubt');
    final response = await _http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'run_id': runId,
            'uid': uid,
            'doubt_id': doubtId,
            'storage_id': storageId,
            'subject': subject,
            'university': university,
            'course': course,
            'branch': branch,
            'sem': sem,
          }),
        )
        .timeout(const Duration(seconds: 300));

    if (response.statusCode != 200) {
      throw AgentBackendException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response),
        runId: runId,
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final stepsJson = body['steps'] as List<dynamic>? ?? const [];
    final steps = stepsJson
        .map((s) => SolutionStep.fromMap(s as Map<String, dynamic>))
        .toList();

    final solution = DoubtSolution(
      id: body['doubt_id'] as String,
      imageUrl: body['imageUrl'] as String? ?? '',
      extractedQuestion: body['extractedQuestion'] as String? ?? '',
      steps: steps,
      finalAnswer: body['finalAnswer'] as String? ?? '',
      topic: body['topic'] as String? ?? '',
      subject: body['subject'] as String?,
      createdAt: DateTime.now(),
    );
    return DoubtSolutionWithRunId(solution: solution, runId: runId);
  }

  @override
  Future<ProjectGuidance> getProjectGuidance({
    required String uid,
    required String projectId,
    required ProjectPhase phase,
    required Map<String, dynamic> projectContext,
    String? userQuery,
  }) => _fallback.getProjectGuidance(
    uid: uid,
    projectId: projectId,
    phase: phase,
    projectContext: projectContext,
    userQuery: userQuery,
  );

  @override
  Future<Map<String, dynamic>> generateUIResponse({
    required String prompt,
    required Map<String, dynamic> context,
  }) => _fallback.generateUIResponse(prompt: prompt, context: context);

  @override
  Future<String> chatAboutPdf({
    required String uid,
    required String pdfUrl,
    required String question,
    List<Map<String, String>> priorTurns = const [],
  }) => _fallback.chatAboutPdf(
    uid: uid,
    pdfUrl: pdfUrl,
    question: question,
    priorTurns: priorTurns,
  );
}

class PyqAnalysisWithRunId {
  final PyqAnalysis analysis;
  final String runId;
  const PyqAnalysisWithRunId({required this.analysis, required this.runId});
}

class AdversarialExamWithRunId {
  final AdversarialExam exam;
  final String runId;
  const AdversarialExamWithRunId({required this.exam, required this.runId});
}

class DoubtSolutionWithRunId {
  final DoubtSolution solution;
  final String runId;
  const DoubtSolutionWithRunId({required this.solution, required this.runId});
}

class AgentBackendException implements Exception {
  final int statusCode;
  final String message;
  final String runId;
  const AgentBackendException({
    required this.statusCode,
    required this.message,
    required this.runId,
  });
  // toString returns the user-facing message only — the status code is
  // still accessible via .statusCode for debug/logging. UIs that print
  // error.toString() should land on the clean backend message.
  @override
  String toString() => message;
}
