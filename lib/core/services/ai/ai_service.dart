import '../../../models/ai_models.dart';

/// Single abstraction behind every AI-powered feature in Academic Ally.
///
/// Callers (Study Planner, PYQ Analyzer, Snap-a-Doubt, Project Copilot,
/// Gen UI renderer, Misconception tagger) talk to this interface and never
/// know whether the impl is `MockAIService` (Phase 2) or `GeminiAIService`
/// (Phase 4). Swapping providers is one line in `aiServiceProvider`.
///
/// Interface stability is critical — adding/removing parameters later
/// forces every feature to be refactored. Design decisions shaping this
/// file:
///  - Every method is `Future<T>`. When Gemini lands, methods that stream
///    (`chatProjectCopilot`, `chatAboutPdf`) get streaming siblings; the
///    Future variants stay for callers that only need the final text.
///  - Every method that writes user state takes `uid` so the mock can
///    read/write user-scoped Firestore and the real impl can authorize.
///  - Typed models everywhere EXCEPT Gen UI, where the point of the
///    feature is that the LLM picks the UI shape at runtime.
abstract class AIService {
  // ---------------------------------------------------------------------------
  // Misconception Graph
  // ---------------------------------------------------------------------------

  Future<List<Misconception>> tagMisconceptions({
    required String subject,
    required String topic,
    required String questionText,
    required String userAnswer,
    required String correctAnswer,
  });

  Future<MasteryScore> updateMastery({
    required String uid,
    required String nodeId,
    required bool wasCorrect,
  });

  // ---------------------------------------------------------------------------
  // Study Planner
  // ---------------------------------------------------------------------------

  Future<StudyPlan> generateStudyPlan({
    required String uid,
    required DateTime examDate,
    required List<String> subjects,
    required String branch,
    required String sem,
    List<String> weakTopics = const [],
    int dailyStudyMinutes = 120,
  });

  // ---------------------------------------------------------------------------
  // PYQ Analyzer
  // ---------------------------------------------------------------------------

  Future<PyqAnalysis> analyzePyq({
    required String university,
    required String course,
    required String branch,
    required String sem,
    required String subject,
    required List<String> pyqResourceIds,
  });

  // ---------------------------------------------------------------------------
  // Snap-a-Doubt
  // ---------------------------------------------------------------------------

  /// Accept a storage URL (R2 or Firebase Storage) for a photo of a doubt
  /// and return an extracted question + step-by-step solution.
  Future<DoubtSolution> solveDoubtFromImage({
    required String uid,
    required String imageUrl,
    String? subjectHint,
  });

  // ---------------------------------------------------------------------------
  // Project Copilot
  // ---------------------------------------------------------------------------

  Future<ProjectGuidance> getProjectGuidance({
    required String uid,
    required String projectId,
    required ProjectPhase phase,
    required Map<String, dynamic> projectContext,
    String? userQuery,
  });

  // ---------------------------------------------------------------------------
  // Gen UI
  // ---------------------------------------------------------------------------

  /// Returns a JSON tree describing the widgets to render for a given user
  /// prompt. Schema defined in the Gen UI feature itself (Phase 2, #8).
  Future<Map<String, dynamic>> generateUIResponse({
    required String prompt,
    required Map<String, dynamic> context,
  });

  // ---------------------------------------------------------------------------
  // AllyBot (PDF chat) — continuity with the existing chat feature.
  // ---------------------------------------------------------------------------

  /// One-shot Q&A against a PDF. In Phase 4 this gets a streaming sibling.
  Future<String> chatAboutPdf({
    required String uid,
    required String pdfUrl,
    required String question,
    List<Map<String, String>> priorTurns = const [],
  });
}
