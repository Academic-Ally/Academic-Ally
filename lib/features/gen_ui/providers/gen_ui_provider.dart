import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ai_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// Holds the most recent Gen UI response (the raw JSON tree) so a single
/// screen can show a loading state, render the tree, or render an error.
class GenUiNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async => null;

  Future<void> submit(String prompt) async {
    if (prompt.trim().isEmpty) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final profile = ref.read(userProfileProvider).value;
      final ctx = <String, dynamic>{
        if (profile != null) ...{
          'university': profile.university,
          'course': profile.course,
          'branch': profile.branch,
          'sem': profile.sem,
        },
      };
      return await ref.read(aiServiceProvider).generateUIResponse(
            prompt: prompt,
            context: ctx,
          );
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final genUiProvider =
    AsyncNotifierProvider<GenUiNotifier, Map<String, dynamic>?>(
  GenUiNotifier.new,
);
