import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/theme.dart';
import '../../../core/services/r2_storage_service.dart';
import '../../../models/resource_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../bookmarks/providers/bookmarks_provider.dart';
import '../../downloads/providers/downloads_provider.dart';
import '../../recents/providers/recents_provider.dart';
import '../../resources/providers/resources_provider.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final String id;
  final String name;
  final String subject;
  final String category;
  final String university;
  final String course;
  final String branch;
  final String sem;
  final String? storageId;
  final String resourceType;

  const PdfViewerScreen({
    super.key,
    required this.id,
    required this.name,
    required this.subject,
    required this.category,
    required this.university,
    required this.course,
    required this.branch,
    required this.sem,
    this.storageId,
    required this.resourceType,
  });

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String? _localFilePath;
  bool _hasTrackedView = false;

  ResourceModel get _resource => ResourceModel(
        id: widget.id,
        name: widget.name,
        subject: widget.subject,
        category: widget.category,
        sem: widget.sem,
        branch: widget.branch,
        storageId: widget.storageId,
        university: widget.university,
        course: widget.course,
      );

  @override
  void initState() {
    super.initState();
    _checkLocalFile();
    _trackView();
    _addToRecents();
  }

  Future<void> _checkLocalFile() async {
    final path = await ref.read(downloadsProvider.notifier).getLocalPath(_resource);
    if (mounted && path != null) {
      setState(() => _localFilePath = path);
    }
  }

  Future<void> _trackView() async {
    if (_hasTrackedView) return;
    _hasTrackedView = true;
    try {
      await incrementViewCount(
        university: widget.university,
        course: widget.course,
        branch: widget.branch,
        sem: widget.sem,
        resourceType: widget.resourceType,
        subject: widget.subject,
        resourceId: widget.id,
      );
    } catch (_) {}
  }

  Future<void> _addToRecents() async {
    ref.read(recentsProvider.notifier).addRecent(_resource);
  }

  Future<void> _handleDownload() async {
    if (_isDownloading) return;

    final storageId = widget.storageId;
    if (storageId == null || storageId.isEmpty) {
      _showSnackBar('Storage not configured yet. PDF download unavailable.');
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    final url = R2StorageService.getResourceUrl(storageId);
    final downloadPath =
        await ref.read(downloadsProvider.notifier).getDownloadPath(_resource);

    final result = await R2StorageService.downloadFile(
      url: url,
      fileName: downloadPath.split('/').last,
      onProgress: (progress) {
        if (mounted) setState(() => _downloadProgress = progress);
      },
    );

    if (mounted) {
      if (result != null) {
        await ref
            .read(downloadsProvider.notifier)
            .saveDownloadMeta(_resource, result);
        setState(() {
          _localFilePath = result;
          _isDownloading = false;
        });
        _showSnackBar('Downloaded successfully!', isSuccess: true);
      } else {
        setState(() => _isDownloading = false);
        _showSnackBar('Download failed. Please try again.');
      }
    }
  }

  Future<void> _handleBookmark() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final service = ref.read(bookmarksServiceProvider);
    final added = await service.toggleBookmark(
      uid: user.uid,
      resource: _resource,
    );

    if (mounted) {
      _showSnackBar(
        added ? 'Bookmarked!' : 'Bookmark removed',
        isSuccess: added,
      );
    }
  }

  void _handleShare() {
    final text = 'Check out "${widget.name}" on Academic Ally!\n'
        'Subject: ${widget.subject}\n'
        '${widget.branch} - Semester ${widget.sem}';
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _handleRate() {
    double selectedRating = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Rate this resource'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < selectedRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                ),
                onPressed: () {
                  setDialogState(() => selectedRating = (index + 1).toDouble());
                },
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedRating > 0
                  ? () async {
                      final user = ref.read(currentUserProvider);
                      if (user == null) return;

                      await rateResource(
                        uid: user.uid,
                        university: widget.university,
                        course: widget.course,
                        branch: widget.branch,
                        sem: widget.sem,
                        resourceType: widget.resourceType,
                        subject: widget.subject,
                        resourceId: widget.id,
                        rating: selectedRating,
                      );

                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        _showSnackBar('Thanks for rating!', isSuccess: true);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _openAllyBot() {
    context.push(
      '/allybot-chat'
      '?resourceId=${widget.id}'
      '&resourceName=${Uri.encodeComponent(widget.name)}'
      '&subject=${Uri.encodeComponent(widget.subject)}'
      '&storageId=${Uri.encodeComponent(widget.storageId ?? '')}',
    );
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? const Color(0xFF5CB85C)
            : const Color(0xFFFF0101),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBookmarked = ref.watch(isBookmarkedProvider(widget.id));

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF1F1FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          widget.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Bookmark
          isBookmarked.when(
            data: (bookmarked) => IconButton(
              icon: Icon(
                bookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.white,
              ),
              onPressed: _handleBookmark,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          // Share
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _handleShare,
          ),
          // More options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'rate':
                  _handleRate();
                case 'allybot':
                  _openAllyBot();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'rate',
                child: Row(
                  children: [
                    Icon(Icons.star_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Rate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'allybot',
                child: Row(
                  children: [
                    Icon(Icons.smart_toy_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Ask AllyBot'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // PDF Viewer area
          Expanded(
            child: _localFilePath != null
                ? _buildPdfContent()
                : _buildNoPdfState(),
          ),

          // Download bar
          if (_isDownloading)
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? Colors.grey[900] : Colors.white,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _downloadProgress,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation(
                        AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Downloading... ${(_downloadProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      // Bottom action bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Download button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isDownloading
                      ? null
                      : _localFilePath != null
                          ? null
                          : _handleDownload,
                  icon: Icon(
                    _localFilePath != null
                        ? Icons.check_circle
                        : Icons.download,
                  ),
                  label: Text(
                    _localFilePath != null ? 'Downloaded' : 'Download',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _localFilePath != null
                        ? const Color(0xFF5CB85C)
                        : AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // AllyBot button
              ElevatedButton.icon(
                onPressed: _openAllyBot,
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text(
                  'AllyBot',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tertiaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfContent() {
    // TODO: Replace with flutter_pdfview when storage is connected
    // For now show a placeholder indicating the file is downloaded
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf,
                size: 80, color: AppTheme.primaryColor),
            const SizedBox(height: 20),
            Text(
              widget.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PDF is available locally.',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 4),
            Text(
              _localFilePath ?? '',
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPdfState() {
    final hasStorage =
        widget.storageId != null && widget.storageId!.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasStorage ? Icons.cloud_download_outlined : Icons.cloud_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              widget.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasStorage
                  ? 'Tap "Download" to view this PDF.'
                  : 'PDF storage is not connected yet.\nThe PDF will be viewable once storage is configured.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            // Resource metadata
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _MetaChip(
                    icon: Icons.subject, label: widget.subject),
                _MetaChip(
                    icon: Icons.category, label: widget.category),
                _MetaChip(
                    icon: Icons.account_tree,
                    label: widget.branch),
                _MetaChip(
                    icon: Icons.school,
                    label: 'Sem ${widget.sem}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
