class SubjectModel {
  final String subject;
  final String sem;
  final String branch;

  const SubjectModel({
    required this.subject,
    required this.sem,
    required this.branch,
  });

  /// Parses a subject entry from a QueryList `list` array item.
  ///
  /// Production data uses `subjectName` (not `subject`) — confirmed from the
  /// web app at `academic-ally-web-main/src/pages/PdfViewer/multipleResType.js`.
  /// Falls back to `subject` for any hand-authored docs. `sem` may be stored
  /// as either a string or a number in legacy data; `.toString()` normalizes
  /// both so downstream filtering against `UserModel.sem` (always string) works.
  factory SubjectModel.fromMap(Map<String, dynamic> data) {
    return SubjectModel(
      subject: (data['subjectName'] ?? data['subject'] ?? '').toString(),
      sem: (data['sem'] ?? '').toString(),
      branch: (data['branch'] ?? '').toString(),
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
