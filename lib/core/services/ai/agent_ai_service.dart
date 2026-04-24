import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
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
  AgentAIService({
    http.Client? httpClient,
    Uuid? uuid,
    AIService? fallback,
  })  : _http = httpClient ?? http.Client(),
        _uuid = uuid ?? const Uuid(),
        _fallback = fallback ?? MockAIService();

  final http.Client _http;
  final Uuid _uuid;
  final AIService _fallback;

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
            'force_refresh': false,
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
            'force_refresh': false,
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
        .map(
          (e) => PredictedQuestion.fromMap(e as Map<String, dynamic>),
        )
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
    final token = await user.getIdToken(false);
    if (token == null) {
      throw StateError('Could not obtain ID token.');
    }
    return token;
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final userMsg = body['error'] as String? ?? 'Unknown error';
      final debug = body['debug_error'] as String?;
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
  }) =>
      _fallback.tagMisconceptions(
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
    required String branch,
    required String sem,
    List<String> weakTopics = const [],
    int dailyStudyMinutes = 120,
  }) =>
      _fallback.generateStudyPlan(
        uid: uid,
        examDate: examDate,
        subjects: subjects,
        branch: branch,
        sem: sem,
        weakTopics: weakTopics,
        dailyStudyMinutes: dailyStudyMinutes,
      );

  @override
  Future<DoubtSolution> solveDoubtFromImage({
    required String uid,
    required String imageUrl,
    String? subjectHint,
  }) =>
      _fallback.solveDoubtFromImage(
        uid: uid,
        imageUrl: imageUrl,
        subjectHint: subjectHint,
      );

  @override
  Future<ProjectGuidance> getProjectGuidance({
    required String uid,
    required String projectId,
    required ProjectPhase phase,
    required Map<String, dynamic> projectContext,
    String? userQuery,
  }) =>
      _fallback.getProjectGuidance(
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
  }) =>
      _fallback.generateUIResponse(prompt: prompt, context: context);

  @override
  Future<String> chatAboutPdf({
    required String uid,
    required String pdfUrl,
    required String question,
    List<Map<String, String>> priorTurns = const [],
  }) =>
      _fallback.chatAboutPdf(
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

class AgentBackendException implements Exception {
  final int statusCode;
  final String message;
  final String runId;
  const AgentBackendException({
    required this.statusCode,
    required this.message,
    required this.runId,
  });
  @override
  String toString() => 'AgentBackendException($statusCode): $message';
}
