import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/providers/ai_provider.dart';
import '../../../models/ai_models.dart';
import '../../auth/providers/auth_provider.dart';

/// Stream of the current user's study plans, newest first.
final userStudyPlansProvider = StreamProvider<List<StudyPlan>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);

  return FirebaseFirestore.instance
      .collection(FirestorePaths.userStudyPlans(user.uid))
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => StudyPlan.fromFirestore(d)).toList());
});

/// Stream of a single study plan by ID.
final studyPlanDetailProvider =
    StreamProvider.family<StudyPlan?, String>((ref, planId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .doc(FirestorePaths.userStudyPlan(user.uid, planId))
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return StudyPlan.fromFirestore(doc);
  });
});

/// Generates a new study plan via [AIService.generateStudyPlan] (mocked in
/// Phase 2). The mock writes the plan to Firestore; we return the new plan
/// ID so the UI can navigate to its detail screen.
class StudyPlanCreator extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<String?> generate({
    required DateTime examDate,
    required List<String> subjects,
    required int dailyStudyMinutes,
    List<String> weakTopics = const [],
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final uid = ref.read(currentUserProvider)?.uid;
      if (uid == null) {
        throw StateError('Must be signed in to create a study plan.');
      }
      final profile = ref.read(userProfileProvider).value;
      if (profile == null) {
        throw StateError('Profile not loaded yet.');
      }

      final plan = await ref.read(aiServiceProvider).generateStudyPlan(
            uid: uid,
            examDate: examDate,
            subjects: subjects,
            branch: profile.branch,
            sem: profile.sem,
            weakTopics: weakTopics,
            dailyStudyMinutes: dailyStudyMinutes,
          );
      return plan.id;
    });
    state = result;
    return result.value;
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final studyPlanCreatorProvider =
    AsyncNotifierProvider<StudyPlanCreator, String?>(StudyPlanCreator.new);

/// Toggles a single task's completion on a plan document. Writes the whole
/// `days` array back because Firestore can't update a nested index in a
/// list without a read-modify-write cycle anyway.
Future<void> toggleStudyTaskCompletion({
  required String uid,
  required StudyPlan plan,
  required int dayIndex,
  required int taskIndex,
}) async {
  final updatedDays = <StudyDay>[];
  for (var d = 0; d < plan.days.length; d++) {
    if (d != dayIndex) {
      updatedDays.add(plan.days[d]);
      continue;
    }
    final day = plan.days[d];
    final updatedTasks = <StudyTask>[];
    for (var t = 0; t < day.tasks.length; t++) {
      if (t != taskIndex) {
        updatedTasks.add(day.tasks[t]);
        continue;
      }
      updatedTasks.add(day.tasks[t].copyWith(completed: !day.tasks[t].completed));
    }
    updatedDays.add(StudyDay(date: day.date, tasks: updatedTasks));
  }

  await FirebaseFirestore.instance
      .doc(FirestorePaths.userStudyPlan(uid, plan.id))
      .update({
    'days': updatedDays.map((d) => d.toMap()).toList(),
  });
}

/// Deletes a plan doc. Used from the list screen's long-press dismiss.
Future<void> deleteStudyPlan({
  required String uid,
  required String planId,
}) async {
  await FirebaseFirestore.instance
      .doc(FirestorePaths.userStudyPlan(uid, planId))
      .delete();
}
