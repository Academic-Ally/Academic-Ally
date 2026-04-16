import 'dart:convert';

class RecentPdfModel {
  final String id;
  final String name;
  final String subject;
  final String category;
  final String sem;
  final String branch;
  final String? storageId;
  final String? university;
  final String? course;
  final DateTime viewedAt;

  const RecentPdfModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.category,
    required this.sem,
    required this.branch,
    this.storageId,
    this.university,
    this.course,
    required this.viewedAt,
  });

  factory RecentPdfModel.fromJson(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    return RecentPdfModel.fromMap(data);
  }

  factory RecentPdfModel.fromMap(Map<String, dynamic> data) {
    return RecentPdfModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      subject: data['subject'] ?? '',
      category: data['category'] ?? '',
      sem: data['sem'] ?? '',
      branch: data['branch'] ?? '',
      storageId: data['storageId'],
      university: data['university'],
      course: data['course'],
      viewedAt: data['viewedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['viewedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'category': category,
      'sem': sem,
      'branch': branch,
      'storageId': storageId,
      'university': university,
      'course': course,
      'viewedAt': viewedAt.millisecondsSinceEpoch,
    };
  }

  String toJson() => jsonEncode(toMap());
}
