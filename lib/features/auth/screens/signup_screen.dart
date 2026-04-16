import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _collegeController = TextEditingController();
  bool _isLoading = false;

  String _selectedUniversity = AppConstants.jntuh;
  String _selectedBranch = AppConstants.branches.first;
  String _selectedSem = AppConstants.semesters.first;

  String get _selectedCourse =>
      _selectedUniversity == AppConstants.jntuh
          ? AppConstants.btech
          : AppConstants.be;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Color(0xFFFF0101),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        university: _selectedUniversity,
        course: _selectedCourse,
        branch: _selectedBranch,
        sem: _selectedSem,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please verify your email.'),
            backgroundColor: Color(0xFF5CB85C),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFFF0101),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Logo area (smaller for signup)
            SizedBox(
              height: size.height * 0.15,
              child: Center(
                child: Image.asset(
                  'assets/images/white-logo.png',
                  height: 70,
                ),
              ),
            ),

            // Form card
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F1FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        const Text(
                          'Create Your Account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 30,
                            color: Color(0xFF161719),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Full Name
                        _buildInputField(
                          controller: _nameController,
                          icon: Icons.person_outline,
                          placeholder: 'Full Name',
                        ),
                        const SizedBox(height: 10),

                        // Email
                        _buildInputField(
                          controller: _emailController,
                          icon: Icons.mail_outline,
                          placeholder: 'Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 10),

                        // Password
                        _buildInputField(
                          controller: _passwordController,
                          icon: Icons.lock_outline,
                          placeholder: 'Password',
                          obscureText: true,
                        ),
                        const SizedBox(height: 10),

                        // Confirm Password
                        _buildInputField(
                          controller: _confirmPasswordController,
                          icon: Icons.lock_outline,
                          placeholder: 'Confirm Password',
                          obscureText: true,
                        ),
                        const SizedBox(height: 10),

                        // University dropdown
                        _buildDropdown(
                          value: _selectedUniversity,
                          icon: Icons.more_horiz,
                          items: const [
                            DropdownMenuItem(
                                value: AppConstants.jntuh,
                                child: Text('JNTUH')),
                            DropdownMenuItem(
                                value: AppConstants.ou,
                                child: Text('Osmania University')),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedUniversity = val!),
                        ),
                        const SizedBox(height: 10),

                        // Course & Branch side by side
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                value: _selectedCourse,
                                icon: Icons.safety_check_outlined,
                                items: [
                                  DropdownMenuItem(
                                      value: _selectedCourse,
                                      child: Text(_selectedCourse)),
                                ],
                                onChanged: (_) {},
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDropdown(
                                value: _selectedBranch,
                                icon: Icons.account_tree_outlined,
                                items: AppConstants.branches
                                    .map((b) => DropdownMenuItem(
                                        value: b, child: Text(b)))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedBranch = val!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Semester dropdown
                        _buildDropdown(
                          value: _selectedSem,
                          icon: Icons.more_horiz,
                          items: AppConstants.semesters
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text('Semester $s')))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedSem = val!),
                        ),
                        const SizedBox(height: 10),

                        // College name
                        _buildInputField(
                          controller: _collegeController,
                          icon: Icons.location_city_outlined,
                          placeholder: 'College Name',
                        ),
                        const SizedBox(height: 20),

                        // Sign Up button
                        _buildButton(
                          label: 'Sign Up',
                          color: AppTheme.primaryColor,
                          isLoading: _isLoading,
                          onPressed: _handleSignup,
                        ),
                        const SizedBox(height: 16),

                        // Log In button
                        _buildButton(
                          label: 'Log In',
                          color: AppTheme.tertiaryColor,
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String placeholder,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 16, color: Color(0xFF161719)),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF161719), size: 24),
        hintText: placeholder,
        hintStyle: const TextStyle(color: Color(0xFF808080)),
        filled: true,
        fillColor: const Color(0xFFF1F1FA),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF2E00), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF2E00), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String value,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF161719), size: 24),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
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

  Widget _buildButton({
    required String label,
    required Color color,
    bool isLoading = false,
    required VoidCallback onPressed,
  }) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: double.infinity,
      height: size.height * 0.07,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFFF1F1FA),
                ),
              ),
      ),
    );
  }
}
