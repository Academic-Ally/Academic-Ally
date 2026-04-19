import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/theme.dart';
import '../../../models/ai_models.dart';
import '../../auth/providers/auth_provider.dart';
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
          if (items.isEmpty) return _empty();
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
    await _showSolveSheet(context, ref, picked.path);
  }

  Future<void> _showSolveSheet(
    BuildContext context,
    WidgetRef ref,
    String imagePath,
  ) async {
    ref.read(doubtSolverProvider.notifier).reset();
    ref.read(doubtSolverProvider.notifier).solve(imagePath: imagePath);

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

  Widget _empty() {
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
                color: Colors.grey[600],
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
                _buildThumb(),
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
                              color: Colors.grey[600],
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

  Widget _buildThumb() {
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
      child: Icon(Icons.image, color: Colors.grey[500]),
    );
  }
}

class _SolveSheet extends ConsumerWidget {
  final String imagePath;

  const _SolveSheet({required this.imagePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solver = ref.watch(doubtSolverProvider);
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
        child: solver.when(
          loading: () => _loadingBody(scrollController, imagePath),
          error: (e, _) => _errorBody(scrollController, e.toString()),
          data: (solution) {
            if (solution == null) return _loadingBody(scrollController, imagePath);
            return _SolutionBody(
              doubt: solution,
              scrollController: scrollController,
              showImage: false,
            );
          },
        ),
      ),
    );
  }

  Widget _loadingBody(ScrollController c, String path) {
    return ListView(
      controller: c,
      children: [
        _handle(),
        const SizedBox(height: 12),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(path), width: 220, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 32),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Reading the problem and working it out…',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
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
          _StepCard(step: step, isDark: isDark),
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

  const _StepCard({required this.step, required this.isDark});

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
