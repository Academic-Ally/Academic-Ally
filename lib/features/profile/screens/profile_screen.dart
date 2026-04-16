import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _showLogoutDialog = false;
  bool _showDeleteDialog = false;

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  // Header with avatar
                  SizedBox(
                    height: size.height * 0.36,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: size.height * 0.01,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Icon(Icons.person, color: Color(0xFFF1F1FA),
                                  size: 28),
                              SizedBox(width: 10),
                              Text(
                                'Account',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Color(0xFFF1F1FA),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Avatar
                          userProfile.when(
                            data: (user) => Center(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: size.height * 0.07,
                                    backgroundColor: const Color(0xFFF1F1FA),
                                    backgroundImage: user?.pfp != null
                                        ? NetworkImage(user!.pfp!)
                                        : null,
                                    child: user?.pfp == null
                                        ? Text(
                                            user?.name.isNotEmpty == true
                                                ? user!.name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.primaryColor,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    user?.name ?? '',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      color: Color(0xFFF1F1FA),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.email ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFFF1F1FA),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            loading: () =>
                                const Center(child: CircularProgressIndicator(
                                    color: Colors.white)),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Body section
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: size.height * 0.6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Theme.of(context).scaffoldBackgroundColor
                          : const Color(0xFFF1F1FA),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: size.height * 0.05,
                        bottom: size.height * 0.15,
                      ),
                      child: Column(
                        children: [
                          // Account Settings
                          _buildSection(
                            context,
                            title: 'Account Settings',
                            items: [
                              _SettingsItem(
                                label: 'Update Profile',
                                onTap: () => context.push('/update-profile'),
                              ),
                              _SettingsItem(
                                label: 'Downloads',
                                onTap: () => context.push('/downloads'),
                              ),
                              _SettingsItem(
                                label: 'Log Out',
                                onTap: () =>
                                    setState(() => _showLogoutDialog = true),
                              ),
                              _SettingsItem(
                                label: 'Delete Account',
                                onTap: () =>
                                    setState(() => _showDeleteDialog = true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Support
                          _buildSection(
                            context,
                            title: 'Support',
                            items: [
                              _SettingsItem(
                                label: 'About Us',
                                onTap: () => launchUrl(
                                    Uri.parse('https://getacademically.co')),
                              ),
                              _SettingsItem(
                                label: 'Share Academic Ally',
                                onTap: () => SharePlus.instance.share(
                                  ShareParams(
                                    text: 'Check out Academic Ally - your study companion for engineering resources! https://getacademically.co',
                                  ),
                                ),
                              ),
                              _SettingsItem(
                                label: 'Get in Touch',
                                onTap: () => launchUrl(
                                    Uri.parse('mailto:support@getacademically.co')),
                              ),
                              _SettingsItem(
                                label: 'Privacy Policy',
                                onTap: () => launchUrl(Uri.parse(
                                    'https://getacademically.co/privacy')),
                              ),
                              _SettingsItem(
                                label: 'Terms & Conditions',
                                onTap: () => launchUrl(Uri.parse(
                                    'https://getacademically.co/terms')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Logout dialog
            if (_showLogoutDialog)
              _buildAlertDialog(
                title: 'Log Out',
                message: 'Are you sure you want to log out?',
                actionLabel: 'Log Out',
                onAction: () async {
                  final authService = ref.read(authServiceProvider);
                  await authService.signOut();
                },
                onCancel: () => setState(() => _showLogoutDialog = false),
              ),

            // Delete dialog
            if (_showDeleteDialog)
              _buildAlertDialog(
                title: 'Delete Account',
                message:
                    'By proceeding with this action, you will be permanently deleting all account data. This action cannot be undone.\n\nAre you sure you want to proceed?',
                actionLabel: 'Delete',
                onAction: () async {
                  final authService = ref.read(authServiceProvider);
                  await authService.deleteAccount();
                },
                onCancel: () => setState(() => _showDeleteDialog = false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_SettingsItem> items,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : const Color(0xFF91919F),
            ),
          ),
          ...items.map((item) => InkWell(
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF161719),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Color(0xFF91919F),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAlertDialog({
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    required VoidCallback onCancel,
  }) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF91919F),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(actionLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsItem {
  final String label;
  final VoidCallback onTap;

  const _SettingsItem({required this.label, required this.onTap});
}
