import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme.dart';
import '../../../models/ai_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/study_planner_provider.dart';

/// Shows one plan day-by-day with task toggles. Writes toggle changes back
/// to Firestore via [toggleStudyTaskCompletion].
class StudyPlanDetailScreen extends ConsumerWidget {
  final String planId;

  const StudyPlanDetailScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF1F1FA);
    final planAsync = ref.watch(studyPlanDetailProvider(planId));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Study Plan',
          style:
              GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Text(
              'Could not load plan.\n$e',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ),
        data: (plan) {
          if (plan == null) {
            return const Center(
              child: Text('Plan not found.'),
            );
          }
          return _buildPlan(context, ref, plan, isDark);
        },
      ),
    );
  }

  Widget _buildPlan(
    BuildContext context,
    WidgetRef ref,
    StudyPlan plan,
    bool isDark,
  ) {
    final uid = ref.watch(currentUserProvider)?.uid;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Exam: ${_fmtDate(plan.examDate)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(plan.progress * 100).round()}%',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.subjects.join(' · '),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: plan.progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation(
                          AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: plan.days.length,
          itemBuilder: (_, dayIndex) => _DayCard(
            day: plan.days[dayIndex],
            dayIndex: dayIndex,
            plan: plan,
            uid: uid,
            isDark: isDark,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _DayCard extends StatelessWidget {
  final StudyDay day;
  final int dayIndex;
  final StudyPlan plan;
  final String? uid;
  final bool isDark;

  const _DayCard({
    required this.day,
    required this.dayIndex,
    required this.plan,
    required this.uid,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final done = day.tasks.where((t) => t.completed).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Material(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _fmtDayHeader(day.date),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF161719),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$done / ${day.tasks.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: context.mutedText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (var t = 0; t < day.tasks.length; t++)
                _TaskTile(
                  task: day.tasks[t],
                  onToggle: uid == null
                      ? null
                      : () => toggleStudyTaskCompletion(
                            uid: uid!,
                            plan: plan,
                            dayIndex: dayIndex,
                            taskIndex: t,
                          ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDayHeader(DateTime d) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(todayOnly).inDays;
    final base =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    if (diff == 0) return '$base  ·  Today';
    if (diff == 1) return '$base  ·  Tomorrow';
    if (diff < 0) return '$base  ·  ${diff.abs()}d ago';
    return '$base  ·  in ${diff}d';
  }
}

class _TaskTile extends StatelessWidget {
  final StudyTask task;
  final VoidCallback? onToggle;

  const _TaskTile({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: task.completed,
                onChanged: onToggle == null ? null : (_) => onToggle!(),
                activeColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${task.subject} · ${task.topic}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF161719),
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${task.durationMinutes} min · ${task.rationale}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: context.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
