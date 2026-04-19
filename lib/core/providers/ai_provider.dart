import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai/ai_service.dart';
import '../services/ai/mock_ai_service.dart';

/// Single provider every AI-powered feature reads through.
///
/// **Phase 4 swap:** when Gemini integration lands, change the single line
/// below to `GeminiAIService()`. Every feature continues to work unchanged.
final aiServiceProvider = Provider<AIService>((ref) {
  return MockAIService();
});
