import 'package:cloud_firestore/cloud_firestore.dart';

/// A topic-based discussion channel.
/// Stored at `Channels/{channelId}`.
class ChannelModel {
  final String id;
  final String name;
  final String description;
  final String? createdBy;
  final String? createdByName;
  final DateTime? createdAt;
  final int messageCount;

  const ChannelModel({
    required this.id,
    required this.name,
    required this.description,
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.messageCount = 0,
  });

  factory ChannelModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChannelModel(
      id: doc.id,
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      createdBy: d['createdBy'],
      createdByName: d['createdByName'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      messageCount: (d['messageCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        if (createdBy != null) 'createdBy': createdBy,
        if (createdByName != null) 'createdByName': createdByName,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'messageCount': messageCount,
      };
}

/// A single chat message inside a channel.
/// Stored at `Channels/{channelId}/Messages/{messageId}`.
class ChannelMessage {
  final String id;
  final String text;
  final String authorUid;
  final String authorName;
  final DateTime? createdAt;

  const ChannelMessage({
    required this.id,
    required this.text,
    required this.authorUid,
    required this.authorName,
    this.createdAt,
  });

  factory ChannelMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChannelMessage(
      id: doc.id,
      text: d['text'] ?? '',
      authorUid: d['authorUid'] ?? '',
      authorName: d['authorName'] ?? 'Anonymous',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'text': text,
        'authorUid': authorUid,
        'authorName': authorName,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
