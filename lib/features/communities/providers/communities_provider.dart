import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../models/channel_model.dart';
import '../../auth/providers/auth_provider.dart';

/// Stream of all channels, most-recently-active first. Falls back to
/// creation time when no messages have been posted yet.
final channelsListProvider = StreamProvider<List<ChannelModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestorePaths.channels())
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => ChannelModel.fromFirestore(d)).toList());
});

/// Single channel stream (for the chat header).
final channelDetailProvider =
    StreamProvider.family<ChannelModel?, String>((ref, channelId) {
  return FirebaseFirestore.instance
      .doc(FirestorePaths.channel(channelId))
      .snapshots()
      .map((doc) => doc.exists ? ChannelModel.fromFirestore(doc) : null);
});

/// Live stream of messages in a channel, oldest first so the ListView
/// can scroll to the bottom naturally.
final channelMessagesProvider =
    StreamProvider.family<List<ChannelMessage>, String>((ref, channelId) {
  return FirebaseFirestore.instance
      .collection(FirestorePaths.channelMessages(channelId))
      .orderBy('createdAt', descending: false)
      .limit(200)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => ChannelMessage.fromFirestore(d)).toList());
});

/// Creates a new channel doc. Returns the auto-ID.
Future<String?> createChannel({
  required WidgetRef ref,
  required String name,
  required String description,
}) async {
  final user = ref.read(currentUserProvider);
  final profile = ref.read(userProfileProvider).value;
  final docRef =
      FirebaseFirestore.instance.collection(FirestorePaths.channels()).doc();
  final channel = ChannelModel(
    id: docRef.id,
    name: name,
    description: description,
    createdBy: user?.uid,
    createdByName: profile?.name,
    createdAt: DateTime.now(),
  );
  await docRef.set(channel.toMap());
  return docRef.id;
}

/// Posts a message to a channel and bumps the parent doc's messageCount.
/// Two writes (message + count) are not atomic — acceptable for demo; if
/// this becomes a contention hotspot in production, switch to a Cloud
/// Function that fans out the count increment on message create.
Future<void> sendMessage({
  required WidgetRef ref,
  required String channelId,
  required String text,
}) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return;
  final user = ref.read(currentUserProvider);
  final profile = ref.read(userProfileProvider).value;
  if (user == null) {
    throw StateError('Must be signed in to send messages.');
  }

  final msgRef = FirebaseFirestore.instance
      .collection(FirestorePaths.channelMessages(channelId))
      .doc();
  final msg = ChannelMessage(
    id: msgRef.id,
    text: trimmed,
    authorUid: user.uid,
    authorName: profile?.name ?? user.email?.split('@').first ?? 'Anon',
    createdAt: DateTime.now(),
  );
  await msgRef.set(msg.toMap());

  // Best-effort counter bump — ignore failures so messages still land.
  try {
    await FirebaseFirestore.instance
        .doc(FirestorePaths.channel(channelId))
        .update({
      'messageCount': FieldValue.increment(1),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  } catch (_) {/* non-fatal */}
}

/// Deletes a message. Caller should verify ownership client-side (server
/// rules will enforce it properly in Phase 4).
Future<void> deleteMessage({
  required String channelId,
  required String messageId,
}) async {
  await FirebaseFirestore.instance
      .doc(FirestorePaths.channelMessage(channelId, messageId))
      .delete();
}

/// Deletes a channel and its message subcollection is NOT cascaded — for
/// demo we just drop the parent; orphan messages stay in Firestore but
/// never render because the parent is gone. Phase 4 rewrites this as a
/// Cloud Function that cascades.
Future<void> deleteChannel(String channelId) async {
  await FirebaseFirestore.instance
      .doc(FirestorePaths.channel(channelId))
      .delete();
}

/// Idempotent demo seeder: creates 3 channels with a few sample messages
/// each, only if the Channels collection is empty.
Future<void> seedDemoChannels(WidgetRef ref) async {
  final snap = await FirebaseFirestore.instance
      .collection(FirestorePaths.channels())
      .limit(1)
      .get();
  if (snap.docs.isNotEmpty) return;

  final seeds = <({String name, String description, List<String> msgs})>[
    (
      name: 'General',
      description: 'Campus-wide chatter, announcements, and off-topic.',
      msgs: [
        'Welcome to Academic Ally! 👋',
        'Post resources, ask doubts, meet classmates.',
        'New features drop every week — watch this channel.',
      ],
    ),
    (
      name: 'DBMS Discussion',
      description: 'Everything relational: ER model, SQL, transactions.',
      msgs: [
        'Anyone has notes for the normalization chapter?',
        'Check the Knowledge Map — ER Model shows up there.',
        'PYQ Analyzer flagged Normalization as the highest weighted topic for Sem 3.',
      ],
    ),
    (
      name: 'Memes & Side-talk',
      description: 'Campus memes, random pings, vent zone.',
      msgs: [
        'When the exam is tomorrow and you haven\'t started yet 💀',
        'Coffee recommendations near JNTUH gate 4?',
      ],
    ),
  ];

  for (final seed in seeds) {
    final id = await createChannel(
      ref: ref,
      name: seed.name,
      description: seed.description,
    );
    if (id == null) continue;
    for (final msg in seed.msgs) {
      await sendMessage(ref: ref, channelId: id, text: msg);
    }
  }
}
