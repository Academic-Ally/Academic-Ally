import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/subject_model.dart';
import '../../resources/providers/resources_provider.dart';

/// Search query notifier.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// Branch filter notifier.
class SearchBranchFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  set value(String? v) => state = v;
}

final searchBranchFilterProvider =
    NotifierProvider<SearchBranchFilterNotifier, String?>(
        SearchBranchFilterNotifier.new);

/// Semester filter notifier.
class SearchSemFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  set value(String? v) => state = v;
}

final searchSemFilterProvider =
    NotifierProvider<SearchSemFilterNotifier, String?>(
        SearchSemFilterNotifier.new);

/// Filtered subjects based on search query and filters.
final filteredSubjectsProvider = Provider<List<SubjectModel>>((ref) {
  final allSubjects = ref.watch(subjectsListProvider).value ?? [];
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final branchFilter = ref.watch(searchBranchFilterProvider);
  final semFilter = ref.watch(searchSemFilterProvider);

  var filtered = allSubjects.toList();

  // Apply branch filter
  if (branchFilter != null) {
    filtered = filtered.where((s) => s.branch == branchFilter).toList();
  }

  // Apply semester filter
  if (semFilter != null) {
    filtered = filtered.where((s) => s.sem == semFilter).toList();
  }

  // Apply search query
  if (query.isNotEmpty) {
    filtered = filtered.where((s) {
      final name = s.subject.toLowerCase();
      final abbr = s.abbreviation.toLowerCase();
      return name.contains(query) || abbr.contains(query);
    }).toList();
  }

  return filtered;
});
