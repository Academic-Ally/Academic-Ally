import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../models/seekhub_request_model.dart';
import '../../auth/providers/auth_provider.dart';

final _firestore = FirebaseFirestore.instance;

/// Stream of SeekHub requests for the current user's university/course.
final seekHubRequestsProvider =
    StreamProvider<List<SeekHubRequestModel>>((ref) {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) return Stream.value([]);

  return _firestore
      .collection(FirestorePaths.seekHub(user.university, user.course))
      .orderBy('requestedOn', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => SeekHubRequestModel.fromFirestore(doc))
          .toList());
});

/// Only pending requests.
final pendingRequestsProvider = Provider<List<SeekHubRequestModel>>((ref) {
  final all = ref.watch(seekHubRequestsProvider).value ?? [];
  return all.where((r) => r.isPending).toList();
});

class SeekHubService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new resource request.
  Future<void> createRequest({
    required String seekerName,
    required String seekerUid,
    String? seekerPhoto,
    required String subject,
    required String category,
    required String sem,
    required String branch,
    required String course,
    required String university,
  }) async {
    final id = const Uuid().v4();
    final request = SeekHubRequestModel(
      id: id,
      subject: subject,
      category: category,
      seekerName: seekerName,
      seekerUid: seekerUid,
      seekerPhoto: seekerPhoto,
      sem: sem,
      branch: branch,
      course: course,
      university: university,
      status: 'pending',
      notifyList: [],
    );

    await _firestore
        .doc(FirestorePaths.seekHubRequest(university, course, id))
        .set(request.toFirestore());

    // Also store in user's SeekHub subcollection
    final userRequestsRef =
        _firestore.doc(FirestorePaths.userSeekHubRequests(seekerUid));
    final userRequestsDoc = await userRequestsRef.get();
    if (userRequestsDoc.exists) {
      await userRequestsRef.update({
        'requests': FieldValue.arrayUnion([id]),
      });
    } else {
      await userRequestsRef.set({
        'requests': [id],
      });
    }
  }

  /// Subscribe to notifications for a request.
  Future<void> subscribeToRequest({
    required String university,
    required String course,
    required String requestId,
    required String uid,
  }) async {
    await _firestore
        .doc(FirestorePaths.seekHubRequest(university, course, requestId))
        .update({
      'notifyList': FieldValue.arrayUnion([uid]),
    });
  }

  /// Unsubscribe from a request.
  Future<void> unsubscribeFromRequest({
    required String university,
    required String course,
    required String requestId,
    required String uid,
  }) async {
    await _firestore
        .doc(FirestorePaths.seekHubRequest(university, course, requestId))
        .update({
      'notifyList': FieldValue.arrayRemove([uid]),
    });
  }
}

final seekHubServiceProvider = Provider<SeekHubService>((ref) {
  return SeekHubService();
});
