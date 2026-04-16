import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../config/theme.dart';
import '../../../core/widgets/screen_layout.dart';
import '../../../models/resource_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/bookmarks_provider.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScreenLayout(
      title: 'Bookmarks',
      icon: Icons.bookmark_rounded,
      body: bookmarksAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: TextStyle(color: Colors.grey[500])),
        ),
        data: (bookmarks) {
          if (bookmarks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/lottie/NoBookMarks.json',
                      width: 200,
                      height: 200,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No bookmarks to show. Start bookmarking your favorite notes for easy access later!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Group bookmarks by subject
          final grouped = <String, List<ResourceModel>>{};
          for (final bm in bookmarks) {
            grouped.putIfAbsent(bm.subject, () => []).add(bm);
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 8),
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[400] : const Color(0xFF91919F),
                      ),
                    ),
                  ),
                  ...entry.value.map((resource) => _BookmarkCard(
                        resource: resource,
                        isDark: isDark,
                        onTap: () => _openResource(context, resource),
                        onDelete: () => _removeBookmark(ref, resource),
                      )),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _openResource(BuildContext context, ResourceModel resource) {
    context.push(
      '/pdf-viewer'
      '?id=${resource.id}'
      '&name=${Uri.encodeComponent(resource.name)}'
      '&subject=${Uri.encodeComponent(resource.subject)}'
      '&category=${Uri.encodeComponent(resource.category)}'
      '&university=${resource.university ?? ''}'
      '&course=${resource.course ?? ''}'
      '&branch=${resource.branch}'
      '&sem=${resource.sem}'
      '&storageId=${Uri.encodeComponent(resource.storageId ?? '')}'
      '&type=${resource.category}',
    );
  }

  void _removeBookmark(WidgetRef ref, ResourceModel resource) {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    ref.read(bookmarksServiceProvider).removeBookmark(
          uid: user.uid,
          resourceId: resource.id,
        );
  }
}

class _BookmarkCard extends StatelessWidget {
  final ResourceModel resource;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookmarkCard({
    required this.resource,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(resource.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
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
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.picture_as_pdf,
                    color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.name,
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
                      '${resource.category} · ${resource.branch}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.bookmark, color: AppTheme.primaryColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
