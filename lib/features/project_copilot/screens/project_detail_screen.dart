import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme.dart';
import '../../../models/ai_models.dart';
import '../../../models/project_model.dart';
import '../providers/project_copilot_provider.dart';

/// Project detail — 4 phase tabs, each showing cached guidance or a
/// "Get Guidance" CTA that calls MockAIService and caches the response on
/// the project doc.
class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  static const _phases = ProjectPhase.values;

  late final TabController _tabs;

  /// Per-phase state: 'loading', 'error', or absent (idle / use cached).
  final Map<ProjectPhase, String> _phaseStatus = {};
  final Map<ProjectPhase, String> _phaseError = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _phases.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _requestGuidance(ProjectModel project, ProjectPhase phase) async {
    setState(() {
      _phaseStatus[phase] = 'loading';
      _phaseError.remove(phase);
    });
    try {
      await requestPhaseGuidance(ref: ref, project: project, phase: phase);
      if (mounted) setState(() => _phaseStatus.remove(phase));
    } catch (e) {
      if (mounted) {
        setState(() {
          _phaseStatus[phase] = 'error';
          _phaseError[phase] = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF1F1FA);
    final projectAsync =
        ref.watch(projectDetailProvider(widget.projectId));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Project Copilot',
          style:
              GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          tabs: _phases
              .map((p) => Tab(text: _phaseLabel(p)))
              .toList(),
        ),
      ),
      body: projectAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Could not load project.\n$e',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ),
        data: (project) {
          if (project == null) {
            return const Center(child: Text('Project not found.'));
          }
          return Column(
            children: [
              _ProjectHeader(project: project, isDark: isDark),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: _phases
                      .map((p) => _PhaseTab(
                            project: project,
                            phase: p,
                            status: _phaseStatus[p],
                            errorText: _phaseError[p],
                            onRequest: () => _requestGuidance(project, p),
                          ))
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _phaseLabel(ProjectPhase p) {
    switch (p) {
      case ProjectPhase.ideation:
        return 'Ideation';
      case ProjectPhase.litReview:
        return 'Lit Review';
      case ProjectPhase.scaffolding:
        return 'Scaffolding';
      case ProjectPhase.report:
        return 'Report';
    }
  }
}

class _ProjectHeader extends StatelessWidget {
  final ProjectModel project;
  final bool isDark;

  const _ProjectHeader({required this.project, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  project.type.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  project.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color:
                        isDark ? Colors.white : const Color(0xFF161719),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            project.brief,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseTab extends StatelessWidget {
  final ProjectModel project;
  final ProjectPhase phase;
  final String? status;
  final String? errorText;
  final VoidCallback onRequest;

  const _PhaseTab({
    required this.project,
    required this.phase,
    required this.status,
    required this.errorText,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final cached = project.cachedGuidance[phase.wire];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (status == 'loading') {
      return const Center(child: CircularProgressIndicator());
    }

    if (cached != null) {
      return _GuidanceView(
        guidance: cached,
        isDark: isDark,
        onRerun: onRequest,
      );
    }

    return _EmptyState(
      phase: phase,
      isDark: isDark,
      errorText: errorText,
      onGenerate: onRequest,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ProjectPhase phase;
  final bool isDark;
  final String? errorText;
  final VoidCallback onGenerate;

  const _EmptyState({
    required this.phase,
    required this.isDark,
    required this.errorText,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconFor(phase), size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _descFor(phase),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onGenerate,
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  'Get Guidance',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 16),
              Text(
                errorText!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFFFF0101),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(ProjectPhase p) {
    switch (p) {
      case ProjectPhase.ideation:
        return Icons.lightbulb_outline;
      case ProjectPhase.litReview:
        return Icons.menu_book;
      case ProjectPhase.scaffolding:
        return Icons.architecture;
      case ProjectPhase.report:
        return Icons.article_outlined;
    }
  }

  String _descFor(ProjectPhase p) {
    switch (p) {
      case ProjectPhase.ideation:
        return 'Scope check and next steps to turn your idea into a shippable 12-week plan.';
      case ProjectPhase.litReview:
        return 'Anchor papers and a structured way to frame the research gap.';
      case ProjectPhase.scaffolding:
        return 'Starter architecture and a path from hello-world to working prototype.';
      case ProjectPhase.report:
        return 'Section-by-section report template aligned with engineering project norms.';
    }
  }
}

class _GuidanceView extends StatelessWidget {
  final ProjectGuidance guidance;
  final bool isDark;
  final VoidCallback onRerun;

  const _GuidanceView({
    required this.guidance,
    required this.isDark,
    required this.onRerun,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildCard(
          isDark,
          title: 'Summary',
          child: Text(
            guidance.summary,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF161719),
              height: 1.45,
            ),
          ),
        ),
        _buildCard(
          isDark,
          title: 'Key Points',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final b in guidance.bullets) _bulletRow(b, isDark),
            ],
          ),
        ),
        _buildCard(
          isDark,
          title: 'Next Steps',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < guidance.nextSteps.length; i++)
                _numberedRow(i + 1, guidance.nextSteps[i], isDark),
            ],
          ),
        ),
        if (guidance.references.isNotEmpty)
          _buildCard(
            isDark,
            title: 'References',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final r in guidance.references)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      r,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (guidance.codeSnippet != null)
          _buildCard(
            isDark,
            title: 'Starter Snippet',
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF161719),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                guidance.codeSnippet!,
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  color: const Color(0xFFF1F1FA),
                  height: 1.4,
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onRerun,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(
              'Regenerate',
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style:
                TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(bool isDark,
      {required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _bulletRow(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.4,
                color: isDark ? Colors.white : const Color(0xFF161719),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberedRow(int n, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$n',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.4,
                color: isDark ? Colors.white : const Color(0xFF161719),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
