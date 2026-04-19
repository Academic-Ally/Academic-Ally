import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/providers/ai_provider.dart';
import '../../../models/ai_models.dart';
import '../../../models/project_model.dart';
import '../../auth/providers/auth_provider.dart';

/// Stream of the user's projects, newest first.
final userProjectsProvider = StreamProvider<List<ProjectModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);

  return FirebaseFirestore.instance
      .collection(FirestorePaths.userProjects(user.uid))
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => ProjectModel.fromFirestore(d)).toList());
});

/// Single project stream — the detail screen subscribes here so newly-cached
/// guidance flows back into the UI without manual refresh.
final projectDetailProvider =
    StreamProvider.family<ProjectModel?, String>((ref, projectId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .doc(FirestorePaths.userProject(user.uid, projectId))
      .snapshots()
      .map((doc) => doc.exists ? ProjectModel.fromFirestore(doc) : null);
});

/// Creates a project doc. Returns the new project ID.
Future<String?> createProject({
  required String uid,
  required String title,
  required String brief,
  required String type,
}) async {
  final ref = FirebaseFirestore.instance
      .collection(FirestorePaths.userProjects(uid))
      .doc();
  final project = ProjectModel(
    id: ref.id,
    title: title,
    brief: brief,
    type: type,
    createdAt: DateTime.now(),
  );
  await ref.set(project.toMap());
  return ref.id;
}

Future<void> deleteProject({
  required String uid,
  required String projectId,
}) async {
  await FirebaseFirestore.instance
      .doc(FirestorePaths.userProject(uid, projectId))
      .delete();
}

/// Requests guidance for a phase via AIService and caches it on the project
/// doc under `cachedGuidance.{phase.wire}`. The detail screen's stream picks
/// up the change and renders. Caller is responsible for tracking per-phase
/// loading state (Project Copilot UI uses a local map for this).
Future<void> requestPhaseGuidance({
  required WidgetRef ref,
  required ProjectModel project,
  required ProjectPhase phase,
}) async {
  final uid = ref.read(currentUserProvider)?.uid;
  if (uid == null) {
    throw StateError('Must be signed in to use Project Copilot.');
  }

  final guidance = await ref.read(aiServiceProvider).getProjectGuidance(
        uid: uid,
        projectId: project.id,
        phase: phase,
        projectContext: {
          'title': project.title,
          'brief': project.brief,
          'type': project.type,
        },
      );

  await FirebaseFirestore.instance
      .doc(FirestorePaths.userProject(uid, project.id))
      .update({
    'cachedGuidance.${phase.wire}': guidance.toMap(),
  });
}
