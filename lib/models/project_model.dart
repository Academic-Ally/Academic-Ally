import 'package:cloud_firestore/cloud_firestore.dart';

import 'ai_models.dart';

/// A user's project, stored at `Users/{uid}/Projects/{projectId}`.
///
/// `cachedGuidance` is a map from phase wire name (ideation, litReview,
/// scaffolding, report) to the last `ProjectGuidance` returned for that
/// phase, so the UI can render instantly without re-calling the AI.
class ProjectModel {
  final String id;
  final String title;
  final String brief;
  final String type; // 'major' | 'minor'
  final DateTime? createdAt;
  final Map<String, ProjectGuidance> cachedGuidance;

  const ProjectModel({
    required this.id,
    required this.title,
    required this.brief,
    required this.type,
    this.createdAt,
    this.cachedGuidance = const {},
  });

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final raw = d['cachedGuidance'] as Map<String, dynamic>? ?? const {};
    final guidance = <String, ProjectGuidance>{};
    raw.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        guidance[key] = _guidanceFromMap(value);
      }
    });
    return ProjectModel(
      id: doc.id,
      title: d['title'] ?? '',
      brief: d['brief'] ?? '',
      type: d['type'] ?? 'major',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      cachedGuidance: guidance,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'brief': brief,
        'type': type,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'cachedGuidance': cachedGuidance.map((k, v) => MapEntry(k, v.toMap())),
      };
}

ProjectGuidance _guidanceFromMap(Map<String, dynamic> m) => ProjectGuidance(
      phase: ProjectPhaseX.fromWire(m['phase'] as String?),
      summary: m['summary'] ?? '',
      bullets: List<String>.from(m['bullets'] ?? const []),
      nextSteps: List<String>.from(m['nextSteps'] ?? const []),
      references: List<String>.from(m['references'] ?? const []),
      codeSnippet: m['codeSnippet'],
    );
