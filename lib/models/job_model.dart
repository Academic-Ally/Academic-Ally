import 'package:cloud_firestore/cloud_firestore.dart';

/// A job or internship posting.
/// Stored at `Jobs/{jobId}`.
enum JobType { internship, fullTime, partTime }

extension JobTypeX on JobType {
  String get wire {
    switch (this) {
      case JobType.internship:
        return 'internship';
      case JobType.fullTime:
        return 'full-time';
      case JobType.partTime:
        return 'part-time';
    }
  }

  String get label {
    switch (this) {
      case JobType.internship:
        return 'Internship';
      case JobType.fullTime:
        return 'Full-time';
      case JobType.partTime:
        return 'Part-time';
    }
  }

  static JobType fromWire(String? raw) {
    switch (raw) {
      case 'full-time':
        return JobType.fullTime;
      case 'part-time':
        return JobType.partTime;
      case 'internship':
      default:
        return JobType.internship;
    }
  }
}

class JobModel {
  final String id;
  final String title;
  final String company;
  final String location;
  final JobType type;
  final String description;
  final String applyUrl;
  final List<String> tags;
  final String? postedBy;
  final String? postedByName;
  final DateTime? postedAt;

  const JobModel({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.description,
    required this.applyUrl,
    this.tags = const [],
    this.postedBy,
    this.postedByName,
    this.postedAt,
  });

  factory JobModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return JobModel(
      id: doc.id,
      title: d['title'] ?? '',
      company: d['company'] ?? '',
      location: d['location'] ?? '',
      type: JobTypeX.fromWire(d['type'] as String?),
      description: d['description'] ?? '',
      applyUrl: d['applyUrl'] ?? '',
      tags: List<String>.from(d['tags'] ?? const []),
      postedBy: d['postedBy'],
      postedByName: d['postedByName'],
      postedAt: (d['postedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'company': company,
        'location': location,
        'type': type.wire,
        'description': description,
        'applyUrl': applyUrl,
        'tags': tags,
        if (postedBy != null) 'postedBy': postedBy,
        if (postedByName != null) 'postedByName': postedByName,
        'postedAt': postedAt != null
            ? Timestamp.fromDate(postedAt!)
            : FieldValue.serverTimestamp(),
      };
}
