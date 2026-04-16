import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update user profile fields.
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? college,
    String? branch,
    String? sem,
    String? pfp,
  }) async {
    final updates = <String, dynamic>{
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    if (name != null) updates['name'] = name;
    if (college != null) updates['college'] = college;
    if (branch != null) updates['branch'] = branch;
    if (sem != null) updates['sem'] = sem;
    if (pfp != null) updates['pfp'] = pfp;

    await _firestore.doc(FirestorePaths.user(uid)).update(updates);
  }
}

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});
