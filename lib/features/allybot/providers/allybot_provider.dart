import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../models/chat_session_model.dart';
import '../../auth/providers/auth_provider.dart';

final _firestore = FirebaseFirestore.instance;

/// Stream of all chat sessions for the current user.
final chatSessionsProvider = StreamProvider<List<ChatSessionModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  return _firestore
      .collection(FirestorePaths.userInitializedPdfs(user.uid))
      .orderBy('lastUpdated', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ChatSessionModel.fromFirestore(doc))
          .toList());
});

/// Stream of a single chat session.
final chatSessionProvider =
    StreamProvider.family<ChatSessionModel?, String>((ref, sessionId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return _firestore
      .doc(FirestorePaths.userInitializedPdf(user.uid, sessionId))
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return ChatSessionModel.fromFirestore(doc);
  });
});

class AllyBotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initiate a new chat session for a PDF.
  ///
  /// No external service call — we just persist a Firestore session
  /// record with all the metadata our agentic backend needs to scope
  /// later message turns. Returns the new session ID.
  Future<String?> initiateChat({
    required String uid,
    required String resourceId,
    required String storageId,
    required String resourceName,
    required String subject,
    required String university,
    required String course,
    required String branch,
    required String sem,
  }) async {
    if (resourceId.isEmpty || subject.isEmpty) {
      throw Exception(
        'Missing PDF metadata. Open a chat from the PDF viewer or '
        'history list.',
      );
    }

    final docRef = _firestore
        .collection(FirestorePaths.userInitializedPdfs(uid))
        .doc();

    await docRef.set({
      // Stable identifiers our /chat_about_pdf endpoint needs
      'resourceId': resourceId,
      'storageId': storageId,
      'university': university,
      'course': course,
      'branch': branch,
      'sem': sem,
      'subject': subject,
      // Display fields the chat history list reads
      'resourceName': resourceName,
      'url': storageId, // legacy `url` slot — keeps existing list UI working
      // Legacy field retained for backward-compat with the old list UI;
      // use resourceId for any new logic.
      'sourceId': resourceId,
      'conversations': <Map<String, dynamic>>[],
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Send a message in an existing chat session.
  ///
  /// Posts to the agentic backend `/chat_about_pdf` endpoint, which
  /// runs a RAG-grounded LLM call scoped to the session's PDF.
  Future<String> sendMessage({
    required String uid,
    required String sessionId,
    required String message,
  }) async {
    final sessionRef =
        _firestore.doc(FirestorePaths.userInitializedPdf(uid, sessionId));
    final snap = await sessionRef.get();
    if (!snap.exists) {
      throw Exception('Chat session no longer exists.');
    }
    final data = snap.data() as Map<String, dynamic>;

    final resourceId = data['resourceId'] as String? ??
        data['sourceId'] as String? ??
        '';
    final subject = data['subject'] as String? ?? '';
    final university = data['university'] as String? ?? '';
    final course = data['course'] as String? ?? '';
    final branch = data['branch'] as String? ?? '';
    final sem = data['sem'] as String? ?? '';
    if (resourceId.isEmpty || subject.isEmpty) {
      throw Exception(
        'This chat session is missing PDF metadata. Start a new chat '
        'from the PDF viewer.',
      );
    }

    // Pull the most recent turns from the session for context.
    final convs = (data['conversations'] as List<dynamic>? ?? const []);
    final priorTurns = convs
        .map((c) => c as Map<String, dynamic>)
        .where((c) => (c['message'] ?? '').toString().isNotEmpty)
        .map((c) => {
              'sender': c['sender'] ?? 'user',
              'message': c['message'] ?? '',
            })
        .toList();

    // Append the user's new message to the conversation log.
    await sessionRef.update({
      'conversations': FieldValue.arrayUnion([
        {
          'sender': 'user',
          'message': message,
          'date': Timestamp.now(),
          'loading': false,
        }
      ]),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Call our backend.
    final idToken =
        await FirebaseAuth.instance.currentUser?.getIdToken(false) ?? '';
    final response = await http.post(
      Uri.parse('${AppConstants.aiBackendBaseUrl}/chat_about_pdf'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'uid': uid,
        'university': university,
        'course': course,
        'branch': branch,
        'sem': sem,
        'subject': subject,
        'resource_id': resourceId,
        'question': message,
        'prior_turns': priorTurns,
      }),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      String msg = 'Failed to get response. Please try again.';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final detail = body['detail'];
        if (detail is Map && detail['error'] is String) {
          msg = detail['error'] as String;
        } else if (body['error'] is String) {
          msg = body['error'] as String;
        }
      } catch (_) {}
      throw Exception(msg);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final reply = body['reply'] as String? ?? '(no reply)';

    await sessionRef.update({
      'conversations': FieldValue.arrayUnion([
        {
          'sender': 'AllyBot',
          'message': reply,
          'date': Timestamp.now(),
          'loading': false,
        }
      ]),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    return reply;
  }

  /// Delete a chat session.
  Future<void> deleteSession({
    required String uid,
    required String sessionId,
  }) async {
    await _firestore
        .doc(FirestorePaths.userInitializedPdf(uid, sessionId))
        .delete();
  }
}

final allyBotServiceProvider = Provider<AllyBotService>((ref) {
  return AllyBotService();
});
