import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String sender; // 'user' or 'AllyBot'
  final String message;
  final DateTime? date;
  final bool loading;

  const ChatMessage({
    required this.sender,
    required this.message,
    this.date,
    this.loading = false,
  });

  bool get isUser => sender == 'user';
  bool get isBot => sender == 'AllyBot';

  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      sender: data['sender'] ?? '',
      message: data['message'] ?? '',
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : null,
      loading: data['loading'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'message': message,
      'date': date != null ? Timestamp.fromDate(date!) : FieldValue.serverTimestamp(),
      'loading': loading,
    };
  }
}

class ChatSessionModel {
  final String id;
  final String sourceId;
  final String url;
  final String? resourceName;
  final String? subject;
  final List<ChatMessage> conversations;
  final DateTime? createdAt;
  final DateTime? lastUpdated;

  const ChatSessionModel({
    required this.id,
    required this.sourceId,
    required this.url,
    this.resourceName,
    this.subject,
    this.conversations = const [],
    this.createdAt,
    this.lastUpdated,
  });

  String get lastMessage {
    if (conversations.isEmpty) return 'No messages yet';
    return conversations.last.message;
  }

  factory ChatSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final convList = (data['conversations'] as List<dynamic>?) ?? [];

    return ChatSessionModel(
      id: doc.id,
      sourceId: data['sourceId'] ?? '',
      url: data['url'] ?? '',
      resourceName: data['resourceName'],
      subject: data['subject'],
      conversations: convList
          .map((c) => ChatMessage.fromMap(c as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sourceId': sourceId,
      'url': url,
      'resourceName': resourceName,
      'subject': subject,
      'conversations': conversations.map((c) => c.toMap()).toList(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}
