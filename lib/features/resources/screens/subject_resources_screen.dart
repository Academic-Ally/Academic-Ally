import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/resources_provider.dart';

class SubjectResourcesScreen extends ConsumerWidget {
  final String subject;
  final String branch;
  final String sem;
  final String university;
  final String course;

  const SubjectResourcesScreen({
    super.key,
    required this.subject,
    required this.branch,
    required this.sem,
    required this.university,
    required this.course,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final flagsAsync = ref.watch(subjectResourceFlagsProvider((
      university: university,
      course: course,
      branch: branch,
      sem: sem,
      subject: subject,
    )));

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            SizedBox(
              height: size.height * 0.18,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            subject,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF1F1FA),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 52),
                      child: Text(
                        '$branch  |  Semester $sem',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Body
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Theme.of(context).scaffoldBackgroundColor
                      : const Color(0xFFF1F1FA),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: flagsAsync.when(
                  loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.primaryColor)),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Error loading resources: $e',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.faintText),
                      ),
                    ),
                  ),
                  data: (flags) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resource Categories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF161719),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pick a category to browse resources.',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.mutedText,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              _ResourceTypeTile(
                                title: 'Notes',
                                subtitle: 'Topic-wise study notes',
                                icon: Icons.description_outlined,
                                color: const Color(0xFF6360FF),
                                hasResources:
                                    flags[AppConstants.notes] ?? false,
                                onTap: () => _navigateToList(
                                    context, AppConstants.notes),
                              ),
                              const SizedBox(height: 12),
                              _ResourceTypeTile(
                                title: 'Question Papers',
                                subtitle: 'Previous year question papers',
                                icon: Icons.quiz_outlined,
                                color: const Color(0xFFFF8181),
                                hasResources:
                                    flags[AppConstants.questionPapers] ??
                                        false,
                                onTap: () => _navigateToList(
                                    context, AppConstants.questionPapers),
                              ),
                              const SizedBox(height: 12),
                              _ResourceTypeTile(
                                title: 'Other Resources',
                                subtitle: 'Question banks & extras',
                                icon: Icons.folder_outlined,
                                color: const Color(0xFF4CAF50),
                                hasResources:
                                    flags[AppConstants.otherResources] ??
                                        false,
                                onTap: () => _navigateToList(
                                    context, AppConstants.otherResources),
                              ),
                              const SizedBox(height: 12),
                              _ResourceTypeTile(
                                title: 'Syllabus',
                                subtitle: 'Official course syllabus',
                                icon: Icons.menu_book_outlined,
                                color: const Color(0xFFFF9800),
                                hasResources:
                                    flags[AppConstants.syllabus] ?? false,
                                onTap: () => _navigateToList(
                                    context, AppConstants.syllabus),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToList(BuildContext context, String resourceType) {
    context.push(
      '/resources-list'
      '?university=$university'
      '&course=$course'
      '&branch=$branch'
      '&sem=$sem'
      '&subject=${Uri.encodeComponent(subject)}'
      '&type=$resourceType',
    );
  }
}

class _ResourceTypeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool hasResources;
  final VoidCallback onTap;

  const _ResourceTypeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.hasResources,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1F1F26) : Colors.white;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF161719),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (hasResources)
                  Icon(
                    Icons.chevron_right,
                    color: context.faintText,
                    size: 22,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.faintText.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Empty',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: context.mutedText,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
