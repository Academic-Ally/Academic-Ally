import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme.dart';
import '../../../models/job_model.dart';
import '../providers/jobs_provider.dart';

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF1F1FA);
    final jobsAsync = ref.watch(jobsListProvider);
    final selectedFilter = ref.watch(jobsFilterProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Jobs & Internships',
          style:
              GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/jobs/post'),
        icon: const Icon(Icons.add),
        label: Text(
          'Post a Job',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(ref, isDark, selectedFilter),
          Expanded(
            child: jobsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _error(e.toString()),
              data: (jobs) {
                if (jobs.isEmpty) return _empty(ref, selectedFilter);
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: jobs.length,
                  itemBuilder: (_, i) =>
                      _JobCard(job: jobs[i], isDark: isDark),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
      WidgetRef ref, bool isDark, JobType? selectedFilter) {
    final items = <(JobType?, String)>[
      (null, 'All'),
      (JobType.internship, 'Internships'),
      (JobType.fullTime, 'Full-time'),
      (JobType.partTime, 'Part-time'),
    ];

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          for (final (type, label) in items) ...[
            _FilterChip(
              label: label,
              selected: selectedFilter == type,
              onTap: () => ref.read(jobsFilterProvider.notifier).set(type),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _empty(WidgetRef ref, JobType? filter) {
    if (filter != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'No ${filter.label.toLowerCase()} postings right now.\nTry "All" to see everything.',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No job postings yet.',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Post one yourself, or seed sample listings for demo.',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => seedDemoJobs(ref),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(
                'Seed sample jobs',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _error(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Could not load jobs.\n$msg',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  final bool isDark;

  const _JobCard({required this.job, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/jobs/${job.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _typeColor(job.type).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        job.type.label,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _typeColor(job.type),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (job.postedAt != null)
                      Text(
                        _formatWhen(job.postedAt!),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  job.title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF161719),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.business,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${job.company} · ${job.location}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (job.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final t in job.tags.take(4))
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            t,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _typeColor(JobType t) {
    switch (t) {
      case JobType.internship:
        return AppTheme.tertiaryColor;
      case JobType.fullTime:
        return AppTheme.primaryColor;
      case JobType.partTime:
        return const Color(0xFFFFA726);
    }
  }

  String _formatWhen(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 30) return '${diff.inDays} d ago';
    return '${(diff.inDays / 30).floor()} mo ago';
  }
}
