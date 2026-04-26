import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../models/subject_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../resources/providers/resources_provider.dart';
import '../providers/upload_provider.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _nameController = TextEditingController();
  String? _selectedBranch;
  String? _selectedSem;
  String? _selectedSubject;
  String _selectedCategory = AppConstants.notes;
  String? _selectedFilePath;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<SubjectModel> get _filteredSubjects {
    final all = ref.watch(subjectsListProvider).value ?? [];
    return all.where((s) {
      if (_selectedBranch != null && s.branch != _selectedBranch) return false;
      if (_selectedSem != null && s.sem != _selectedSem) return false;
      return true;
    }).toList();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      if (picked.path == null) return;
      setState(() => _selectedFilePath = picked.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open file picker: $e'),
          backgroundColor: const Color(0xFFFF0101),
        ),
      );
    }
  }

  Future<void> _handleUpload() async {
    if (_nameController.text.trim().isEmpty ||
        _selectedSubject == null ||
        _selectedBranch == null ||
        _selectedSem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Color(0xFFFF0101),
        ),
      );
      return;
    }

    if (_selectedFilePath == null || _selectedFilePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a PDF file first.'),
          backgroundColor: Color(0xFFFF0101),
        ),
      );
      return;
    }

    final user = ref.read(userProfileProvider).value;
    if (user == null) return;

    final success = await ref.read(uploadProvider.notifier).submitUpload(
          name: _nameController.text.trim(),
          subject: _selectedSubject!,
          category: _selectedCategory,
          university: user.university,
          course: user.course,
          branch: _selectedBranch!,
          sem: _selectedSem!,
          units: [],
          filePath: _selectedFilePath ?? '',
        );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF uploaded — your resource is now live.'),
          backgroundColor: Color(0xFF5CB85C),
        ),
      );
      _nameController.clear();
      setState(() {
        _selectedSubject = null;
        _selectedFilePath = null;
      });
      ref.read(uploadProvider.notifier).resetState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uploadState = ref.watch(uploadProvider);
    final subjects = _filteredSubjects;

    return ScreenLayout(
      title: 'Upload',
      icon: Icons.upload_rounded,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // File selection area
            GestureDetector(
              onTap: uploadState.isUploading ? null : _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedFilePath != null
                        ? const Color(0xFF5CB85C)
                        : Colors.grey.withValues(alpha: 0.3),
                    width: _selectedFilePath != null ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFilePath != null
                          ? Icons.picture_as_pdf
                          : Icons.cloud_upload_outlined,
                      size: 56,
                      color: _selectedFilePath != null
                          ? const Color(0xFF5CB85C)
                          : Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFilePath != null
                          ? _selectedFilePath!
                              .split(RegExp(r'[\\/]'))
                              .last
                          : 'Tap to select a PDF',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF161719),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    if (_selectedFilePath != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _formatFileSize(File(_selectedFilePath!).lengthSync()),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.faintText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: uploadState.isUploading
                            ? null
                            : () =>
                                setState(() => _selectedFilePath = null),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Change file'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Resource name
            _buildLabel('Resource Name'),
            _buildTextField(
              controller: _nameController,
              hint: 'e.g. Unit 1 Notes, Mid-2 Paper',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Branch + Semester row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Branch'),
                      _buildDropdown(
                        value: _selectedBranch,
                        hint: 'Branch',
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
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Semester'),
                      _buildDropdown(
                        value: _selectedSem,
                        hint: 'Sem',
                        items: AppConstants.semesters
                            .map((s) => DropdownMenuItem(
                                value: s, child: Text('Sem $s')))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSem = val;
                            _selectedSubject = null;
                          });
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subject
            _buildLabel('Subject'),
            _buildDropdown(
              value: _selectedSubject,
              hint: 'Select Subject',
              items: subjects
                  .map((s) => DropdownMenuItem(
                      value: s.subject, child: Text(s.subject)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedSubject = val),
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Category
            _buildLabel('Category'),
            _buildDropdown(
              value: _selectedCategory,
              hint: 'Category',
              items: AppConstants.resourceTypes
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(_displayType(t))))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Upload progress
            if (uploadState.isUploading)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: uploadState.progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation(
                          AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Uploading... ${(uploadState.progress * 100).toInt()}%',
                      style: TextStyle(color: context.mutedText, fontSize: 13),
                    ),
                  ],
                ),
              ),

            // Error message
            if (uploadState.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  uploadState.error!,
                  style: const TextStyle(color: Color(0xFFFF0101), fontSize: 13),
                ),
              ),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: uploadState.isUploading ? null : _handleUpload,
                icon: const Icon(Icons.upload_rounded),
                label: const Text(
                  'Submit Upload',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF161719),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF808080)),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
