import 'package:cloud_firestore/cloud_firestore.dart';

class SeekHubRequestModel {
  final String id;
  final String subject;
  final String category;
  final String seekerName;
  final String seekerUid;
  final String? seekerPhoto;
  final String sem;
  final String branch;
  final String course;
  final String university;
  final String status; // 'pending' or 'fulfilled'
  final List<String> notifyList;
  final DateTime? requestedOn;
  final DateTime? date;

  const SeekHubRequestModel({
    required this.id,
    required this.subject,
    required this.category,
    required this.seekerName,
    required this.seekerUid,
    this.seekerPhoto,
    required this.sem,
    required this.branch,
    required this.course,
    required this.university,
    this.status = 'pending',
    this.notifyList = const [],
    this.requestedOn,
    this.date,
  });

  bool get isPending => status == 'pending';
  bool get isFulfilled => status == 'fulfilled';

  factory SeekHubRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SeekHubRequestModel(
      id: data['id'] ?? doc.id,
      subject: data['subject'] ?? '',
      category: data['category'] ?? '',
      seekerName: data['seekerName'] ?? '',
      seekerUid: data['seekerUid'] ?? '',
      seekerPhoto: data['seekerPhoto'],
      sem: data['sem'] ?? '',
      branch: data['branch'] ?? '',
      course: data['course'] ?? '',
      university: data['university'] ?? '',
      status: data['status'] ?? 'pending',
      notifyList: List<String>.from(data['notifyList'] ?? []),
      requestedOn: (data['requestedOn'] as Timestamp?)?.toDate(),
      date: (data['date'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'subject': subject,
      'category': category,
      'seekerName': seekerName,
      'seekerUid': seekerUid,
      'seekerPhoto': seekerPhoto,
      'sem': sem,
      'branch': branch,
      'course': course,
      'university': university,
      'status': status,
      'notifyList': notifyList,
      'requestedOn': requestedOn != null
          ? Timestamp.fromDate(requestedOn!)
          : FieldValue.serverTimestamp(),
      'date': date != null
          ? Timestamp.fromDate(date!)
          : FieldValue.serverTimestamp(),
    };
  }

  SeekHubRequestModel copyWith({
    String? status,
    List<String>? notifyList,
  }) {
    return SeekHubRequestModel(
      id: id,
      subject: subject,
      category: category,
      seekerName: seekerName,
      seekerUid: seekerUid,
      seekerPhoto: seekerPhoto,
      sem: sem,
      branch: branch,
      course: course,
      university: university,
      status: status ?? this.status,
      notifyList: notifyList ?? this.notifyList,
      requestedOn: requestedOn,
      date: date,
    );
  }
}
