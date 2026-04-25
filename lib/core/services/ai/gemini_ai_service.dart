import '../../../models/ai_models.dart';
import 'ai_service.dart';

/// Phase 4 implementation of [AIService] backed by Google Gemini (Flash 1.5
/// recommended for cost/capability).
///
/// Intentionally a stub. The plan:
///  1. When Phase 4 lands, wire a Firebase/Netlify function that proxies
///     Gemini calls server-side (keeps the API key off-device).
///  2. Fill each method below to call that endpoint, parse the JSON response
///     into the same typed model the mock returns, and persist to Firestore
///     at the same paths the mock uses.
///  3. Flip `aiServiceProvider` from `MockAIService()` to `GeminiAIService()`.
///     Every feature keeps working unchanged.
///
/// Every method throws so accidentally wiring this up early fails loudly.
class GeminiAIService implements AIService {
  static Never _notYet(String method) {
    throw UnimplementedError(
      'GeminiAIService.$method is wired in Phase 4. '
      'Use MockAIService during Phase 2/3 development. '
      'See docs/AI_PIVOT_PLAN.md "Phase 4" for the rollout plan.',
    );
  }

  @override
  Future<List<Misconception>> tagMisconceptions({
    required String subject,
    required String topic,
    required String questionText,
    required String userAnswer,
    required String correctAnswer,
  }) =>
      _notYet('tagMisconceptions');

  @override
  Future<MasteryScore> updateMastery({
    required String uid,
    required String nodeId,
    required bool wasCorrect,
  }) =>
      _notYet('updateMastery');

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
  }) =>
      _notYet('generateStudyPlan');

  @override
  Future<AdversarialExam> generateAdversarialExam({
    required String university,
    required String course,
    required String branch,
    required String sem,
    required String subject,
    List<String> focusTopics = const [],
    int questionCount = 6,
  }) =>
      _notYet('generateAdversarialExam');

  @override
  Future<PyqAnalysis> analyzePyq({
    required String university,
    required String course,
    required String branch,
    required String sem,
    required String subject,
    required List<String> pyqResourceIds,
  }) =>
      _notYet('analyzePyq');

  @override
  Future<DoubtSolution> solveDoubtFromImage({
    required String uid,
    required String imagePath,
    required String subject,
    required String university,
    required String course,
    required String branch,
    required String sem,
  }) =>
      _notYet('solveDoubtFromImage');

  @override
  Future<ProjectGuidance> getProjectGuidance({
    required String uid,
    required String projectId,
    required ProjectPhase phase,
    required Map<String, dynamic> projectContext,
    String? userQuery,
  }) =>
      _notYet('getProjectGuidance');

  @override
  Future<Map<String, dynamic>> generateUIResponse({
    required String prompt,
    required Map<String, dynamic> context,
  }) =>
      _notYet('generateUIResponse');

  @override
  Future<String> chatAboutPdf({
    required String uid,
    required String pdfUrl,
    required String question,
    List<Map<String, String>> priorTurns = const [],
  }) =>
      _notYet('chatAboutPdf');
}
