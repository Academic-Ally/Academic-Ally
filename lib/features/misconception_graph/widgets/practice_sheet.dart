import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme.dart';
import '../../../models/ai_models.dart';
import '../providers/misconception_graph_provider.dart';

/// Practice loop for a single knowledge node.
///
/// Flow:
///  1. Show a generated question stem for the topic.
///  2. User types their explanation and submits.
///  3. User self-assesses "Got it" / "Unsure" (Phase 2 has no real grader).
///  4. Screen displays the AI's misconception tagging + new mastery score.
class PracticeSheet extends ConsumerStatefulWidget {
  final KnowledgeNode node;

  const PracticeSheet({super.key, required this.node});

  @override
  ConsumerState<PracticeSheet> createState() => _PracticeSheetState();
}

class _PracticeSheetState extends ConsumerState<PracticeSheet> {
  final _answerController = TextEditingController();
  bool? _selfAssessed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(practiceProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  String get _questionStem =>
      'Explain the core idea of "${widget.node.topic}" and give one concrete '
      'example. Two sentences is enough.';

  String get _modelAnswer =>
      'The core idea of "${widget.node.topic}" is its key invariant and the '
      'operations it supports efficiently. Real systems use it to balance '
      'trade-offs between time and memory.';

  Future<void> _onSubmit() async {
    final self = _selfAssessed;
    if (self == null) return;
    await ref.read(practiceProvider.notifier).submit(
          node: widget.node,
          questionText: _questionStem,
          userAnswer: _answerController.text.trim(),
          correctAnswer: _modelAnswer,
          treatAsCorrect: self,
        );
  }

  @override
  Widget build(BuildContext context) {
    final practice = ref.watch(practiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.grey[900] : const Color(0xFFF1F1FA);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: practice.when(
                data: (result) => result == null
                    ? _buildForm(scrollController, isDark)
                    : _buildResult(result, isDark, scrollController),
                loading: () => _buildLoading(scrollController, isDark),
                error: (e, _) => _buildError(e, scrollController, isDark),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sheetHandle() => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _buildForm(ScrollController scrollController, bool isDark) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _sheetHandle(),
        Text(
          widget.node.topic,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF161719),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.node.subject,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: context.mutedText,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.help_outline,
                      size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Question',
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
                _questionStem,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF161719),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Your Answer',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _answerController,
          maxLines: 5,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF161719),
          ),
          decoration: InputDecoration(
            hintText: 'Write 1–3 sentences explaining the concept…',
            hintStyle: GoogleFonts.poppins(color: context.faintText),
            filled: true,
            fillColor: isDark ? Colors.grey[850] : Colors.white,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Self-assess: how confident are you?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SelfAssessChip(
                label: 'Got it',
                icon: Icons.check_circle_outline,
                selected: _selfAssessed == true,
                color: const Color(0xFF4CAF50),
                onTap: () => setState(() => _selfAssessed = true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SelfAssessChip(
                label: 'Unsure / Got it wrong',
                icon: Icons.replay,
                selected: _selfAssessed == false,
                color: AppTheme.tertiaryColor,
                onTap: () => setState(() => _selfAssessed = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _selfAssessed == null ? null : _onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Submit',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLoading(ScrollController scrollController, bool isDark) {
    return ListView(
      controller: scrollController,
      children: [
        _sheetHandle(),
        const SizedBox(height: 80),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'AI is analyzing your answer…',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: context.mutedText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(
    PracticeResult result,
    bool isDark,
    ScrollController scrollController,
  ) {
    final masteryPct = (result.mastery.score * 100).round();
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _sheetHandle(),
        Icon(
          result.wasCorrect ? Icons.emoji_events : Icons.insights,
          size: 56,
          color: result.wasCorrect
              ? const Color(0xFF4CAF50)
              : AppTheme.tertiaryColor,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            result.wasCorrect
                ? 'Great — mastery increased!'
                : 'Honest answer. Here\'s what we noticed.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF161719),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Mastery of "${widget.node.topic}"',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: result.mastery.score,
            minHeight: 10,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
                _masteryColor(result.mastery.score)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$masteryPct% — ${result.mastery.attempts} attempts recorded',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: context.mutedText,
          ),
        ),
        const SizedBox(height: 24),
        if (result.newMisconceptions.isNotEmpty) ...[
          Text(
            'Misconceptions identified',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.tertiaryColor,
            ),
          ),
          const SizedBox(height: 8),
          for (final m in result.newMisconceptions)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.tertiaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.tertiaryColor.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                m.description,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF161719),
                  height: 1.4,
                ),
              ),
            ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Done',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildError(
    Object error,
    ScrollController scrollController,
    bool isDark,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _sheetHandle(),
        const SizedBox(height: 40),
        Icon(Icons.error_outline, size: 56, color: context.mutedText),
        const SizedBox(height: 16),
        Text(
          'Something went wrong.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error.toString(),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 12, color: context.mutedText),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            ref.read(practiceProvider.notifier).reset();
          },
          child: const Text('Try again'),
        ),
      ],
    );
  }

  Color _masteryColor(double score) {
    if (score >= 0.7) return const Color(0xFF4CAF50);
    if (score >= 0.4) return const Color(0xFFFFA726);
    return AppTheme.tertiaryColor;
  }
}

class _SelfAssessChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SelfAssessChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color:
              selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey[400]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? color : context.mutedText),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
