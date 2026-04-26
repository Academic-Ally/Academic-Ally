import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../auth/providers/auth_provider.dart';

final _firestore = FirebaseFirestore.instance;
final _storage = FirebaseStorage.instance;

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

  /// Upload a PDF to Firebase Storage and create matching Firestore docs:
  ///   - `Universities/.../{type}/{subject}/{auto-id}`  → so the resource
  ///     immediately appears in the app's resource list
  ///   - `NewUploads/{uni}/{course}/{branch}/uploads/{auto-id}` → moderation
  ///     queue / admin visibility
  ///   - `Users/{uid}/UserUploads/{auto-id}`            → user's own history
  ///
  /// Returns true on success, false otherwise. Sets `state.error` on failure.
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
      if (user == null) {
        throw Exception('You must be logged in to upload.');
      }

      final file = File(filePath);
      if (filePath.isEmpty || !file.existsSync()) {
        throw Exception('Please select a PDF file first.');
      }

      // Sanitize filename — keep readability but drop characters that
      // would break a Storage path. The uploadId prefix prevents
      // collisions when two users upload files with the same name.
      final originalName = filePath.split(RegExp(r'[\\/]')).last;
      final safeName = originalName.replaceAll(RegExp(r'[^\w\-. ]+'), '_');
      final uploadId = const Uuid().v4();
      final storageId =
          'Resources/$university/$course/$branch/$sem/$category/$subject/'
          '${uploadId}_$safeName';

      // Stream the file to Storage and bridge progress events to UI.
      final ref0 = _storage.ref(storageId);
      final task = ref0.putFile(
        file,
        SettableMetadata(contentType: 'application/pdf'),
      );

      task.snapshotEvents.listen((snap) {
        if (snap.totalBytes <= 0) return;
        final p = snap.bytesTransferred / snap.totalBytes;
        // Cap at 0.95 — final 5% reserved for the Firestore writes below.
        state = state.copyWith(progress: (p * 0.95).clamp(0.0, 0.95));
      });

      await task;

      final sizeBytes = await file.length();
      final sizeMB = (sizeBytes / (1024 * 1024)).toStringAsFixed(2);

      final doc = {
        'name': name,
        'subject': subject,
        'category': category,
        'university': university,
        'course': course,
        'branch': branch,
        'sem': sem,
        'storageId': storageId,
        'units': units,
        'rating': 0,
        'views': 0,
        'size': double.parse(sizeMB),
        'uploaderId': user.uid,
        'uploaderName': user.name,
        'uploaderEmail': user.email,
        'pfp': user.pfp,
        'date': FieldValue.serverTimestamp(),
      };

      // Three writes in parallel — the file's already in Storage, only
      // index entries to write. Failure to write any one of them shouldn't
      // strand the binary, but the user-visible resource entry is the
      // priority, so write that first and let the others race.
      final resourcesPath = FirestorePaths.resources(
        university,
        course,
        branch,
        sem,
        category,
        subject,
      );
      await _firestore.collection(resourcesPath).add(doc);

      await Future.wait([
        _firestore
            .collection(FirestorePaths.newUploads(university, course, branch))
            .add(doc),
        _firestore
            .collection(FirestorePaths.userUploads(user.uid))
            .add(doc),
      ]);

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
