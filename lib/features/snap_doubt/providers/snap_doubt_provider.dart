import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/providers/ai_provider.dart';
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

/// Submits an image to [AIService.solveDoubtFromImage] and returns the
/// resulting solution. Phase 2 uses the local file path as the "URL" since
/// the mock ignores the actual bytes; Phase 4 will upload to Storage first.
class DoubtSolverNotifier extends AsyncNotifier<DoubtSolution?> {
  @override
  Future<DoubtSolution?> build() async => null;

  Future<void> solve({
    required String imagePath,
    String? subjectHint,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(currentUserProvider)?.uid;
      if (uid == null) {
        throw StateError('Must be signed in to ask a doubt.');
      }
      return await ref.read(aiServiceProvider).solveDoubtFromImage(
            uid: uid,
            imageUrl: imagePath,
            subjectHint: subjectHint,
          );
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final doubtSolverProvider =
    AsyncNotifierProvider<DoubtSolverNotifier, DoubtSolution?>(
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
