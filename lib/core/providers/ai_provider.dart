import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai/agent_ai_service.dart';
import '../services/ai/ai_service.dart';

/// Single provider every AI-powered feature reads through.
///
/// Phase 4b: returns [AgentAIService] which calls the Python Firebase
/// Function backend. Only [AIService.analyzePyq] is fully wired; other
/// methods throw UnimplementedError until their crews ship in later
/// plans.
///
/// To fall back to the mock during local dev (e.g., when the backend
/// is unreachable), swap `AgentAIService()` for `MockAIService()`
/// temporarily.
final aiServiceProvider = Provider<AIService>((ref) {
  return AgentAIService();
});
