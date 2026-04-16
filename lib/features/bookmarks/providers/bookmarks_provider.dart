import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../models/resource_model.dart';
import '../../auth/providers/auth_provider.dart';

final _firestore = FirebaseFirestore.instance;

/// Stream of all bookmarked resources for the current user.
final bookmarksProvider = StreamProvider<List<ResourceModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  return _firestore
      .collection(FirestorePaths.userBookmarks(user.uid))
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => ResourceModel.fromFirestore(doc)).toList());
});

/// Check if a specific resource is bookmarked.
final isBookmarkedProvider =
    StreamProvider.family<bool, String>((ref, resourceId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(false);

  return _firestore
      .doc(FirestorePaths.userBookmark(user.uid, resourceId))
      .snapshots()
      .map((doc) => doc.exists);
});

class BookmarksService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Toggle bookmark for a resource.
  Future<bool> toggleBookmark({
    required String uid,
    required ResourceModel resource,
  }) async {
    final docRef =
        _firestore.doc(FirestorePaths.userBookmark(uid, resource.id));
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
      return false; // removed
    } else {
      await docRef.set(resource.toFirestore());
      return true; // added
    }
  }

  /// Remove a bookmark.
  Future<void> removeBookmark({
    required String uid,
    required String resourceId,
  }) async {
    await _firestore
        .doc(FirestorePaths.userBookmark(uid, resourceId))
        .delete();
  }
}

final bookmarksServiceProvider = Provider<BookmarksService>((ref) {
  return BookmarksService();
});
