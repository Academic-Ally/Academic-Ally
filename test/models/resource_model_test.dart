import 'package:flutter_test/flutter_test.dart';

import 'package:academically/models/resource_model.dart';

void main() {
  group('ResourceModel.fromMap', () {
    test('accepts Firestore numeric values stored as strings', () {
      final resource = ResourceModel.fromMap('resource-1', {
        'name': 'Physics notes',
        'subject': 'Physics',
        'category': 'Notes',
        'rating': '4.5',
        'views': '20',
        'size': '22.99',
        'sem': 1,
        'department': 'IT',
        'date': '1686331219643',
        'units': 'Unit I, Unit II',
        'storageId': 'Resources/OU/BE/IT/1/Notes/Physics/notes.pdf',
      });

      expect(resource.rating, 4.5);
      expect(resource.views, 20);
      expect(resource.size, 22.99);
      expect(resource.sem, '1');
      expect(resource.branch, 'IT');
      expect(resource.date?.millisecondsSinceEpoch, 1686331219643);
      expect(resource.units, ['Unit I', 'Unit II']);
    });

    test('uses safe defaults for empty or malformed numeric values', () {
      final resource = ResourceModel.fromMap('resource-2', {
        'name': 'Legacy notes',
        'subject': 'Physics',
        'category': 'Notes',
        'rating': '',
        'views': null,
        'size': 'not-a-number',
        'sem': '1',
        'branch': 'IT',
      });

      expect(resource.rating, 0);
      expect(resource.views, 0);
      expect(resource.size, 0);
    });
  });
}
