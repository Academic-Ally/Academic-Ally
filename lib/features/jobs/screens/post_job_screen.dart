import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme.dart';
import '../../../models/job_model.dart';
import '../providers/jobs_provider.dart';

class PostJobScreen extends ConsumerStatefulWidget {
  const PostJobScreen({super.key});

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final _title = TextEditingController();
  final _company = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  final _applyUrl = TextEditingController();
  final _tags = TextEditingController();
  JobType _type = JobType.internship;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _company.dispose();
    _location.dispose();
    _description.dispose();
    _applyUrl.dispose();
    _tags.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _title.text.trim().isNotEmpty &&
      _company.text.trim().isNotEmpty &&
      _description.text.trim().isNotEmpty &&
      _applyUrl.text.trim().isNotEmpty &&
      _isValidUrl(_applyUrl.text.trim());

  bool _isValidUrl(String s) {
    final uri = Uri.tryParse(s);
    return uri != null && uri.hasScheme && (uri.isScheme('http') || uri.isScheme('https'));
  }

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final tagList = _tags.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      final id = await createJob(
        ref: ref,
        title: _title.text.trim(),
        company: _company.text.trim(),
        location: _location.text.trim(),
        type: _type,
        description: _description.text.trim(),
        applyUrl: _applyUrl.text.trim(),
        tags: tagList,
      );
      if (id != null && mounted) {
        context.pushReplacement('/jobs/$id');
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
          'Post a Job',
          style:
              GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              _label('Job title *', Icons.title),
              const SizedBox(height: 6),
              _field(_title, 'e.g. Flutter Developer Intern', isDark),
              const SizedBox(height: 16),
              _label('Company *', Icons.business),
              const SizedBox(height: 6),
              _field(_company, 'e.g. Razorpay', isDark),
              const SizedBox(height: 16),
              _label('Location', Icons.place),
              const SizedBox(height: 6),
              _field(_location, 'e.g. Hyderabad · Hybrid', isDark),
              const SizedBox(height: 16),
              _label('Type', Icons.category),
              const SizedBox(height: 6),
              SegmentedButton<JobType>(
                segments: JobType.values
                    .map((t) =>
                        ButtonSegment(value: t, label: Text(t.label)))
                    .toList(),
                selected: {_type},
                onSelectionChanged: (v) =>
                    setState(() => _type = v.first),
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _label('Description *', Icons.description),
              const SizedBox(height: 6),
              _field(
                _description,
                'What does the role involve?',
                isDark,
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              _label('Apply URL *', Icons.link),
              const SizedBox(height: 6),
              _field(
                _applyUrl,
                'https://...',
                isDark,
                keyboard: TextInputType.url,
              ),
              if (_applyUrl.text.isNotEmpty &&
                  !_isValidUrl(_applyUrl.text.trim()))
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    'Must start with http:// or https://',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFFFF0101),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _label('Tags (comma-separated)', Icons.sell),
              const SizedBox(height: 6),
              _field(_tags, 'e.g. CSE, AIML, Remote', isDark),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFFFF0101),
                  ),
                ),
              ],
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
                  onPressed: _canSubmit && !_submitting ? _submit : null,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.publish),
                  label: Text(
                    _submitting ? 'Posting…' : 'Post Job',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700),
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
          Icon(i, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            t,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      );

  Widget _field(
    TextEditingController c,
    String hint,
    bool isDark, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.poppins(fontSize: 13, height: 1.4),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.poppins(fontSize: 13, color: context.faintText),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.white,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
