import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/ai_provider.dart';
import '../../../core/services/ai/agent_ai_service.dart';
import '../../../models/ai_models.dart';

/// Subject the user currently has selected in the examiner picker.
class SelectedExaminerSubjectNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? subject) => state = subject;
}

final selectedExaminerSubjectProvider =
    NotifierProvider<SelectedExaminerSubjectNotifier, String?>(
  SelectedExaminerSubjectNotifier.new,
);

/// State for an in-flight examiner run.
class ExaminerRunState {
  final String? runId;
  final bool isLoading;
  final AdversarialExam? result;
  final Object? error;

  const ExaminerRunState({
    this.runId,
    this.isLoading = false,
    this.result,
    this.error,
  });

  ExaminerRunState copyWith({
    String? runId,
    bool? isLoading,
    AdversarialExam? result,
    Object? error,
  }) =>
      ExaminerRunState(
        runId: runId ?? this.runId,
        isLoading: isLoading ?? this.isLoading,
        result: result ?? this.result,
        error: error,
      );

  static const initial = ExaminerRunState();
}

class AdversarialExaminerNotifier extends Notifier<ExaminerRunState> {
  @override
  ExaminerRunState build() => ExaminerRunState.initial;

  Future<void> runExam({
    required String university,
    required String course,
    required String branch,
    required String sem,
    required String subject,
    int questionCount = 6,
  }) async {
    final runId = const Uuid().v4();
    state = ExaminerRunState(runId: runId, isLoading: true);
    try {
      final service = ref.read(aiServiceProvider);
      AdversarialExam exam;
      if (service is AgentAIService) {
        final res = await service.generateAdversarialExamWithRunId(
          runId: runId,
          university: university,
          course: course,
          branch: branch,
          sem: sem,
          subject: subject,
          questionCount: questionCount,
        );
        exam = res.exam;
      } else {
        exam = await service.generateAdversarialExam(
          university: university,
          course: course,
          branch: branch,
          sem: sem,
          subject: subject,
          questionCount: questionCount,
        );
      }
      state = ExaminerRunState(runId: runId, isLoading: false, result: exam);
    } catch (exc) {
      state = ExaminerRunState(runId: runId, isLoading: false, error: exc);
    }
  }

  void reset() => state = ExaminerRunState.initial;
}

final adversarialExaminerProvider =
    NotifierProvider<AdversarialExaminerNotifier, ExaminerRunState>(
  AdversarialExaminerNotifier.new,
);

/// Default subject suggestions for the picker — pulled from the user's
/// curriculum via the same provider PYQ Analyzer uses. Re-exported here
/// for symmetry, but consumers can use the resources_provider directly
/// if they prefer.
typedef ExaminerSubjectKey = ({
  String university,
  String course,
  String branch,
  String sem,
  String subject,
});
