import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../constants/firestore_paths.dart';

/// FCM integration service.
///
/// Handles:
///  - runtime notification permission (iOS + Android 13+)
///  - FCM token lifecycle (initial fetch, persist to Users/{uid}.fcmToken, refresh)
///  - topic subscription matching the user's {university}_{course}_{branch}_{sem}
///  - cleanup on logout
class FcmService {
  FcmService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  /// Hard ceiling on any FCM call so a broken Play Services install on an
  /// emulator (or no network) can never block app startup.
  static const Duration _fcmCallTimeout = Duration(seconds: 5);

  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          )
          .timeout(_fcmCallTimeout);
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Fetch the current FCM token and persist it to the user's Firestore doc.
  ///
  /// Critical idempotency rule: if the current token matches `storedToken`,
  /// we do not write — otherwise every listener run would bump lastUpdated,
  /// re-emit the Users/{uid} stream, and retrigger the listener → loop.
  Future<String?> syncToken(String uid, {String? storedToken}) async {
    try {
      if (Platform.isIOS) {
        await _messaging.getAPNSToken().timeout(_fcmCallTimeout);
      }
      final token = await _messaging.getToken().timeout(_fcmCallTimeout);
      if (token == null) return null;
      if (token == storedToken) return token; // no-op — already stored

      await _firestore.doc(FirestorePaths.user(uid)).update({
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return token;
    } catch (_) {
      return null;
    }
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Build the canonical topic string for a given curriculum tuple.
  ///
  /// FCM topic names must match `[a-zA-Z0-9-_.~%]+` — branches like
  /// "CSE AIML" or "CSE IOT" would produce invalid topics if concatenated
  /// verbatim, so every character outside the allowed set becomes a hyphen.
  static String buildTopic({
    required String university,
    required String course,
    required String branch,
    required String sem,
  }) {
    final raw =
        FirestorePaths.notificationTopic(university, course, branch, sem);
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9_.~%\-]'), '-');
  }

  Future<void> subscribeToTopic(String uid, String topic) async {
    if (topic.isEmpty) return;
    try {
      await _messaging.subscribeToTopic(topic).timeout(_fcmCallTimeout);
    } catch (_) {/* best-effort */}
    await _firestore.doc(FirestorePaths.user(uid)).update({
      'subscribeArray': FieldValue.arrayUnion([topic]),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unsubscribeFromTopic(String uid, String topic) async {
    if (topic.isEmpty) return;
    try {
      await _messaging.unsubscribeFromTopic(topic).timeout(_fcmCallTimeout);
    } catch (_) {/* best-effort */}
    await _firestore.doc(FirestorePaths.user(uid)).update({
      'subscribeArray': FieldValue.arrayRemove([topic]),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Ensure the device is subscribed to exactly the topic matching the user's
  /// current curriculum, and unsubscribed from any stale topics recorded in
  /// `subscribeArray`.
  ///
  /// Fast path: if `currentSubscriptions == [desired]`, no I/O. Critical for
  /// loop prevention.
  Future<void> syncTopicsForProfile({
    required String uid,
    required String university,
    required String course,
    required String branch,
    required String sem,
    required List<String> currentSubscriptions,
  }) async {
    final desired = buildTopic(
      university: university,
      course: course,
      branch: branch,
      sem: sem,
    );
    if (desired.isEmpty) return;

    if (currentSubscriptions.length == 1 &&
        currentSubscriptions.first == desired) {
      return;
    }

    for (final stale in currentSubscriptions) {
      if (stale != desired && stale.isNotEmpty) {
        try {
          await unsubscribeFromTopic(uid, stale);
        } catch (_) {/* best-effort */}
      }
    }

    if (!currentSubscriptions.contains(desired)) {
      await subscribeToTopic(uid, desired);
    }
  }

  /// Called on logout. Clears the token from Firestore and unsubscribes from
  /// every known topic. Every FCM call has a 5s timeout so stale topics
  /// (e.g. `OU_BE_CSE AIML_4` with a space) can't freeze the UI.
  Future<void> clearForLogout({
    required String uid,
    required List<String> subscribedTopics,
  }) async {
    for (final topic in subscribedTopics) {
      if (topic.isNotEmpty) {
        try {
          await _messaging
              .unsubscribeFromTopic(topic)
              .timeout(_fcmCallTimeout);
        } catch (_) {/* best-effort */}
      }
    }
    try {
      await _firestore.doc(FirestorePaths.user(uid)).update({
        'fcmToken': null,
        'subscribeArray': <String>[],
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (_) {/* user may already be signed out; non-fatal */}
    try {
      await _messaging.deleteToken().timeout(_fcmCallTimeout);
    } catch (_) {/* non-fatal */}
  }

  Stream<RemoteMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage;

  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();
}
