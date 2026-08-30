import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../models/resource_model.dart';
import '../../../models/subject_model.dart';
import '../../auth/providers/auth_provider.dart';

final _firestore = FirebaseFirestore.instance;

/// Fetches the full subject list for the current user's university/course.
final subjectsListProvider = FutureProvider<List<SubjectModel>>((ref) async {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) return [];

  final doc = await _firestore
      .doc(FirestorePaths.queryList(user.university, user.course))
      .get();

  if (!doc.exists) return [];
  final data = doc.data() as Map<String, dynamic>;
  final list = (data['list'] as List<dynamic>?) ?? [];

  return list
      .map((item) => SubjectModel.fromMap(item as Map<String, dynamic>))
      .toList();
});

/// Fetches recommended subjects for the current user (matching their branch + sem).
final recommendedSubjectsProvider = FutureProvider<List<SubjectModel>>((
  ref,
) async {
  final allSubjects = await ref.watch(subjectsListProvider.future);
  final user = ref.watch(userProfileProvider).value;
  if (user == null) return [];

  return allSubjects
      .where((s) => s.branch == user.branch && s.sem == user.sem)
      .toList();
});

/// Provider family to fetch resource availability flags for a subject.
/// Returns a Map like { "Notes": true, "QuestionPapers": false, ... }
final subjectResourceFlagsProvider =
    FutureProvider.family<
      Map<String, bool>,
      ({
        String university,
        String course,
        String branch,
        String sem,
        String subject,
      })
    >((ref, params) async {
      // The SubjectsList doc has subject names as keys with boolean flags
      final path = FirestorePaths.universityBase(
        params.university,
        params.course,
        params.branch,
        params.sem,
      );

      // Check each resource type collection for documents that have a
      // ``storageId``. ``orderBy(field)`` skips docs missing that field, so
      // we get a free "non-null storageId" filter without an explicit where.
      final flags = <String, bool>{};
      for (final type in AppConstants.resourceTypes) {
        final snapshot = await _firestore
            .collection('$path/$type/${params.subject}')
            .orderBy('storageId')
            .limit(1)
            .get();
        flags[type] = snapshot.docs.isNotEmpty;
      }
      return flags;
    });

/// Fetches resources of a specific type for a subject.
///
/// Filters out legacy docs (Phase 0 React Native era) that don't have a
/// ``storageId`` — those used Google Drive download links which are no
/// longer reachable, so showing them in the UI just leads to the
/// "Storage not configured yet" dead end.
final resourcesProvider =
    FutureProvider.family<
      List<ResourceModel>,
      ({
        String university,
        String course,
        String branch,
        String sem,
        String resourceType,
        String subject,
      })
    >((ref, params) async {
      final path = FirestorePaths.resources(
        params.university,
        params.course,
        params.branch,
        params.sem,
        params.resourceType,
        params.subject,
      );

      // Firestore excludes documents missing an orderBy field. Querying by
      // storageId therefore omits the obsolete Drive-backed metadata before
      // deserialisation, so a malformed legacy value cannot crash the whole list.
      final snapshot = await _firestore
          .collection(path)
          .orderBy('storageId')
          .get();
      return snapshot.docs.map(ResourceModel.fromFirestore).toList();
    });

/// Increment view count for a resource.
Future<void> incrementViewCount({
  required String university,
  required String course,
  required String branch,
  required String sem,
  required String resourceType,
  required String subject,
  required String resourceId,
}) async {
  final path = FirestorePaths.resources(
    university,
    course,
    branch,
    sem,
    resourceType,
    subject,
  );
  await _firestore.doc('$path/$resourceId').update({
    'views': FieldValue.increment(1),
  });
}

/// Rate a resource.
Future<void> rateResource({
  required String uid,
  required String university,
  required String course,
  required String branch,
  required String sem,
  required String resourceType,
  required String subject,
  required String resourceId,
  required double rating,
}) async {
  final resourcePath = FirestorePaths.resources(
    university,
    course,
    branch,
    sem,
    resourceType,
    subject,
  );

  // Update the rating on the resource
  await _firestore.doc('$resourcePath/$resourceId').update({'rating': rating});

  // Store in user's rated list
  await _firestore.doc('${FirestorePaths.userRatedList(uid)}/$resourceId').set({
    'rating': rating,
    'ratedAt': FieldValue.serverTimestamp(),
  });
}
