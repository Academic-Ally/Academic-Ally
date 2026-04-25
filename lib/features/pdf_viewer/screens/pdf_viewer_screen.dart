import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/theme.dart';
import '../../../models/resource_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../bookmarks/providers/bookmarks_provider.dart';
import '../../downloads/providers/downloads_provider.dart';
import '../../recents/providers/recents_provider.dart';
import '../../resources/providers/resources_provider.dart';
import '../widgets/report_bottom_sheet.dart';

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
  final int? initialPage; // 1-indexed; null = page 1

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
    this.initialPage,
  });

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String? _localFilePath;
  bool _hasTrackedView = false;
  PDFViewController? _pdfController;
  bool _initialPageApplied = false;

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
    // Defer to post-frame so any provider mutations inside _bootstrapPdf
    // / _trackView / _addToRecents don't overlap the first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bootstrapPdf();
      _trackView();
      _addToRecents();
    });
  }

  /// Find the cached copy if it exists; otherwise auto-download so the
  /// PDF view renders immediately on first open (especially when a
  /// citation tap navigates here with an ``initialPage``).
  Future<void> _bootstrapPdf() async {
    final cached =
        await ref.read(downloadsProvider.notifier).getLocalPath(_resource);
    if (!mounted) return;
    if (cached != null) {
      setState(() => _localFilePath = cached);
      return;
    }
    if ((widget.storageId ?? '').isNotEmpty) {
      _handleDownload();
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

    try {
      // Resolve a Firebase Storage download URL from the storageId path.
      final url = await FirebaseStorage.instance
          .ref(storageId)
          .getDownloadURL()
          .timeout(const Duration(seconds: 15));

      // Stream-download to local cache so flutter_pdfview can render it.
      final localPath = await _downloadToLocal(
        url: url,
        fileName: _safeLocalFileName(storageId),
        onProgress: (progress) {
          if (mounted) setState(() => _downloadProgress = progress);
        },
      );

      if (!mounted) return;
      if (localPath == null) {
        setState(() => _isDownloading = false);
        _showSnackBar('Download failed. Please try again.');
        return;
      }

      // Save metadata so the rest of the app picks the local copy up.
      await ref
          .read(downloadsProvider.notifier)
          .saveDownloadMeta(_resource, localPath);

      setState(() {
        _localFilePath = localPath;
        _isDownloading = false;
      });
      _showSnackBar('Downloaded successfully!', isSuccess: true);
    } catch (exc) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      _showSnackBar('Download failed: $exc');
    }
  }

  /// Filename derived from the storage path — keeps it deterministic so
  /// repeated taps reuse the cached file.
  String _safeLocalFileName(String storageId) {
    final basename = storageId.split('/').last;
    return basename.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
  }

  Future<String?> _downloadToLocal({
    required String url,
    required String fileName,
    void Function(double)? onProgress,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final resourcesDir = Directory('${dir.path}/Resources');
    if (!resourcesDir.existsSync()) {
      resourcesDir.createSync(recursive: true);
    }
    final filePath = '${resourcesDir.path}/$fileName';

    // Reuse cached copy if already downloaded.
    final existing = File(filePath);
    if (existing.existsSync() && (await existing.length()) > 0) {
      return filePath;
    }

    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);
      final total = response.contentLength ?? 0;
      var received = 0;
      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
      await File(filePath).writeAsBytes(bytes);
      return filePath;
    } catch (_) {
      return null;
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

  void _openReport() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportBottomSheet(
        resourceId: widget.id,
        resourceName: widget.name,
        subject: widget.subject,
        category: widget.category,
        university: widget.university,
        course: widget.course,
        branch: widget.branch,
        sem: widget.sem,
      ),
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
                case 'report':
                  _openReport();
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
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 20, color: Color(0xFFFF0101)),
                    SizedBox(width: 8),
                    Text('Report',
                        style: TextStyle(color: Color(0xFFFF0101))),
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
    final initial = (widget.initialPage ?? 1).clamp(1, 100000);
    return PDFView(
      filePath: _localFilePath!,
      // flutter_pdfview's defaultPage is 0-indexed.
      defaultPage: initial - 1,
      autoSpacing: true,
      pageFling: true,
      onRender: (_) {
        // Some platforms ignore defaultPage on first render — re-apply
        // once the PDF reports it's ready.
        if (!_initialPageApplied && _pdfController != null && initial > 1) {
          _pdfController!.setPage(initial - 1);
          _initialPageApplied = true;
        }
      },
      onViewCreated: (controller) {
        _pdfController = controller;
        if (!_initialPageApplied && initial > 1) {
          // Defer slightly so the controller is fully attached.
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              controller.setPage(initial - 1);
              _initialPageApplied = true;
            }
          });
        }
      },
      onError: (error) {
        if (mounted) _showSnackBar('PDF error: $error');
      },
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
