import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/providers/ai_provider.dart';
import '../../../models/ai_models.dart';
import '../../auth/providers/auth_provider.dart';

/// Subject chosen in the Knowledge Map screen (top-of-screen picker).
class SelectedKnowledgeSubjectNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? subject) {
    state = subject;
  }
}

final selectedKnowledgeSubjectProvider =
    NotifierProvider<SelectedKnowledgeSubjectNotifier, String?>(
  SelectedKnowledgeSubjectNotifier.new,
);

/// Client-generated knowledge nodes for a subject.
///
/// In Phase 4 these come from `KnowledgeGraph/{university}/{course}/{subject}
/// /nodes`. For Phase 2 we generate them client-side using a static topic
/// map that mirrors `MockAIService._topicsFor`, so the UI is testable without
/// needing write access to the `KnowledgeGraph` top-level collection (which
/// live Firestore rules deny today).
final knowledgeNodesProvider =
    Provider.family<List<KnowledgeNode>, String>((ref, subject) {
  return _topicsFor(subject)
      .map((topic) => KnowledgeNode(
            id: _slugify(topic),
            topic: topic,
            subject: subject,
          ))
      .toList();
});

/// Stream of the user's mastery scores, keyed by nodeId.
final userMasteryStreamProvider =
    StreamProvider<Map<String, MasteryScore>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const {});

  return FirebaseFirestore.instance
      .collection(FirestorePaths.userMasteryScores(user.uid))
      .snapshots()
      .map((snap) {
    final map = <String, MasteryScore>{};
    for (final doc in snap.docs) {
      map[doc.id] = MasteryScore.fromFirestore(doc);
    }
    return map;
  });
});

/// Stream of the user's misconceptions, keyed by nodeId.
final userMisconceptionsStreamProvider =
    StreamProvider<Map<String, Misconception>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const {});

  return FirebaseFirestore.instance
      .collection(FirestorePaths.userMisconceptions(user.uid))
      .snapshots()
      .map((snap) {
    final map = <String, Misconception>{};
    for (final doc in snap.docs) {
      map[doc.id] = Misconception.fromFirestore(doc);
    }
    return map;
  });
});

// -----------------------------------------------------------------------------
// Practice session
// -----------------------------------------------------------------------------

class PracticeResult {
  final bool wasCorrect;
  final MasteryScore mastery;
  final List<Misconception> newMisconceptions;

  const PracticeResult({
    required this.wasCorrect,
    required this.mastery,
    required this.newMisconceptions,
  });
}

/// Submits a practice answer through the AI service, persists any tagged
/// misconceptions under `Users/{uid}/Misconceptions/{nodeId}`, and returns
/// the updated mastery + misconception list.
class PracticeNotifier extends AsyncNotifier<PracticeResult?> {
  @override
  Future<PracticeResult?> build() async => null;

  Future<void> submit({
    required KnowledgeNode node,
    required String questionText,
    required String userAnswer,
    required String correctAnswer,
    required bool treatAsCorrect,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final uid = ref.read(currentUserProvider)?.uid;
      if (uid == null) {
        throw StateError('Must be signed in to practice.');
      }
      final ai = ref.read(aiServiceProvider);

      final mastery = await ai.updateMastery(
        uid: uid,
        nodeId: node.id,
        wasCorrect: treatAsCorrect,
      );

      // Tag misconceptions only on incorrect answers (consistent with how
      // the Gemini-backed impl will need to work — tagging a correct answer
      // is wasteful).
      final newMisconceptions = <Misconception>[];
      if (!treatAsCorrect) {
        final tagged = await ai.tagMisconceptions(
          subject: node.subject,
          topic: node.topic,
          questionText: questionText,
          userAnswer: userAnswer,
          correctAnswer: correctAnswer,
        );
        for (final m in tagged) {
          final docRef = FirebaseFirestore.instance
              .doc(FirestorePaths.userMisconception(uid, m.nodeId));
          await docRef.set(m.toMap());
          newMisconceptions.add(m);
        }
      }

      return PracticeResult(
        wasCorrect: treatAsCorrect,
        mastery: mastery,
        newMisconceptions: newMisconceptions,
      );
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final practiceProvider =
    AsyncNotifierProvider<PracticeNotifier, PracticeResult?>(
  PracticeNotifier.new,
);

// -----------------------------------------------------------------------------
// Static topic map (mirrors MockAIService._topicsFor for UI consistency).
// -----------------------------------------------------------------------------

List<String> _topicsFor(String subject) {
  switch (subject.toLowerCase()) {
    case 'data structures':
    case 'ds':
      return const [
        'Arrays & Linked Lists',
        'Stacks & Queues',
        'Trees',
        'Graphs',
        'Hashing',
      ];
    case 'dbms':
      return const [
        'ER Model',
        'Normalization',
        'SQL & Relational Algebra',
        'Transactions',
        'Indexing',
      ];
    case 'operating systems':
    case 'os':
      return const [
        'Process Management',
        'Scheduling',
        'Memory Management',
        'File Systems',
        'Concurrency & Deadlocks',
      ];
    case 'computer networks':
    case 'cn':
      return const [
        'OSI & TCP/IP',
        'Data Link Layer',
        'Network Layer',
        'Transport Layer',
        'Application Layer',
      ];
    default:
      return const [
        'Unit 1: Foundations',
        'Unit 2: Core Concepts',
        'Unit 3: Applications',
        'Unit 4: Advanced Topics',
        'Unit 5: Case Studies',
      ];
  }
}

String _slugify(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
