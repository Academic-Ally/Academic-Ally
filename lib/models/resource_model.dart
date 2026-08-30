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
    return ResourceModel.fromMap(doc.id, data);
  }

  /// Builds a resource from Firestore-compatible map data.
  ///
  /// A few Phase 0 records stored numeric fields as strings. Current queries
  /// exclude records without Storage paths, but parsing remains defensive so a
  /// single malformed document can never take down an entire subject list.
  factory ResourceModel.fromMap(String id, Map<String, dynamic> data) {
    // Legacy docs from the React Native era store numeric fields as
    // doubles or strings, so coerce defensively rather than casting blindly.
    return ResourceModel(
      id: id,
      name: data['name']?.toString() ?? '',
      subject: data['subject']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      rating: _parseNum(data['rating'])?.toDouble() ?? 0,
      views: _parseNum(data['views'])?.toInt() ?? 0,
      uploaderId: data['uploaderId']?.toString(),
      uploaderName: data['uploaderName']?.toString(),
      size: _parseNum(data['size'])?.toDouble() ?? 0,
      sem: data['sem']?.toString() ?? '',
      branch: (data['branch'] ?? data['department'])?.toString().trim() ?? '',
      course: data['course']?.toString(),
      university: data['university']?.toString(),
      date: _parseDate(data['date']),
      units: _parseUnits(data['units']),
      storageId: data['storageId']?.toString(),
      did: data['did']?.toString(),
    );
  }

  static num? _parseNum(dynamic raw) {
    if (raw is num) return raw;
    if (raw is String) return num.tryParse(raw.trim());
    return null;
  }

  static List<dynamic> _parseUnits(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    // Legacy docs sometimes stored units as a comma-separated string.
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return const [];
      return trimmed
          .split(RegExp(r'[,;]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
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
      final parsedEpoch = num.tryParse(raw.trim());
      if (parsedEpoch != null) {
        return DateTime.fromMillisecondsSinceEpoch(parsedEpoch.toInt());
      }
      return DateTime.tryParse(raw.trim());
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
