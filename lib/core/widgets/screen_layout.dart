import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Common screen layout used across the app.
/// Matches the React Native pattern: colored header + rounded body section.
class ScreenLayout extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget body;
  final Widget? headerExtra;

  const ScreenLayout({
    super.key,
    required this.title,
    required this.icon,
    required this.body,
    this.headerExtra,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header — sizes itself to its content so we don't end up with
            // a tall purple gap below the title.
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.05,
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: const Color(0xFFF1F1FA), size: 28),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color(0xFFF1F1FA),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (headerExtra != null) ...[
                    const SizedBox(height: 8),
                    headerExtra!,
                  ],
                ],
              ),
            ),

            // Body with rounded top corners
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
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
