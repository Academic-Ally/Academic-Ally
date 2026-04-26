import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/theme.dart';
import '../../../models/ai_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pyq_analyzer/providers/analysis_run_provider.dart';
import '../../resources/providers/resources_provider.dart';
import '../providers/snap_doubt_provider.dart';

/// Main Snap-a-Doubt screen: shows history list + FAB to capture a new doubt.
class SnapDoubtScreen extends ConsumerWidget {
  const SnapDoubtScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF1F1FA);
    final historyAsync = ref.watch(doubtHistoryProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Snap a Doubt',
          style:
              GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _showCaptureSheet(context, ref),
        icon: const Icon(Icons.camera_alt),
        label: Text(
          'New Doubt',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _error(e.toString()),
        data: (items) {
          if (items.isEmpty) return _empty(context);
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            itemBuilder: (_, i) => _DoubtCard(
              doubt: items[i],
              isDark: isDark,
              onOpen: () => _showSolutionSheet(context, items[i]),
              onDelete: () => _confirmDelete(context, ref, items[i].id),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCaptureSheet(BuildContext context, WidgetRef ref) async {
    // 1. Pick subject first — backend's RAG search needs it.
    final subject = await _pickSubject(context, ref);
    if (subject == null) return;

    if (!context.mounted) return;
    // 2. Pick image source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt,
                  color: AppTheme.primaryColor),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo, color: AppTheme.primaryColor),
              title: const Text('Pick from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;

    if (!context.mounted) return;
    await _showSolveSheet(context, ref, picked.path, subject);
  }

  Future<String?> _pickSubject(BuildContext context, WidgetRef ref) async {
    final subjects = await ref.read(recommendedSubjectsProvider.future);
    if (subjects.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No subjects in your curriculum yet.')),
        );
      }
      return null;
    }
    if (!context.mounted) return null;
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.school, color: AppTheme.primaryColor),
                  const SizedBox(width: 10),
                  Text(
                    'Which subject is your doubt from?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView(
                shrinkWrap: true,
                children: subjects
                    .map(
                      (s) => ListTile(
                        title: Text(s.subject),
                        onTap: () => Navigator.pop(context, s.subject),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showSolveSheet(
    BuildContext context,
    WidgetRef ref,
    String imagePath,
    String subject,
  ) async {
    // Defer the state mutations to a microtask so they don't fire during
    // the same frame where the modal is mounting. Riverpod 3.x flags
    // synchronous provider mutations that overlap a widget build phase.
    final notifier = ref.read(doubtSolverProvider.notifier);
    Future.microtask(() {
      notifier.reset();
      notifier.solve(imagePath: imagePath, subject: subject);
    });

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SolveSheet(imagePath: imagePath),
    );
  }

  Future<void> _showSolutionSheet(
    BuildContext context,
    DoubtSolution doubt,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SolutionSheet(doubt: doubt),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete doubt?'),
        content: const Text('This solution will be removed from your history.'),
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
    await deleteDoubt(uid: uid, doubtId: id);
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_outlined, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Stuck on a problem?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Snap a photo of any handwritten or textbook problem — the AI returns a step-by-step solution.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: context.mutedText,
                height: 1.4,
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
            'Could not load history.\n$msg',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      );
}

class _DoubtCard extends StatelessWidget {
  final DoubtSolution doubt;
  final bool isDark;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _DoubtCard({
    required this.doubt,
    required this.isDark,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onOpen,
          onLongPress: onDelete,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumb(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doubt.extractedQuestion,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF161719),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              doubt.topic,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Answer: ${doubt.finalAnswer}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: context.mutedText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumb(BuildContext context) {
    final file = File(doubt.imageUrl);
    if (file.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image, color: context.faintText),
    );
  }
}

class _SolveSheet extends ConsumerWidget {
  final String imagePath;

  const _SolveSheet({required this.imagePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(doubtSolverProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : const Color(0xFFF1F1FA),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _buildBody(scrollController, state),
      ),
    );
  }

  Widget _buildBody(ScrollController c, DoubtRunState state) {
    if (state.error != null) {
      return _errorBody(c, state.error.toString());
    }
    if (state.result != null) {
      return _SolutionBody(
        doubt: state.result!,
        scrollController: c,
        showImage: false,
      );
    }
    // Loading: show image + live agent checkmarks (or generic spinner if no run_id)
    return _loadingBody(c, imagePath, state.runId);
  }

  Widget _loadingBody(ScrollController c, String path, String? runId) {
    return ListView(
      controller: c,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _handle(),
        const SizedBox(height: 8),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(path), width: 200, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 24),
        if (runId != null)
          _AgentChecklist(runId: runId)
        else
          const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _errorBody(ScrollController c, String msg) {
    return ListView(
      controller: c,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        _handle(),
        const SizedBox(height: 40),
        const Icon(Icons.error_outline, size: 56, color: Colors.grey),
        const SizedBox(height: 12),
        Text(
          'Could not solve this doubt.\n$msg',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
        ),
      ],
    );
  }
}

class _AgentChecklist extends ConsumerWidget {
  final String runId;
  const _AgentChecklist({required this.runId});

  static const _agents = [
    ('vision', 'Vision Extractor'),
    ('retriever', 'Notes Retriever'),
    ('solver', 'Step Solver'),
    ('validator', 'Solution Validator'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runAsync = ref.watch(analysisRunProvider(runId));
    return runAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(
        'Run unavailable: $e',
        style: GoogleFonts.poppins(fontSize: 12),
      ),
      data: (run) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  '4 agents working on your doubt…',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
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

class _SolutionSheet extends StatelessWidget {
  final DoubtSolution doubt;

  const _SolutionSheet({required this.doubt});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : const Color(0xFFF1F1FA),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _SolutionBody(
          doubt: doubt,
          scrollController: scrollController,
          showImage: true,
        ),
      ),
    );
  }
}

class _SolutionBody extends StatelessWidget {
  final DoubtSolution doubt;
  final ScrollController scrollController;
  final bool showImage;

  const _SolutionBody({
    required this.doubt,
    required this.scrollController,
    required this.showImage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final file = File(doubt.imageUrl);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _handle(),
        if (showImage && file.existsSync())
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(file,
                    width: 200, fit: BoxFit.contain),
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Problem',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                doubt.extractedQuestion,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF161719),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Solution',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        for (final step in doubt.steps)
          _StepCard(step: step, isDark: isDark, doubt: doubt),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Final Answer',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    Text(
                      doubt.finalAnswer,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? Colors.white : const Color(0xFF161719),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final SolutionStep step;
  final bool isDark;
  final DoubtSolution doubt;

  const _StepCard({
    required this.step,
    required this.isDark,
    required this.doubt,
  });

  void _openCitation(BuildContext context, SolutionCitation citation) {
    final storageId = citation.storageId;
    if (storageId == null || storageId.isEmpty) return;

    final params = <String, String>{
      'id': citation.resourceId ?? '',
      'name': citation.filename,
      'subject': doubt.subject ?? '',
      'category': citation.category ?? 'Notes',
      'university': '',
      'course': '',
      'branch': '',
      'sem': '',
      'storageId': storageId,
      'type': citation.category ?? 'Notes',
      'page': '${citation.pageStart}',
    };
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    context.push('/pdf-viewer?$qs');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step.index}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color:
                        isDark ? Colors.white : const Color(0xFF161719),
                    height: 1.4,
                  ),
                ),
                if (step.citations.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: step.citations
                        .map((c) => _CitationChip(
                              citation: c,
                              onTap: c.isClickable
                                  ? () => _openCitation(context, c)
                                  : null,
                            ))
                        .toList(),
                  ),
                ],
                if (step.latex != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      step.latex!,
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: const Color(0xFF161719),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _handle() => Center(
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

class _CitationChip extends StatelessWidget {
  final SolutionCitation citation;
  final VoidCallback? onTap;

  const _CitationChip({required this.citation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final clickable = onTap != null;
    final color = clickable ? AppTheme.primaryColor : Colors.grey;
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                clickable ? Icons.menu_book_rounded : Icons.menu_book_outlined,
                size: 13,
                color: color,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '${citation.filename}  ·  ${citation.pageLabel}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (clickable) ...[
                const SizedBox(width: 4),
                Icon(Icons.open_in_new, size: 12, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
