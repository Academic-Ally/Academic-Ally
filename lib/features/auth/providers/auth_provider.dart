import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/providers/fcm_provider.dart';
import '../../../models/user_model.dart';

/// Stream of Firebase Auth state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Current Firebase user (nullable).
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

/// Current user's Firestore profile data.
final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .doc(FirestorePaths.user(user.uid))
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  });
});

/// Auth service for login, signup, etc.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String university,
    required String course,
    required String branch,
    required String sem,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(name);
    await credential.user?.sendEmailVerification();

    // Create user document in Firestore
    final userModel = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: email,
      university: university,
      course: course,
      branch: branch,
      sem: sem,
      year: '',
      college: '',
    );

    await _firestore
        .doc(FirestorePaths.user(credential.user!.uid))
        .set(userModel.toFirestore());

    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.doc(FirestorePaths.user(user.uid)).delete();
      await user.delete();
    }
  }
}

/// Full sign-out: FCM cleanup → Firebase Auth sign-out.
///
/// Use this wrapper instead of calling `AuthService.signOut()` directly so
/// the device stops receiving pushes before the auth session ends. Hard 8s
/// outer timeout on the FCM cleanup phase so logout cannot hang the UI.
/// If the wrapper throws for any reason, we still force the Firebase Auth
/// sign-out as a last resort so the user never gets stuck.
Future<void> performSignOut(WidgetRef ref) async {
  try {
    final profile = ref.read(userProfileProvider).value;
    if (profile != null) {
      try {
        await ref
            .read(fcmServiceProvider)
            .clearForLogout(
              uid: profile.uid,
              subscribedTopics: profile.subscribeArray,
            )
            .timeout(const Duration(seconds: 8));
      } catch (_) {/* best-effort — never block sign-out on FCM */}
    }
    await ref.read(authServiceProvider).signOut();
  } catch (_) {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {/* give up silently */}
  }
}

/// Full account deletion: FCM cleanup → Firestore user doc delete → Auth
/// user delete. Same best-effort semantics as `performSignOut`.
Future<void> performDeleteAccount(WidgetRef ref) async {
  try {
    final profile = ref.read(userProfileProvider).value;
    if (profile != null) {
      try {
        await ref
            .read(fcmServiceProvider)
            .clearForLogout(
              uid: profile.uid,
              subscribedTopics: profile.subscribeArray,
            )
            .timeout(const Duration(seconds: 8));
      } catch (_) {/* best-effort */}
    }
    await ref.read(authServiceProvider).deleteAccount();
  } catch (_) {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {/* give up silently */}
  }
}
