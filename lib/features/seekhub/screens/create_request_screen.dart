import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/subject_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../resources/providers/resources_provider.dart';
import '../providers/seekhub_provider.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  String? _selectedBranch;
  String? _selectedSem;
  String? _selectedSubject;
  String _selectedCategory = AppConstants.notes;
  bool _isSubmitting = false;

  List<SubjectModel> get _filteredSubjects {
    final all = ref.watch(subjectsListProvider).value ?? [];
    return all.where((s) {
      if (_selectedBranch != null && s.branch != _selectedBranch) return false;
      if (_selectedSem != null && s.sem != _selectedSem) return false;
      return true;
    }).toList();
  }

  Future<void> _submitRequest() async {
    if (_selectedSubject == null || _selectedBranch == null || _selectedSem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Color(0xFFFF0101),
        ),
      );
      return;
    }

    final user = ref.read(userProfileProvider).value;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(seekHubServiceProvider);
      await service.createRequest(
        seekerName: user.name,
        seekerUid: user.uid,
        seekerPhoto: user.pfp,
        subject: _selectedSubject!,
        category: _selectedCategory,
        sem: _selectedSem!,
        branch: _selectedBranch!,
        course: user.course,
        university: user.university,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted successfully!'),
            backgroundColor: Color(0xFF5CB85C),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF0101),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjects = _filteredSubjects;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            SizedBox(
              height: size.height * 0.13,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'New Request',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF1F1FA),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Form body
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Theme.of(context).scaffoldBackgroundColor
                      : const Color(0xFFF1F1FA),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Branch dropdown
                      _buildLabel('Branch'),
                      _buildDropdown(
                        value: _selectedBranch,
                        hint: 'Select Branch',
                        items: AppConstants.branches
                            .map((b) =>
                                DropdownMenuItem(value: b, child: Text(b)))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedBranch = val;
                            _selectedSubject = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Semester dropdown
                      _buildLabel('Semester'),
                      _buildDropdown(
                        value: _selectedSem,
                        hint: 'Select Semester',
                        items: AppConstants.semesters
                            .map((s) => DropdownMenuItem(
                                value: s, child: Text('Semester $s')))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSem = val;
                            _selectedSubject = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Subject dropdown
                      _buildLabel('Subject'),
                      _buildDropdown(
                        value: _selectedSubject,
                        hint: 'Select Subject',
                        items: subjects
                            .map((s) => DropdownMenuItem(
                                value: s.subject, child: Text(s.subject)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedSubject = val),
                      ),
                      const SizedBox(height: 16),

                      // Category dropdown
                      _buildLabel('Resource Type'),
                      _buildDropdown(
                        value: _selectedCategory,
                        hint: 'Select Type',
                        items: AppConstants.resourceTypes
                            .map((t) => DropdownMenuItem(
                                value: t, child: Text(_displayType(t))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 32),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: size.height * 0.07,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Submit Request',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white70
              : const Color(0xFF161719),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        hint: Text(hint),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        items: items,
        onChanged: onChanged,
        isExpanded: true,
      ),
    );
  }

  String _displayType(String type) {
    switch (type) {
      case 'QuestionPapers':
        return 'Question Papers';
      case 'OtherResources':
        return 'Other Resources';
      default:
        return type;
    }
  }
}
