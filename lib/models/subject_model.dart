class SubjectModel {
  final String subject;
  final String sem;
  final String branch;

  const SubjectModel({
    required this.subject,
    required this.sem,
    required this.branch,
  });

  factory SubjectModel.fromMap(Map<String, dynamic> data) {
    return SubjectModel(
      subject: data['subject'] ?? '',
      sem: data['sem'] ?? '',
      branch: data['branch'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'sem': sem,
      'branch': branch,
    };
  }

  /// Generate abbreviation from subject name.
  /// e.g. "Computer Networks" → "CN"
  String get abbreviation {
    const exclude = {'of', 'for', 'and', 'the', 'in', 'to', 'a', 'an'};
    return subject
        .split(' ')
        .where((w) => w.isNotEmpty && !exclude.contains(w.toLowerCase()))
        .map((w) => w[0].toUpperCase())
        .join();
  }
}
