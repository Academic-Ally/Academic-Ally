import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/project_copilot_provider.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _titleController = TextEditingController();
  final _briefController = TextEditingController();
  String _type = 'major';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _briefController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty &&
      _briefController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final id = await createProject(
        uid: uid,
        title: _titleController.text.trim(),
        brief: _briefController.text.trim(),
        type: _type,
      );
      if (id != null && mounted) {
        context.pushReplacement('/project-copilot/$id');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _submitting = false;
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
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'New Project',
          style:
              GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              _label('Project title', Icons.title),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _inputDecoration(
                    isDark, 'e.g. Campus Navigator AI'),
              ),
              const SizedBox(height: 20),
              _label('Brief (one paragraph)', Icons.description),
              const SizedBox(height: 8),
              TextField(
                controller: _briefController,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.poppins(fontSize: 13, height: 1.4),
                decoration: _inputDecoration(
                  isDark,
                  'Problem you\'re solving, who it\'s for, and the AI/ML hook.',
                ),
              ),
              const SizedBox(height: 20),
              _label('Project type', Icons.category),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'major', label: Text('Major')),
                  ButtonSegment(value: 'minor', label: Text('Minor')),
                ],
                selected: {_type},
                onSelectionChanged: (v) =>
                    setState(() => _type = v.first),
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
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
                  onPressed:
                      _canSubmit && !_submitting ? _submit : null,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text(
                    _submitting ? 'Creating…' : 'Create',
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

  Widget _label(String t, IconData i) => Row(
        children: [
          Icon(i, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            t,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      );

  InputDecoration _inputDecoration(bool isDark, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13),
      filled: true,
      fillColor: isDark ? Colors.grey[850] : Colors.white,
      contentPadding: const EdgeInsets.all(14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
