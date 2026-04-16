import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String course;
  final String sem;
  final String branch;
  final String year;
  final String university;
  final String college;
  final String? pfp;
  final String sourceType;
  final bool premiumUser;
  final int initiatedChats;
  final int messageCount;
  final String? fcmToken;
  final List<String> subscribeArray;
  final DateTime? createdAt;
  final DateTime? lastUpdated;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.course,
    required this.sem,
    required this.branch,
    required this.year,
    required this.university,
    required this.college,
    this.pfp,
    this.sourceType = 'MOBILE_APP',
    this.premiumUser = false,
    this.initiatedChats = 0,
    this.messageCount = 0,
    this.fcmToken,
    this.subscribeArray = const [],
    this.createdAt,
    this.lastUpdated,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      course: data['course'] ?? '',
      sem: data['sem'] ?? '',
      branch: data['branch'] ?? '',
      year: data['Year'] ?? '',
      university: data['university'] ?? '',
      college: data['college'] ?? '',
      pfp: data['pfp'],
      sourceType: data['sourceType'] ?? 'MOBILE_APP',
      premiumUser: data['premiumUser'] ?? false,
      initiatedChats: data['initiatedChats'] ?? 0,
      messageCount: data['messageCount'] ?? 0,
      fcmToken: data['fcmToken'],
      subscribeArray: List<String>.from(data['subscribeArray'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'course': course,
      'sem': sem,
      'branch': branch,
      'Year': year,
      'university': university,
      'college': college,
      'pfp': pfp,
      'sourceType': sourceType,
      'premiumUser': premiumUser,
      'initiatedChats': initiatedChats,
      'messageCount': messageCount,
      'fcmToken': fcmToken,
      'subscribeArray': subscribeArray,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? course,
    String? sem,
    String? branch,
    String? year,
    String? university,
    String? college,
    String? pfp,
    String? sourceType,
    bool? premiumUser,
    int? initiatedChats,
    int? messageCount,
    String? fcmToken,
    List<String>? subscribeArray,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      course: course ?? this.course,
      sem: sem ?? this.sem,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      university: university ?? this.university,
      college: college ?? this.college,
      pfp: pfp ?? this.pfp,
      sourceType: sourceType ?? this.sourceType,
      premiumUser: premiumUser ?? this.premiumUser,
      initiatedChats: initiatedChats ?? this.initiatedChats,
      messageCount: messageCount ?? this.messageCount,
      fcmToken: fcmToken ?? this.fcmToken,
      subscribeArray: subscribeArray ?? this.subscribeArray,
      createdAt: createdAt,
      lastUpdated: lastUpdated,
    );
  }
}
