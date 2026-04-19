import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme.dart';
import '../../../models/ai_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/study_planner_provider.dart';

/// Lists the user's existing study plans. FAB opens the create flow.
class StudyPlannerScreen extends ConsumerWidget {
  const StudyPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plansAsync = ref.watch(userStudyPlansProvider);
    final bg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF1F1FA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Study Planner',
          style:
              GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/study-planner/create'),
        icon: const Icon(Icons.add),
        label: Text(
          'New Plan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(e.toString()),
        data: (plans) {
          if (plans.isEmpty) return _buildEmpty();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: plans.length,
            itemBuilder: (_, i) => _PlanCard(plan: plans[i], isDark: isDark),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_outlined,
                size: 72, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'No study plans yet.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "New Plan" to let the AI draft a personalized '
              'exam prep schedule.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Text(
          'Could not load your plans.\n$msg',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
        ),
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  final StudyPlan plan;
  final bool isDark;

  const _PlanCard({required this.plan, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysLeft = plan.examDate.difference(DateTime.now()).inDays;
    final progressPct = (plan.progress * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/study-planner/${plan.id}'),
          onLongPress: () => _confirmDelete(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatExamLine(plan),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF161719),
                        ),
                      ),
                    ),
                    _DaysBadge(days: daysLeft),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  plan.subjects.join(' · '),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: plan.progress,
                          minHeight: 6,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation(
                              AppTheme.primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$progressPct%',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
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

  String _formatExamLine(StudyPlan plan) {
    final d = plan.examDate;
    return 'Exam · ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete study plan?'),
        content: const Text(
            'The schedule and task progress will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF0101)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await deleteStudyPlan(uid: uid, planId: plan.id);
  }
}

class _DaysBadge extends StatelessWidget {
  final int days;

  const _DaysBadge({required this.days});

  @override
  Widget build(BuildContext context) {
    final label = days < 0
        ? 'Exam passed'
        : days == 0
            ? 'Today'
            : '$days d left';
    final color = days < 0
        ? Colors.grey
        : days <= 3
            ? const Color(0xFFFF0101)
            : days <= 7
                ? AppTheme.tertiaryColor
                : AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
