import 'package:cloud_firestore/cloud_firestore.dart';

class ResourceModel {
  final String id;
  final String name;
  final String subject;
  final String category;
  final double rating;
  final int views;
  final String? uploaderId;
  final String? uploaderName;
  final double? size;
  final String sem;
  final String branch;
  final String? course;
  final String? university;
  final DateTime? date;
  final List<dynamic> units;
  final String? storageId;
  final String? did;

  const ResourceModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.category,
    this.rating = 0,
    this.views = 0,
    this.uploaderId,
    this.uploaderName,
    this.size,
    required this.sem,
    required this.branch,
    this.course,
    this.university,
    this.date,
    this.units = const [],
    this.storageId,
    this.did,
  });

  factory ResourceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Legacy docs from the React Native era store numeric fields as
    // doubles (e.g. views: 1.0), so coerce defensively rather than
    // casting blindly.
    return ResourceModel(
      id: doc.id,
      name: data['name'] ?? '',
      subject: data['subject'] ?? '',
      category: data['category'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      views: (data['views'] as num?)?.toInt() ?? 0,
      uploaderId: data['uploaderId'],
      uploaderName: data['uploaderName'],
      size: (data['size'] as num?)?.toDouble() ?? 0,
      sem: data['sem']?.toString() ?? '',
      branch: data['branch'] ?? data['department'] ?? '',
      course: data['course'],
      university: data['university'],
      date: _parseDate(data['date']),
      units: _parseUnits(data['units']),
      storageId: data['storageId'],
      did: data['did'],
    );
  }

  static List<dynamic> _parseUnits(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    // Legacy docs sometimes stored units as a comma-separated string.
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return const [];
      return trimmed.split(RegExp(r'[,;]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is num) {
      // Legacy docs store epoch millis as int OR double.
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    }
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'subject': subject,
      'category': category,
      'rating': rating,
      'views': views,
      'uploaderId': uploaderId,
      'uploaderName': uploaderName,
      'size': size,
      'sem': sem,
      'branch': branch,
      'course': course,
      'university': university,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'units': units,
      'storageId': storageId,
      'did': did,
    };
  }

  ResourceModel copyWith({
    String? name,
    String? subject,
    String? category,
    double? rating,
    int? views,
    String? uploaderId,
    String? uploaderName,
    double? size,
    String? sem,
    String? branch,
    String? course,
    String? university,
    DateTime? date,
    List<dynamic>? units,
    String? storageId,
    String? did,
  }) {
    return ResourceModel(
      id: id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      views: views ?? this.views,
      uploaderId: uploaderId ?? this.uploaderId,
      uploaderName: uploaderName ?? this.uploaderName,
      size: size ?? this.size,
      sem: sem ?? this.sem,
      branch: branch ?? this.branch,
      course: course ?? this.course,
      university: university ?? this.university,
      date: date ?? this.date,
      units: units ?? this.units,
      storageId: storageId ?? this.storageId,
      did: did ?? this.did,
    );
  }
}
