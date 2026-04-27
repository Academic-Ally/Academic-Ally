import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/adversarial_examiner/providers/adversarial_examiner_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/gen_ui/providers/gen_ui_provider.dart';
import '../../features/misconception_graph/providers/misconception_graph_provider.dart';
import '../../features/pyq_analyzer/providers/pyq_analyzer_provider.dart';
import '../../features/snap_doubt/providers/snap_doubt_provider.dart';
import '../../features/study_planner/providers/study_planner_provider.dart';
import '../../features/upload/providers/upload_provider.dart';

/// Resets every user-scoped Notifier whenever the signed-in user changes.
///
/// None of the AI feature notifiers are `autoDispose`, so without this hook
/// they keep state across a logout → login cycle. The most visible failure
/// is a fresh AI run (PYQ, Study Planner, etc.) doing nothing because the
/// provider is still holding the previous run's `error` or a stale subject
/// selection from the previous user's curriculum. Hot-restart "fixed" it
/// only because hot-restart wipes every provider.
///
/// Activate by `ref.watch(authInvalidatorProvider)` once from a top-level
/// widget (see `main.dart`).
final authInvalidatorProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
    // Skip the very first emission — providers are at their initial state
    // on app boot, nothing to invalidate.
    if (previous == null) return;

    final prevUid = previous.value?.uid;
    final newUid = next.value?.uid;
    if (prevUid == newUid) return;

    // User changed (logout, login, or account switch). Reset every
    // user-scoped notifier so the new session starts clean.
    ref.invalidate(selectedPyqSubjectProvider);
    ref.invalidate(pyqAnalyzerProvider);
    ref.invalidate(selectedExaminerSubjectProvider);
    ref.invalidate(adversarialExaminerProvider);
    ref.invalidate(selectedDoubtSubjectProvider);
    ref.invalidate(doubtSolverProvider);
    ref.invalidate(studyPlanCreatorProvider);
    ref.invalidate(uploadProvider);
    // Hidden features — invalidate defensively in case they're re-enabled.
    ref.invalidate(selectedKnowledgeSubjectProvider);
    ref.invalidate(practiceProvider);
    ref.invalidate(genUiProvider);
  });
});
