import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme.dart';
import '../../resources/providers/resources_provider.dart';
import '../providers/study_planner_provider.dart';

/// Form that collects exam date + subjects + daily minutes, then calls
/// the mock AI to generate a StudyPlan and navigates to its detail screen.
class CreateStudyPlanScreen extends ConsumerStatefulWidget {
  const CreateStudyPlanScreen({super.key});

  @override
  ConsumerState<CreateStudyPlanScreen> createState() =>
      _CreateStudyPlanScreenState();
}

class _CreateStudyPlanScreenState
    extends ConsumerState<CreateStudyPlanScreen> {
  DateTime? _examDate;
  final Set<String> _selectedSubjects = {};
  int _dailyMinutes = 120;

  bool get _canSubmit =>
      _examDate != null &&
      _selectedSubjects.isNotEmpty &&
      _dailyMinutes >= 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studyPlanCreatorProvider.notifier).reset();
    });
  }

  Future<void> _pickExamDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _examDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final id = await ref.read(studyPlanCreatorProvider.notifier).generate(
          examDate: _examDate!,
          subjects: _selectedSubjects.toList(),
          dailyStudyMinutes: _dailyMinutes,
        );
    if (id != null && mounted) {
      context.pushReplacement('/study-planner/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF1F1FA);
    final subjectsAsync = ref.watch(recommendedSubjectsProvider);
    final creator = ref.watch(studyPlanCreatorProvider);
    final isGenerating = creator.isLoading;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'New Study Plan',
          style:
              GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              _sectionHeader('When is your exam?', Icons.event),
              const SizedBox(height: 8),
              Material(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickExamDate,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _examDate == null
                                ? 'Pick a date'
                                : '${_examDate!.day.toString().padLeft(2, '0')}/${_examDate!.month.toString().padLeft(2, '0')}/${_examDate!.year}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _examDate == null
                                  ? Colors.grey[500]
                                  : (isDark
                                      ? Colors.white
                                      : const Color(0xFF161719)),
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_right,
                            color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _sectionHeader('Subjects to cover', Icons.menu_book),
              const SizedBox(height: 8),
              subjectsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => _sectionHint(
                    'Could not load your subjects. Retry later.'),
                data: (subjects) {
                  if (subjects.isEmpty) {
                    return _sectionHint(
                        'No subjects registered for your curriculum yet.');
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subjects.map((s) {
                      final selected = _selectedSubjects.contains(s.subject);
                      return FilterChip(
                        label: Text(s.subject),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _selectedSubjects.add(s.subject);
                          } else {
                            _selectedSubjects.remove(s.subject);
                          }
                        }),
                        selectedColor:
                            AppTheme.primaryColor.withValues(alpha: 0.2),
                        checkmarkColor: AppTheme.primaryColor,
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppTheme.primaryColor
                              : Colors.grey[700],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              _sectionHeader(
                  'Daily study time · $_dailyMinutes min', Icons.timer),
              const SizedBox(height: 4),
              Slider(
                value: _dailyMinutes.toDouble(),
                min: 30,
                max: 360,
                divisions: 11,
                label: '$_dailyMinutes min',
                activeColor: AppTheme.primaryColor,
                onChanged: (v) => setState(() => _dailyMinutes = v.round()),
              ),
              if (creator.hasError)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0101).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFF0101).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    creator.error.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFFFF0101),
                    ),
                  ),
                ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _canSubmit && !isGenerating ? _submit : null,
                  icon: isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    isGenerating ? 'Generating…' : 'Generate Plan',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
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
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _sectionHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
      ),
    );
  }
}
