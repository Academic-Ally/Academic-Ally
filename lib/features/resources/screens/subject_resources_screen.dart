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
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  ),
                  data: (flags) => Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.3,
                            children: [
                              _ResourceTypeCard(
                                title: 'Notes',
                                icon: Icons.description_outlined,
                                color: const Color(0xFF6360FF),
                                hasResources:
                                    flags[AppConstants.notes] ?? false,
                                onTap: () => _navigateToList(
                                    context, AppConstants.notes),
                              ),
                              _ResourceTypeCard(
                                title: 'Question Papers',
                                icon: Icons.quiz_outlined,
                                color: const Color(0xFFFF8181),
                                hasResources:
                                    flags[AppConstants.questionPapers] ??
                                        false,
                                onTap: () => _navigateToList(
                                    context, AppConstants.questionPapers),
                              ),
                              _ResourceTypeCard(
                                title: 'Other Resources',
                                icon: Icons.folder_outlined,
                                color: const Color(0xFF4CAF50),
                                hasResources:
                                    flags[AppConstants.otherResources] ??
                                        false,
                                onTap: () => _navigateToList(
                                    context, AppConstants.otherResources),
                              ),
                              _ResourceTypeCard(
                                title: 'Syllabus',
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

class _ResourceTypeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool hasResources;
  final VoidCallback onTap;

  const _ResourceTypeCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.hasResources,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF161719),
                      ),
                    ),
                  ),
                  if (hasResources)
                    Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                  if (!hasResources)
                    Text(
                      'Empty',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
