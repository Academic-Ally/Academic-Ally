import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme.dart';
import '../../../models/job_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/jobs_provider.dart';

class JobDetailScreen extends ConsumerWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF1F1FA);
    final jobAsync = ref.watch(jobDetailProvider(jobId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Job Details',
          style:
              GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          jobAsync.when(
            data: (job) {
              if (job != null &&
                  currentUser != null &&
                  job.postedBy == currentUser.uid) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, jobId),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Could not load job.\n$e',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ),
        data: (job) {
          if (job == null) {
            return const Center(child: Text('Job not found.'));
          }
          return _buildBody(context, job, isDark);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, JobModel job, bool isDark) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _typeColor(job.type).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      job.type.label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _typeColor(job.type),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (job.postedAt != null)
                    Text(
                      'Posted ${_formatWhen(job.postedAt!)}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: context.faintText,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                job.title,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF161719),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${job.company} · ${job.location}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: context.mutedText,
                      ),
                    ),
                  ),
                ],
              ),
              if (job.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final t in job.tags)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'About the role',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                job.description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF161719),
                  height: 1.5,
                ),
              ),
              if (job.postedByName != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Posted by ${job.postedByName}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: context.faintText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: job.applyUrl.isEmpty
                  ? null
                  : () => _applyExternal(context, job.applyUrl),
              icon: const Icon(Icons.open_in_new),
              label: Text(
                job.applyUrl.isEmpty ? 'No apply link' : 'Apply',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _applyExternal(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the apply link.'),
            backgroundColor: Color(0xFFFF0101),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open the link: $e'),
            backgroundColor: const Color(0xFFFF0101),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, String jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this posting?'),
        content: const Text(
            'The job listing will be removed for everyone. Cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFFF0101)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await deleteJob(jobId);
    if (context.mounted) Navigator.pop(context);
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
