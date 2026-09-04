import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../models/subject_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../resources/providers/resources_provider.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjects = ref.watch(filteredSubjectsProvider);
    final query = ref.watch(searchQueryProvider);
    final branchFilter = ref.watch(searchBranchFilterProvider);
    final semFilter = ref.watch(searchSemFilterProvider);

    return ScreenLayout(
      title: 'Explore',
      icon: Icons.search_rounded,
      body: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      ref.read(searchQueryProvider.notifier).update(value),
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF161719),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search subjects...',
                    hintStyle: TextStyle(
                      color:
                          isDark ? Colors.white54 : const Color(0xFF808080),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    suffixIcon: query.isEmpty
                        ? Icon(Icons.search,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF161719))
                        : IconButton(
                            icon: Icon(Icons.clear,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF161719)),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).update('');
                            },
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter dropdowns
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _FilterDropdown(
                      value: branchFilter,
                      hint: 'All Branches',
                      icon: Icons.account_tree_outlined,
                      items: AppConstants.branches,
                      onChanged: (val) => ref
                          .read(searchBranchFilterProvider.notifier)
                          .value = val,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FilterDropdown(
                      value: semFilter,
                      hint: 'All Semesters',
                      icon: Icons.school_outlined,
                      items: AppConstants.semesters,
                      displayPrefix: 'Sem ',
                      onChanged: (val) =>
                          ref.read(searchSemFilterProvider.notifier).value =
                              val,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Results
            Expanded(
              child: subjects.isEmpty
                  ? Center(
                      child: Text(
                        query.isEmpty && branchFilter == null && semFilter == null
                            ? 'Search for subjects across your curriculum'
                            : 'No subjects found',
                        style: TextStyle(color: context.faintText),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: subjects.length,
                      itemBuilder: (context, index) {
                        return _SubjectTile(
                          subject: subjects[index],
                          isDark: isDark,
                          onTap: () => _navigateToSubject(subjects[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSubject(SubjectModel subject) {
    final user = ref.read(userProfileProvider).value;
    context.push(
      '/subject-resources'
      '?subject=${Uri.encodeComponent(subject.subject)}'
      '&branch=${subject.branch}'
      '&sem=${subject.sem}'
      '&university=${user?.university ?? ''}'
      '&course=${user?.course ?? ''}',
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final IconData icon;
  final List<String> items;
  final String displayPrefix;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  const _FilterDropdown({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    this.displayPrefix = '',
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? Colors.white54 : const Color(0xFF91919F),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(
                  hint,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF808080),
                    fontSize: 14,
                  ),
                ),
                isExpanded: true,
                icon: Icon(Icons.expand_more,
                    color:
                        isDark ? Colors.white54 : context.mutedText,
                    size: 20),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(hint,
                        style: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : context.mutedText)),
                  ),
                  ...items.map((item) => DropdownMenuItem(
                        value: item,
                        child: Text('$displayPrefix$item'),
                      )),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectTile extends ConsumerWidget {
  final SubjectModel subject;
  final bool isDark;
  final VoidCallback onTap;

  const _SubjectTile({
    required this.subject,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // QueryList lists every curriculum subject, including ones that have no
    // PDFs uploaded yet (typically labs). Surface that up front so students
    // don't open a subject only to find four "Empty" categories. The flags
    // provider issues one limit(1) query per category and is cached per
    // subject, and ListView.builder only builds visible rows, so scrolling a
    // long unfiltered list stays cheap.
    final user = ref.watch(userProfileProvider).value;
    final flagsAsync = user == null
        ? null
        : ref.watch(
            subjectResourceFlagsProvider((
              university: user.university,
              course: user.course,
              branch: subject.branch,
              sem: subject.sem,
              subject: subject.subject,
            )),
          );
    // Riverpod 3: `value` is null until the first result arrives, so a tile
    // shows no badge while loading and never flickers.
    final flags = flagsAsync?.value;
    final isEmpty = flags != null && flags.values.every((has) => !has);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  subject.abbreviation,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.subject,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF161719),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${subject.branch} · Sem ${subject.sem}',
                    style: TextStyle(fontSize: 12, color: context.faintText),
                  ),
                ],
              ),
            ),
            if (isEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : const Color(0xFFECECF2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'No files yet',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.faintText,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right,
                color: Color(0xFF91919F), size: 20),
          ],
        ),
      ),
    );
  }
}
