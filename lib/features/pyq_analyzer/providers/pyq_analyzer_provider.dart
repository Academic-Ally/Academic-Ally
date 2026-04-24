import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/providers/ai_provider.dart';
import '../../../core/services/ai/agent_ai_service.dart';
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

typedef PyqKey = ({
  String university,
  String course,
  String branch,
  String sem,
  String subject,
});

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

/// State for an in-flight analyzer run — exposes runId to the UI so it
/// can subscribe to AnalysisRuns/{runId} for the progress tracker.
class PyqRunState {
  final String? runId;
  final bool isLoading;
  final Object? error;

  const PyqRunState({this.runId, this.isLoading = false, this.error});

  PyqRunState copyWith({String? runId, bool? isLoading, Object? error}) =>
      PyqRunState(
        runId: runId ?? this.runId,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );

  static const initial = PyqRunState();
}

class PyqAnalyzerNotifier extends Notifier<PyqRunState> {
  @override
  PyqRunState build() => PyqRunState.initial;

  Future<void> runAnalysis({
    required String university,
    required String course,
    required String branch,
    required String sem,
    required String subject,
  }) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      state = state.copyWith(error: StateError('Must be signed in.'));
      return;
    }
    final runId = const Uuid().v4();
    state = PyqRunState(runId: runId, isLoading: true);
    try {
      final pyqIds = await _fetchPyqResourceIds(
        university: university,
        course: course,
        branch: branch,
        sem: sem,
        subject: subject,
      );

      final service = ref.read(aiServiceProvider);
      if (service is AgentAIService) {
        await service.analyzePyqWithRunId(
          runId: runId,
          university: university,
          course: course,
          branch: branch,
          sem: sem,
          subject: subject,
          pyqResourceIds: pyqIds,
        );
      } else {
        await service.analyzePyq(
          university: university,
          course: course,
          branch: branch,
          sem: sem,
          subject: subject,
          pyqResourceIds: pyqIds,
        );
      }
      state = PyqRunState(runId: runId, isLoading: false);
    } catch (exc) {
      state = PyqRunState(runId: runId, isLoading: false, error: exc);
    }
  }

  void reset() {
    state = PyqRunState.initial;
  }

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
    NotifierProvider<PyqAnalyzerNotifier, PyqRunState>(
  PyqAnalyzerNotifier.new,
);
