import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../models/subject_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../resources/providers/resources_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final contentBg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF1F1FA);

    return Scaffold(
      backgroundColor: contentBg,
      body: SafeArea(
        child: Stack(
          children: [
            // Purple header background
            Container(
              height: size.height * 0.15,
              color: AppTheme.primaryColor,
            ),

            Column(
              children: [
                // Header with user info
                Padding(
                  padding: EdgeInsets.only(
                    top: size.height * 0.02,
                    left: size.width * 0.05,
                    right: size.width * 0.05,
                    bottom: size.height * 0.02,
                  ),
                  child: Row(
                    children: [
                      // Profile pic
                      userProfile.when(
                        data: (user) => GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: size.width * 0.14,
                            height: size.width * 0.14,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F1FA),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: user?.pfp != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Image.network(
                                      user!.pfp!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      user?.name.isNotEmpty == true
                                          ? user!.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        loading: () => Container(
                          width: size.width * 0.14,
                          height: size.width * 0.14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F1FA),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 10),
                      // Welcome text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back',
                              style: TextStyle(
                                color: const Color(0xFFF1F1FA),
                                fontSize: size.height * 0.02,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            userProfile.when(
                              data: (user) => Text(
                                user?.name ?? '',
                                style: TextStyle(
                                  color: const Color(0xFFF1F1FA),
                                  fontSize: size.height * 0.018,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      // Theme toggle
                      IconButton(
                        icon: Icon(
                          themeMode == ThemeMode.dark
                              ? Icons.wb_sunny
                              : Icons.nightlight_round,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                      ),
                    ],
                  ),
                ),

                // Main content area with rounded top
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: contentBg,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(top: size.height * 0.02),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Access icons
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _QuickAccessItem(
                                  icon: Icons.smart_toy_outlined,
                                  label: 'AllyBot',
                                  color: const Color(0xFF6360FF),
                                  onTap: () => context.push('/allybot'),
                                ),
                                _QuickAccessItem(
                                  icon: Icons.volunteer_activism,
                                  label: 'SeekHub',
                                  color: const Color(0xFFFF8181),
                                  onTap: () => context.push('/seekhub'),
                                ),
                                _QuickAccessItem(
                                  icon: Icons.history,
                                  label: 'Recents',
                                  color: const Color(0xFF4CAF50),
                                  onTap: () => context.push('/recents'),
                                ),
                                _QuickAccessItem(
                                  icon: Icons.download_rounded,
                                  label: 'Downloads',
                                  color: const Color(0xFFFF9800),
                                  onTap: () => context.push('/downloads'),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: size.height * 0.03),

                          // AI Tools section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome,
                                    size: 18, color: AppTheme.primaryColor),
                                const SizedBox(width: 6),
                                Text(
                                  'AI Tools',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF161719),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 110,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              children: [
                                _AiToolCard(
                                  icon: Icons.insights,
                                  title: 'Knowledge Map',
                                  subtitle: 'Track your topic mastery',
                                  color: AppTheme.primaryColor,
                                  onTap: () => context.push('/knowledge-map'),
                                ),
                                _AiToolCard(
                                  icon: Icons.event_note,
                                  title: 'Study Planner',
                                  subtitle: 'Personalized exam prep',
                                  color: AppTheme.tertiaryColor,
                                  onTap: () => context.push('/study-planner'),
                                ),
                                _AiToolCard(
                                  icon: Icons.widgets_outlined,
                                  title: 'Gen UI',
                                  subtitle: 'AI picks the layout',
                                  color: const Color(0xFF9C27B0),
                                  onTap: () => context.push('/gen-ui'),
                                ),
                                // More cards land here as Phase 2 ships
                                // (PYQ Analyzer, Snap-a-Doubt, Project Copilot).
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Recommended section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Text(
                                  'Recommended',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF161719),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.tertiaryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.tertiaryColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Text(
                                    'All',
                                    style: TextStyle(
                                      color: AppTheme.tertiaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Recommended subjects
                          _RecommendedSubjects(isDark: isDark),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AiToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AiToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            width: 180,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF161719),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAccessItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : const Color(0xFF161719),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedSubjects extends ConsumerWidget {
  final bool isDark;

  const _RecommendedSubjects({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendedAsync = ref.watch(recommendedSubjectsProvider);

    return recommendedAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (subjects) {
        if (subjects.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'No subjects found for your current semester.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: subjects
                .map((s) => _SubjectCard(subject: s, isDark: isDark))
                .toList(),
          ),
        );
      },
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  final bool isDark;

  const _SubjectCard({required this.subject, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final user =
        ProviderScope.containerOf(context).read(userProfileProvider).value;

    return GestureDetector(
      onTap: () {
        context.push(
          '/subject-resources'
          '?subject=${Uri.encodeComponent(subject.subject)}'
          '&branch=${subject.branch}'
          '&sem=${subject.sem}'
          '&university=${user?.university ?? ''}'
          '&course=${user?.course ?? ''}',
        );
      },
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
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF91919F), size: 20),
          ],
        ),
      ),
    );
  }
}
