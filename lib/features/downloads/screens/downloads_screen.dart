import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../providers/downloads_provider.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final downloads = ref.watch(downloadsProvider);

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
                        const Icon(Icons.download_rounded,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Downloads',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF1F1FA),
                            ),
                          ),
                        ),
                        if (downloads.isNotEmpty)
                          TextButton(
                            onPressed: () =>
                                _confirmClearAll(context, ref),
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
                child: downloads.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download_rounded,
                                  size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 20),
                              Text(
                                'No downloads yet.\nDownload a PDF to read it offline.',
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
                        itemCount: downloads.length,
                        itemBuilder: (context, index) {
                          final dl = downloads[index];
                          return _DownloadCard(
                            download: dl,
                            onTap: () => _openPdf(context, dl),
                            onDelete: () => _confirmDelete(
                                context, ref, dl.filePath),
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

  void _openPdf(BuildContext context, DownloadedFile dl) {
    context.push(
      '/pdf-viewer'
      '?id=${dl.resource.id}'
      '&name=${Uri.encodeComponent(dl.resource.name)}'
      '&subject=${Uri.encodeComponent(dl.resource.subject)}'
      '&category=${Uri.encodeComponent(dl.resource.category)}'
      '&university=${dl.resource.university ?? ''}'
      '&course=${dl.resource.course ?? ''}'
      '&branch=${dl.resource.branch}'
      '&sem=${dl.resource.sem}'
      '&storageId=${Uri.encodeComponent(dl.resource.storageId ?? '')}'
      '&type=${dl.resource.category}',
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String path) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Download'),
        content: const Text(
            'This will remove the file from your device. You can download it again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(downloadsProvider.notifier).deleteDownload(path);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Downloads'),
        content: const Text(
            'This will delete all downloaded files from your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(downloadsProvider.notifier).clearAll();
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

class _DownloadCard extends StatelessWidget {
  final DownloadedFile download;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DownloadCard({
    required this.download,
    required this.onTap,
    required this.onDelete,
  });

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
                color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.download_done,
                  color: Color(0xFFFF9800), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    download.resource.name,
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
                    '${download.resource.subject} · ${download.resource.branch}',
                    style:
                        TextStyle(fontSize: 12, color: context.faintText),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 20, color: Colors.grey[400]),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
