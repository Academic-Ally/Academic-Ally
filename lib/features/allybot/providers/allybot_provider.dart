import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  /// Calls the cloud function `/chat/initiate`.
  /// Returns the session ID.
  Future<String?> initiateChat({
    required String uid,
    required String pdfUrl,
    required String resourceName,
    required String subject,
  }) async {
    // Check if user has reached initiation limit
    final userDoc = await _firestore.doc(FirestorePaths.user(uid)).get();
    final userData = userDoc.data();
    final initiatedChats = userData?['initiatedChats'] ?? 0;
    final isPremium = userData?['premiumUser'] ?? false;

    if (!isPremium && initiatedChats >= AppConstants.maxChatInitiations) {
      throw Exception(
          'Chat initiation limit reached. Upgrade to premium for more.');
    }

    try {
      // Call cloud function to initiate chat
      final response = await http.post(
        Uri.parse('${AppConstants.cloudFunctionsBaseUrl}/chat/initiate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': uid,
          'pdfUrl': pdfUrl,
          'resourceName': resourceName,
          'subject': subject,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sourceId = data['sourceId'] as String?;

        if (sourceId != null) {
          // Create local Firestore record
          final docRef = _firestore
              .collection(FirestorePaths.userInitializedPdfs(uid))
              .doc();

          await docRef.set({
            'sourceId': sourceId,
            'url': pdfUrl,
            'resourceName': resourceName,
            'subject': subject,
            'conversations': [],
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          // Increment initiated chats counter
          await _firestore.doc(FirestorePaths.user(uid)).update({
            'initiatedChats': FieldValue.increment(1),
          });

          return docRef.id;
        }
      }

      throw Exception('Failed to initiate chat. Please try again.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Send a message in an existing chat session.
  /// Calls the cloud function `/chat/message`.
  Future<String> sendMessage({
    required String uid,
    required String sessionId,
    required String sourceId,
    required String message,
  }) async {
    // Check daily message limit
    final userDoc = await _firestore.doc(FirestorePaths.user(uid)).get();
    final userData = userDoc.data();
    final messageCount = userData?['messageCount'] ?? 0;
    final isPremium = userData?['premiumUser'] ?? false;
    final limit = isPremium
        ? AppConstants.dailyMessageLimitPremium
        : AppConstants.dailyMessageLimitRegular;

    if (messageCount >= limit) {
      throw Exception('Daily message limit reached ($limit messages/day).');
    }

    final sessionRef =
        _firestore.doc(FirestorePaths.userInitializedPdf(uid, sessionId));

    // Add user message to conversations
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

    try {
      // Call cloud function
      final response = await http.post(
        Uri.parse('${AppConstants.cloudFunctionsBaseUrl}/chat/message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': uid,
          'sourceId': sourceId,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botReply = data['message'] as String? ?? 'No response received.';

        // Add bot reply to conversations
        await sessionRef.update({
          'conversations': FieldValue.arrayUnion([
            {
              'sender': 'AllyBot',
              'message': botReply,
              'date': Timestamp.now(),
              'loading': false,
            }
          ]),
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Increment message count
        await _firestore.doc(FirestorePaths.user(uid)).update({
          'messageCount': FieldValue.increment(1),
        });

        return botReply;
      }

      throw Exception('Failed to get response. Please try again.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error. Please check your connection.');
    }
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
