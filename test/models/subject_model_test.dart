import 'package:flutter_test/flutter_test.dart';

import 'package:academically/models/subject_model.dart';

void main() {
  test('normalizes legacy QueryList navigation fields', () {
    final subject = SubjectModel.fromMap({
      'subject': 'Elements of Computer Science & Engineering ',
      'sem': '1 ',
      'branch': 'IT ',
    });

    expect(subject.subject, 'Elements of Computer Science & Engineering');
    expect(subject.sem, '1');
    expect(subject.branch, 'IT');
  });
}
