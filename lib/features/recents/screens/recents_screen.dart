import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../models/recent_pdf_model.dart';
import '../providers/recents_provider.dart';

class RecentsScreen extends ConsumerWidget {
  const RecentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recents = ref.watch(recentsProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            SizedBox(
              height: size.height * 0.15,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.history,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Recents',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF1F1FA),
                            ),
                          ),
                        ),
                        if (recents.isNotEmpty)
                          TextButton(
                            onPressed: () => _confirmClearAll(context, ref),
                            child: const Text(
                              'Clear All',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Body
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
                child: recents.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history,
                                  size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 20),
                              Text(
                                'No recently viewed PDFs.\nOpen a resource to see it here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: context.faintText,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => context.go('/search'),
                                icon: const Icon(Icons.search, size: 18),
                                label: const Text(
                                  'Browse Subjects',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: recents.length,
                        itemBuilder: (context, index) {
                          return _RecentCard(
                            recent: recents[index],
                            onTap: () => _openPdf(context, recents[index]),
                            onDelete: () => ref
                                .read(recentsProvider.notifier)
                                .removeRecent(recents[index].id),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPdf(BuildContext context, RecentPdfModel recent) {
    context.push(
      '/pdf-viewer'
      '?id=${recent.id}'
      '&name=${Uri.encodeComponent(recent.name)}'
      '&subject=${Uri.encodeComponent(recent.subject)}'
      '&category=${Uri.encodeComponent(recent.category)}'
      '&university=${recent.university ?? ''}'
      '&course=${recent.course ?? ''}'
      '&branch=${recent.branch}'
      '&sem=${recent.sem}'
      '&storageId=${Uri.encodeComponent(recent.storageId ?? '')}'
      '&type=${recent.category}',
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Recents'),
        content: const Text(
            'Are you sure you want to clear all recently viewed items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(recentsProvider.notifier).clearAll();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  final RecentPdfModel recent;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RecentCard({
    required this.recent,
    required this.onTap,
    required this.onDelete,
  });

  String get _timeAgo {
    final diff = DateTime.now().difference(recent.viewedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${recent.viewedAt.day}/${recent.viewedAt.month}/${recent.viewedAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.picture_as_pdf,
                  color: Color(0xFF4CAF50), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recent.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? Colors.white : const Color(0xFF161719),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${recent.subject} · $_timeAgo',
                    style:
                        TextStyle(fontSize: 12, color: context.faintText),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
