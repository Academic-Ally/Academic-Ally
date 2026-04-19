import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../services/fcm_service.dart';
import 'deep_link_provider.dart';

const _permissionAskedKey = 'fcm_permission_asked';

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService());

/// Watches the authenticated user's profile and keeps FCM in sync:
///  - requests permission on first post-auth launch
///  - persists the FCM token to Firestore
///  - subscribes/unsubscribes topics when branch/sem change
///  - listens for token refresh
class FcmSyncNotifier extends AsyncNotifier<void> {
  StreamSubscription<String>? _refreshSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  // Tracks the last Users/{uid} snapshot we successfully synced against,
  // so the listener can ignore emissions that represent our own writes
  // (fcmToken / subscribeArray / lastUpdated) and only re-sync when the
  // curriculum fields the user controls actually change. Without this
  // guard, every sync write retriggers the stream → listener → sync loop.
  String? _lastSyncedUid;
  String? _lastSyncedUniversity;
  String? _lastSyncedCourse;
  String? _lastSyncedBranch;
  String? _lastSyncedSem;

  @override
  Future<void> build() async {
    ref.keepAlive();
    ref.onDispose(() {
      _refreshSub?.cancel();
      _openedAppSub?.cancel();
    });

    _wireNotificationTaps();

    ref.listen(
      userProfileProvider,
      (previous, next) {
        final profile = next.value;
        if (profile == null) {
          _refreshSub?.cancel();
          _refreshSub = null;
          _lastSyncedUid = null;
          return;
        }

        if (_alreadySynced(profile)) return; // skip echo of our own write.

        _syncForProfile(profile);
      },
      fireImmediately: true,
    );
  }

  bool _alreadySynced(UserModel profile) {
    return _lastSyncedUid == profile.uid &&
        _lastSyncedUniversity == profile.university &&
        _lastSyncedCourse == profile.course &&
        _lastSyncedBranch == profile.branch &&
        _lastSyncedSem == profile.sem;
  }

  Future<void> _wireNotificationTaps() async {
    final service = ref.read(fcmServiceProvider);

    final initial = await service.getInitialMessage();
    if (initial != null) {
      _routeFromMessage(initial);
    }

    _openedAppSub?.cancel();
    _openedAppSub = service.onMessageOpenedApp.listen(_routeFromMessage);
  }

  /// Extract a `route` from the message's data payload and feed it through
  /// the deep-link notifier. Accepted: `data: { "route": "/pdf-viewer?..." }`
  void _routeFromMessage(RemoteMessage message) {
    final route = message.data['route'];
    if (route is String && route.startsWith('/')) {
      ref.read(deepLinkProvider.notifier).push(route);
    }
  }

  Future<void> _syncForProfile(UserModel profile) async {
    // Claim the tuple first so any writes we emit are ignored by the listener.
    _lastSyncedUid = profile.uid;
    _lastSyncedUniversity = profile.university;
    _lastSyncedCourse = profile.course;
    _lastSyncedBranch = profile.branch;
    _lastSyncedSem = profile.sem;

    final service = ref.read(fcmServiceProvider);

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_permissionAskedKey) ?? false)) {
      await service.requestPermission();
      await prefs.setBool(_permissionAskedKey, true);
    }

    await service.syncToken(profile.uid, storedToken: profile.fcmToken);
    await service.syncTopicsForProfile(
      uid: profile.uid,
      university: profile.university,
      course: profile.course,
      branch: profile.branch,
      sem: profile.sem,
      currentSubscriptions: profile.subscribeArray,
    );

    _refreshSub ??= service.onTokenRefresh.listen((_) {
      final latest = ref.read(userProfileProvider).value;
      service.syncToken(profile.uid, storedToken: latest?.fcmToken);
    });
  }
}

final fcmSyncProvider = AsyncNotifierProvider<FcmSyncNotifier, void>(
  FcmSyncNotifier.new,
);

/// Emits every foreground message — the UI layer listens and shows an in-app
/// notification without launching a system notification.
final foregroundMessageProvider = StreamProvider<RemoteMessage>((ref) {
  return ref.watch(fcmServiceProvider).onForegroundMessage;
});
