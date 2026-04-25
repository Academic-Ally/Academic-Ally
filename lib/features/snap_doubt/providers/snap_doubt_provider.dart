import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/providers/ai_provider.dart';
import '../../../core/services/ai/agent_ai_service.dart';
import '../../../models/ai_models.dart';
import '../../auth/providers/auth_provider.dart';

/// Stream of the user's doubt history, newest first.
final doubtHistoryProvider = StreamProvider<List<DoubtSolution>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);

  return FirebaseFirestore.instance
      .collection(FirestorePaths.userDoubtHistory(user.uid))
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => DoubtSolution.fromFirestore(d)).toList());
});

/// Subject the user has selected for the next doubt.
class SelectedDoubtSubjectNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? subject) => state = subject;
}

final selectedDoubtSubjectProvider =
    NotifierProvider<SelectedDoubtSubjectNotifier, String?>(
  SelectedDoubtSubjectNotifier.new,
);

/// State for an in-flight Snap-a-Doubt run, exposing run_id so the UI
/// can subscribe to AnalysisRuns/{runId} for the live agent checkmarks.
class DoubtRunState {
  final String? runId;
  final bool isLoading;
  final DoubtSolution? result;
  final Object? error;

  const DoubtRunState({
    this.runId,
    this.isLoading = false,
    this.result,
    this.error,
  });

  static const initial = DoubtRunState();
}

class DoubtSolverNotifier extends Notifier<DoubtRunState> {
  @override
  DoubtRunState build() => DoubtRunState.initial;

  Future<void> solve({
    required String imagePath,
    required String subject,
  }) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      state = DoubtRunState(error: StateError('Must be signed in.'));
      return;
    }
    final profile = ref.read(userProfileProvider).value;
    if (profile == null) {
      state = DoubtRunState(error: StateError('Profile not loaded yet.'));
      return;
    }
    final runId = const Uuid().v4();
    state = DoubtRunState(runId: runId, isLoading: true);
    try {
      final service = ref.read(aiServiceProvider);
      DoubtSolution solution;
      if (service is AgentAIService) {
        final res = await service.solveDoubtFromImageWithRunId(
          runId: runId,
          uid: uid,
          imagePath: imagePath,
          subject: subject,
          university: profile.university,
          course: profile.course,
          branch: profile.branch,
          sem: profile.sem,
        );
        solution = res.solution;
      } else {
        solution = await service.solveDoubtFromImage(
          uid: uid,
          imagePath: imagePath,
          subject: subject,
          university: profile.university,
          course: profile.course,
          branch: profile.branch,
          sem: profile.sem,
        );
      }
      state = DoubtRunState(runId: runId, isLoading: false, result: solution);
    } catch (exc) {
      state = DoubtRunState(runId: runId, isLoading: false, error: exc);
    }
  }

  void reset() {
    state = DoubtRunState.initial;
  }
}

final doubtSolverProvider =
    NotifierProvider<DoubtSolverNotifier, DoubtRunState>(
  DoubtSolverNotifier.new,
);

/// Deletes a doubt from the user's history.
Future<void> deleteDoubt({
  required String uid,
  required String doubtId,
}) async {
  await FirebaseFirestore.instance
      .doc(FirestorePaths.userDoubt(uid, doubtId))
      .delete();
}
