import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live snapshot of an AnalysisRuns/{runId} document. Drives the
/// progressive loading UI (agent checkmarks).
class AnalysisRun {
  final String runId;
  final String status;
  final String subject;
  final Map<String, String> agents;
  final String? errorMessage;

  const AnalysisRun({
    required this.runId,
    required this.status,
    required this.subject,
    required this.agents,
    this.errorMessage,
  });

  factory AnalysisRun.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    final rawAgents = (data['agents'] as Map<String, dynamic>?) ?? const {};
    return AnalysisRun(
      runId: doc.id,
      status: data['status'] as String? ?? 'running',
      subject: data['subject'] as String? ?? '',
      agents: rawAgents.map((k, v) => MapEntry(k, v as String)),
      errorMessage: data['errorMessage'] as String?,
    );
  }

  bool get isRunning => status == 'running';
  bool get isComplete => status == 'complete';
  bool get isFailed => status == 'failed' || status == 'timeout';

  bool isDone(String agentName) => agents[agentName] == 'done';
  bool isFailedAgent(String agentName) => agents[agentName] == 'failed';
}

/// Streams an AnalysisRuns/{runId} doc in real time. The param is the
/// runId string. Returns null while the doc doesn't exist yet.
final analysisRunProvider =
    StreamProvider.family<AnalysisRun?, String>((ref, runId) {
  return FirebaseFirestore.instance
      .doc('AnalysisRuns/$runId')
      .snapshots()
      .map((doc) => doc.exists ? AnalysisRun.fromFirestore(doc) : null);
});
