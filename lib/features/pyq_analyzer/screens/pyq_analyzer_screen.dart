import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme.dart';
import '../../../models/ai_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../resources/providers/resources_provider.dart';
import '../providers/pyq_analyzer_provider.dart';

/// PYQ Analyzer — scans past question papers for a subject and predicts
/// likely exam questions + topic weights. Core wedge for OU/JNTUH culture.
class PyqAnalyzerScreen extends ConsumerWidget {
  const PyqAnalyzerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF1F1FA);
    final subjectsAsync = ref.watch(recommendedSubjectsProvider);
    final selected = ref.watch(selectedPyqSubjectProvider);
    final profile = ref.watch(userProfileProvider).value;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'PYQ Analyzer',
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
                  .read(selectedPyqSubjectProvider.notifier)
                  .set(subjects.first.subject);
            });
            return const Center(child: CircularProgressIndicator());
          }
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final key = (
            university: profile.university,
            course: profile.course,
            branch: profile.branch,
            sem: profile.sem,
            subject: selected,
          );

          return Column(
            children: [
              _buildPicker(context, ref, isDark, subjects, selected),
              _buildBanner(),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final cachedAsync =
                        ref.watch(cachedPyqAnalysisProvider(key));
                    final runner = ref.watch(pyqAnalyzerProvider);
                    return cachedAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => _error(e.toString()),
                      data: (analysis) {
                        if (runner.isLoading) return _runningState();
                        if (analysis == null) {
                          return _callToAnalyze(
                            ref: ref,
                            subject: selected,
                            university: profile.university,
                            course: profile.course,
                            branch: profile.branch,
                            sem: profile.sem,
                          );
                        }
                        return _buildResults(
                          context,
                          ref,
                          isDark,
                          analysis,
                          onRerun: () => ref
                              .read(pyqAnalyzerProvider.notifier)
                              .runAnalysis(
                                university: profile.university,
                                course: profile.course,
                                branch: profile.branch,
                                sem: profile.sem,
                                subject: selected,
                              ),
                        );
                      },
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

  Widget _buildPicker(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    List<dynamic> subjects,
    String selected,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selected,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down,
                color: AppTheme.primaryColor),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF161719),
            ),
            dropdownColor: isDark ? Colors.grey[900] : Colors.white,
            items: subjects
                .map((s) => DropdownMenuItem<String>(
                      value: s.subject as String,
                      child: Text(s.subject as String),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                ref.read(selectedPyqSubjectProvider.notifier).set(v);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.insights,
                size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Predicts the likely exam questions and topic weights from past papers.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _callToAnalyze({
    required WidgetRef ref,
    required String subject,
    required String university,
    required String course,
    required String branch,
    required String sem,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 18),
            Text(
              'No analysis yet for "$subject".',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () =>
                    ref.read(pyqAnalyzerProvider.notifier).runAnalysis(
                          university: university,
                          course: course,
                          branch: branch,
                          sem: sem,
                          subject: subject,
                        ),
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  'Run Analysis',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
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

  Widget _runningState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 18),
          Text(
            'Analyzing past papers…',
            style:
                GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    PyqAnalysis analysis, {
    required VoidCallback onRerun,
  }) {
    final sortedWeights = analysis.topicWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            Text(
              'Topic Weights',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF161719),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onRerun,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(
                'Re-analyze',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style:
                  TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final e in sortedWeights)
          _WeightRow(topic: e.key, weight: e.value, isDark: isDark),
        const SizedBox(height: 24),
        Text(
          'Likely Questions',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF161719),
          ),
        ),
        const SizedBox(height: 8),
        for (final q in analysis.predictedQuestions)
          _PredictedQuestionCard(question: q, isDark: isDark),
        if (analysis.lastAnalyzed != null) ...[
          const SizedBox(height: 12),
          Text(
            'Last analyzed ${_fmtWhen(analysis.lastAnalyzed!)}',
            style:
                GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ],
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.find_in_page, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No subjects registered for your curriculum yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _error(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Something went wrong.\n$msg',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
        ),
      ),
    );
  }

  String _fmtWhen(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return '${diff.inDays} d ago';
  }
}

class _WeightRow extends StatelessWidget {
  final String topic;
  final double weight;
  final bool isDark;

  const _WeightRow({
    required this.topic,
    required this.weight,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (weight * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              topic,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF161719),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: weight,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor:
                    const AlwaysStoppedAnimation(AppTheme.primaryColor),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '$pct%',
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictedQuestionCard extends StatelessWidget {
  final PredictedQuestion question;
  final bool isDark;

  const _PredictedQuestionCard({
    required this.question,
    required this.isDark,
  });

  Color _likelihoodColor(double l) {
    if (l >= 0.75) return const Color(0xFF4CAF50);
    if (l >= 0.45) return const Color(0xFFFFA726);
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (question.likelihood * 100).round();
    final color = _likelihoodColor(question.likelihood);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$pct% likely',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${question.expectedMarks}M',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                question.topic,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.question,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF161719),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
