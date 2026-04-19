import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme.dart';
import '../../../models/ai_models.dart';
import '../../../models/subject_model.dart';
import '../../resources/providers/resources_provider.dart';
import '../providers/misconception_graph_provider.dart';
import '../widgets/practice_sheet.dart';

/// Knowledge Map — the UI surface of the Misconception Graph feature.
///
/// Top: subject picker defaulting to the user's curriculum.
/// Body: list of topic nodes, each showing its mastery bar and any active
///       misconception chip.
/// Tap a topic → [PracticeSheet] bottom sheet.
class KnowledgeMapScreen extends ConsumerStatefulWidget {
  const KnowledgeMapScreen({super.key});

  @override
  ConsumerState<KnowledgeMapScreen> createState() =>
      _KnowledgeMapScreenState();
}

class _KnowledgeMapScreenState extends ConsumerState<KnowledgeMapScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF1F1FA);
    final selected = ref.watch(selectedKnowledgeSubjectProvider);
    final subjectsAsync = ref.watch(recommendedSubjectsProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Knowledge Map',
          style:
              GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _buildEmpty(isDark,
            'Could not load your subjects. Please try again later.'),
        data: (subjects) {
          if (subjects.isEmpty) {
            return _buildEmpty(
              isDark,
              'No subjects registered for your branch and semester yet.\n'
              'Add resources first, then come back to map your topics.',
            );
          }

          if (selected == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(selectedKnowledgeSubjectProvider.notifier)
                  .set(subjects.first.subject);
            });
            return const Center(child: CircularProgressIndicator());
          }

          return _buildContent(context, isDark, subjects, selected);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isDark,
    List<SubjectModel> subjects,
    String selectedSubject,
  ) {
    final nodes = ref.watch(knowledgeNodesProvider(selectedSubject));
    final masteryAsync = ref.watch(userMasteryStreamProvider);
    final misconceptionsAsync = ref.watch(userMisconceptionsStreamProvider);

    final mastery = masteryAsync.value ?? const <String, MasteryScore>{};
    final misconceptions =
        misconceptionsAsync.value ?? const <String, Misconception>{};

    return Column(
      children: [
        Padding(
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
                value: selectedSubject,
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
                          value: s.subject,
                          child: Text(s.subject),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(selectedKnowledgeSubjectProvider.notifier)
                        .set(val);
                  }
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap a topic to practice. The AI tags misconceptions and updates your mastery in real time.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: nodes.length,
            itemBuilder: (context, i) {
              final node = nodes[i];
              return _TopicCard(
                node: node,
                mastery: mastery[node.id],
                misconception: misconceptions[node.id],
                onTap: () => _openPractice(node),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(bool isDark, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_graph, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPractice(KnowledgeNode node) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PracticeSheet(node: node),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final KnowledgeNode node;
  final MasteryScore? mastery;
  final Misconception? misconception;
  final VoidCallback onTap;

  const _TopicCard({
    required this.node,
    required this.mastery,
    required this.misconception,
    required this.onTap,
  });

  Color _masteryColor(double s) {
    if (s >= 0.7) return const Color(0xFF4CAF50);
    if (s >= 0.4) return const Color(0xFFFFA726);
    return AppTheme.tertiaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final score = mastery?.score ?? 0.0;
    final attempts = mastery?.attempts ?? 0;
    final hasMisconception = misconception != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        node.topic,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF161719),
                        ),
                      ),
                    ),
                    if (hasMisconception)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.tertiaryColor
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lightbulb_outline,
                                size: 12, color: AppTheme.tertiaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'misconception',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.tertiaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: score,
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _masteryColor(score)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${(score * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _masteryColor(score),
                        ),
                      ),
                    ),
                  ],
                ),
                if (attempts > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '$attempts attempts',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
