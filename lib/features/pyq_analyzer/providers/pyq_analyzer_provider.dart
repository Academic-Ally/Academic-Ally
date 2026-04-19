import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/providers/ai_provider.dart';
import '../../../models/ai_models.dart';
import '../../auth/providers/auth_provider.dart';

/// Subject the user currently has selected in the PYQ screen picker.
class SelectedPyqSubjectNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? subject) => state = subject;
}

final selectedPyqSubjectProvider =
    NotifierProvider<SelectedPyqSubjectNotifier, String?>(
  SelectedPyqSubjectNotifier.new,
);

/// Params needed to locate a PyqAnalysis doc. Using a record so the family
/// provider keys on all 5 fields without a custom equality class.
typedef PyqKey = ({
  String university,
  String course,
  String branch,
  String sem,
  String subject,
});

/// Streams a cached PyqAnalysis doc if one exists. Returns null when the
/// doc is absent so the UI can show a "run analysis" state.
final cachedPyqAnalysisProvider =
    StreamProvider.family<PyqAnalysis?, PyqKey>((ref, key) {
  return FirebaseFirestore.instance
      .doc(FirestorePaths.pyqAnalysis(
        key.university,
        key.course,
        key.branch,
        key.sem,
        key.subject,
      ))
      .snapshots()
      .map((doc) => doc.exists ? PyqAnalysis.fromFirestore(doc) : null);
});

/// Triggers an analysis run via [AIService.analyzePyq]. The mock fetches
/// all existing QuestionPapers resources for the subject so the real impl
/// (Phase 4) has a real corpus to parse.
class PyqAnalyzerNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> runAnalysis({
    required String university,
    required String course,
    required String branch,
    required String sem,
    required String subject,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(currentUserProvider)?.uid;
      if (uid == null) {
        throw StateError('Must be signed in to run analysis.');
      }
      final pyqIds = await _fetchPyqResourceIds(
        university: university,
        course: course,
        branch: branch,
        sem: sem,
        subject: subject,
      );
      await ref.read(aiServiceProvider).analyzePyq(
            university: university,
            course: course,
            branch: branch,
            sem: sem,
            subject: subject,
            pyqResourceIds: pyqIds,
          );
    });
  }

  /// Best-effort lookup of existing question-paper resource IDs under the
  /// subject. Returns [] if the collection is empty or the query times out.
  Future<List<String>> _fetchPyqResourceIds({
    required String university,
    required String course,
    required String branch,
    required String sem,
    required String subject,
  }) async {
    try {
      final path = FirestorePaths.resources(
        university,
        course,
        branch,
        sem,
        AppConstants.questionPapers,
        subject,
      );
      final snap = await FirebaseFirestore.instance
          .collection(path)
          .limit(20)
          .get()
          .timeout(const Duration(seconds: 8));
      return snap.docs.map((d) => d.id).toList();
    } catch (_) {
      return const [];
    }
  }
}

final pyqAnalyzerProvider =
    AsyncNotifierProvider<PyqAnalyzerNotifier, void>(PyqAnalyzerNotifier.new);
