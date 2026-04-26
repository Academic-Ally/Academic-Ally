import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme.dart';
import '../../../models/ai_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pyq_analyzer/providers/analysis_run_provider.dart';
import '../../resources/providers/resources_provider.dart';
import '../providers/adversarial_examiner_provider.dart';

/// Adversarial Examiner — multi-agent crew that generates trap questions
/// designed to expose blind spots in the student's understanding.
class AdversarialExaminerScreen extends ConsumerWidget {
  const AdversarialExaminerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF1F1FA);
    final subjectsAsync = ref.watch(recommendedSubjectsProvider);
    final selected = ref.watch(selectedExaminerSubjectProvider);
    final profile = ref.watch(userProfileProvider).value;
    final runner = ref.watch(adversarialExaminerProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Adversarial Examiner',
          style:
              GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _error(e.toString()),
        data: (subjects) {
          if (subjects.isEmpty) return _empty();
          if (selected == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(selectedExaminerSubjectProvider.notifier)
                  .set(subjects.first.subject);
            });
            return const Center(child: CircularProgressIndicator());
          }
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              _Picker(
                isDark: isDark,
                subjects: subjects.map((s) => s.subject).toList(),
                selected: selected,
                onChanged: (v) {
                  ref.read(selectedExaminerSubjectProvider.notifier).set(v);
                  ref.read(adversarialExaminerProvider.notifier).reset();
                },
              ),
              const _Banner(),
              Expanded(
                child: _Body(
                  isDark: isDark,
                  runner: runner,
                  onRun: () {
                    ref.read(adversarialExaminerProvider.notifier).runExam(
                          university: profile.university,
                          course: profile.course,
                          branch: profile.branch,
                          sem: profile.sem,
                          subject: selected,
                        );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'No subjects registered for your curriculum yet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      );

  Widget _error(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'Could not load subjects.\n$msg',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      );
}

class _Picker extends StatelessWidget {
  final bool isDark;
  final List<String> subjects;
  final String selected;
  final ValueChanged<String?> onChanged;

  const _Picker({
    required this.isDark,
    required this.subjects,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Subject',
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          filled: true,
          fillColor: isDark ? Colors.grey[850] : Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selected,
            isExpanded: true,
            items: subjects
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.tertiaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: AppTheme.tertiaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'A 4-agent crew generates trap questions designed to expose '
              'blind spots — the kinds students typically get wrong.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[700],
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final bool isDark;
  final ExaminerRunState runner;
  final VoidCallback onRun;

  const _Body({
    required this.isDark,
    required this.runner,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (runner.isLoading) {
      return _RunningView(runId: runner.runId!);
    }
    if (runner.error != null) {
      return _FailedView(error: runner.error.toString(), onRetry: onRun);
    }
    if (runner.result != null) {
      return _ResultView(exam: runner.result!, onRegenerate: onRun);
    }
    return _IdleView(onRun: onRun, isDark: isDark);
  }
}

class _IdleView extends StatelessWidget {
  final VoidCallback onRun;
  final bool isDark;

  const _IdleView({required this.onRun, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology, size: 80, color: AppTheme.tertiaryColor),
            const SizedBox(height: 18),
            Text(
              'Ready to be challenged?',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF161719),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'The crew will mine your indexed papers for trap patterns and '
              'generate questions that expose your weakest spots.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: context.mutedText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              width: 240,
              child: ElevatedButton.icon(
                onPressed: onRun,
                icon: const Icon(Icons.bolt),
                label: Text(
                  'Generate Adversarial Quiz',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tertiaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunningView extends ConsumerWidget {
  final String runId;
  const _RunningView({required this.runId});

  static const _agents = [
    ('topicSelector', 'Topic Selector'),
    ('trapMiner', 'Trap Pattern Miner'),
    ('questionGenerator', 'Adversarial Question Generator'),
    ('formatter', 'Output Formatter'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runAsync = ref.watch(analysisRunProvider(runId));
    return runAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Run unavailable: $e',
            style: GoogleFonts.poppins(fontSize: 12)),
      ),
      data: (run) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'Running 4-agent crew…',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._agents.map((a) {
              final done = run?.isDone(a.$1) ?? false;
              final failed = run?.isFailedAgent(a.$1) ?? false;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      failed
                          ? Icons.error
                          : done
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                      color: failed
                          ? const Color(0xFFFF0101)
                          : done
                              ? Colors.green
                              : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      a.$2,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _FailedView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _FailedView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 56, color: Color(0xFFFF0101)),
            const SizedBox(height: 12),
            Text(
              'Generation failed.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tertiaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final AdversarialExam exam;
  final VoidCallback onRegenerate;
  const _ResultView({required this.exam, required this.onRegenerate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.tertiaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.tertiaryColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.gps_fixed, color: AppTheme.tertiaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  exam.overallFocus,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...exam.questions.asMap().entries.map((e) => _QuestionCard(
              index: e.key + 1,
              question: e.value,
            )),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onRegenerate,
          icon: const Icon(Icons.refresh),
          label: Text(
            'Generate a new set',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.tertiaryColor,
            side: const BorderSide(color: AppTheme.tertiaryColor),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatefulWidget {
  final int index;
  final AdversarialQuestion question;
  const _QuestionCard({required this.index, required this.question});

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _showApproach = false;

  Color _diffColor(String d) {
    switch (d) {
      case 'very_hard':
        return const Color(0xFFFF0101);
      case 'hard':
        return AppTheme.tertiaryColor;
      default:
        return Colors.amber[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final q = widget.question;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.tertiaryColor.withValues(alpha: 0.15),
                child: Text(
                  '${widget.index}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.tertiaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  q.topic,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              _badge('${q.expectedMarks}m', AppTheme.primaryColor),
              const SizedBox(width: 6),
              _badge(q.difficulty.replaceAll('_', ' '), _diffColor(q.difficulty)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            q.question,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF161719),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF0101).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFF0101).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber,
                    size: 16, color: Color(0xFFFF0101)),
                const SizedBox(width: 6),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: 'Trap (${q.trapType}): ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF0101),
                          ),
                        ),
                        TextSpan(text: q.commonMistake),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(() => _showApproach = !_showApproach),
            child: Row(
              children: [
                Icon(
                  _showApproach
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                Text(
                  _showApproach
                      ? 'Hide correct approach'
                      : 'Show correct approach',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (_showApproach) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      q.correctApproach,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
}
