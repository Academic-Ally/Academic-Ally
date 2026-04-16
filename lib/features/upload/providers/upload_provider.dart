import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../auth/providers/auth_provider.dart';

final _firestore = FirebaseFirestore.instance;

/// Upload state for tracking progress.
class UploadState {
  final bool isUploading;
  final double progress;
  final String? error;

  const UploadState({
    this.isUploading = false,
    this.progress = 0,
    this.error,
  });

  UploadState copyWith({bool? isUploading, double? progress, String? error}) {
    return UploadState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      error: error,
    );
  }
}

class UploadNotifier extends Notifier<UploadState> {
  @override
  UploadState build() => const UploadState();

  /// Submit upload metadata to Firestore NewUploads collection.
  /// The actual PDF file upload to R2 will be connected later.
  Future<bool> submitUpload({
    required String name,
    required String subject,
    required String category,
    required String university,
    required String course,
    required String branch,
    required String sem,
    required List<String> units,
    required String filePath,
  }) async {
    state = const UploadState(isUploading: true, progress: 0);

    try {
      final user = ref.read(userProfileProvider).value;
      if (user == null) throw Exception('Not logged in');

      final storageId = const Uuid().v4();

      // TODO: Upload actual PDF file to R2 storage here
      // For now, just save metadata to Firestore
      state = state.copyWith(progress: 0.5);

      final uploadData = {
        'name': name,
        'uploaderName': user.name,
        'uploaderEmail': user.email,
        'uploaderId': user.uid,
        'subject': subject,
        'category': category,
        'units': units,
        'pfp': user.pfp,
        'date': FieldValue.serverTimestamp(),
        'storageId': storageId,
        'university': university,
        'course': course,
        'branch': branch,
        'sem': sem,
      };

      // Save to NewUploads collection (pending review)
      final uploadsPath = FirestorePaths.newUploads(university, course, branch);
      await _firestore.collection(uploadsPath).add(uploadData);

      // Also save to user's uploads subcollection
      await _firestore
          .collection(FirestorePaths.userUploads(user.uid))
          .add(uploadData);

      state = const UploadState(isUploading: false, progress: 1);
      return true;
    } catch (e) {
      state = UploadState(isUploading: false, error: e.toString());
      return false;
    }
  }

  void resetState() {
    state = const UploadState();
  }
}

final uploadProvider =
    NotifierProvider<UploadNotifier, UploadState>(UploadNotifier.new);
