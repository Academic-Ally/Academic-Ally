import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../auth/providers/auth_provider.dart';

const String _supportEmail = 'support@getacademically.co';

class ReportBottomSheet extends ConsumerStatefulWidget {
  final String resourceId;
  final String resourceName;
  final String subject;
  final String category;
  final String university;
  final String course;
  final String branch;
  final String sem;

  const ReportBottomSheet({
    super.key,
    required this.resourceId,
    required this.resourceName,
    required this.subject,
    required this.category,
    required this.university,
    required this.course,
    required this.branch,
    required this.sem,
  });

  @override
  ConsumerState<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends ConsumerState<ReportBottomSheet> {
  bool _copyright = false;
  bool _misleading = false;
  bool _spam = false;
  bool _submitting = false;
  bool _submitted = false;

  bool get _canSubmit => _copyright || _misleading || _spam;

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _submitting = true);

    try {
      await FirebaseFirestore.instance
          .doc(FirestorePaths.userReport(
            widget.university,
            widget.course,
            widget.branch,
            widget.sem,
            user.uid,
          ))
          .set({
        'uid': user.uid,
        'email': user.email,
        'report': {
          'copyright': _copyright,
          'misleading': _misleading,
          'spam': _spam,
        },
        'subjectName': widget.resourceName,
        'subjectId': widget.resourceId,
        'sCategory': widget.category,
        'sSubject': widget.subject,
        'sUniversity': widget.university,
        'sCourse': widget.course,
        'sBranch': widget.branch,
        'sSem': widget.sem,
        'date': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: const Color(0xFFFF0101),
          ),
        );
      }
    }
  }

  Future<void> _openMail() async {
    final uri = Uri.parse(
      'mailto:$_supportEmail'
      '?subject=${Uri.encodeComponent('Report: ${widget.resourceName}')}'
      '&body=${Uri.encodeComponent(
        'Report for resource ID: ${widget.resourceId}\n'
        '${widget.course} ${widget.branch}, Semester ${widget.sem}\n'
        'Category: ${widget.category}\n'
        'Subject: ${widget.subject}\n\n',
      )}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email app available to send a report.'),
          backgroundColor: Color(0xFFFF0101),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF1F1FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _submitted ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.topRight,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Icon(Icons.flag_outlined,
                      size: 48, color: AppTheme.primaryColor),
                  const SizedBox(height: 12),
                  Text(
                    'Why are you reporting this resource?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your report is anonymous, except if you are reporting an intellectual property infringement.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF91919F),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 8,
              child: IconButton(
                icon:
                    const Icon(Icons.cancel, color: Color(0xFFBCC4CC), size: 28),
                onPressed: _submitting ? null : () => Navigator.pop(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ReasonTile(
          label:
              'Copyrights: The notes or this resource file contain copyrighted material',
          value: _copyright,
          onChanged: (v) => setState(() => _copyright = v ?? false),
        ),
        _ReasonTile(
          label:
              'Misleading resource: The uploaded source contains inaccurate and false information.',
          value: _misleading,
          onChanged: (v) => setState(() => _misleading = v ?? false),
        ),
        _ReasonTile(
          label:
              'Spam: This file contains content other than notes and resources.',
          value: _spam,
          onChanged: (v) => setState(() => _spam = v ?? false),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: InkWell(
            onTap: _openMail,
            child: Text(
              'Reason not listed here? Write to Us',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed:
                      _submitting ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.mutedText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canSubmit && !_submitting ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Confirm',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle,
              size: 56, color: AppTheme.primaryColor),
          const SizedBox(height: 20),
          Text(
            'Thank you for letting us know!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We will review your report and take appropriate action.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.mutedText,
            ),
          ),
          const SizedBox(height: 32),
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
                'Close',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _ReasonTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF91919F), width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
