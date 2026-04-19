import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme.dart';
import '../../../models/marketplace_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/marketplace_provider.dart';

class MarketplaceDetailScreen extends ConsumerWidget {
  final String listingId;

  const MarketplaceDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF1F1FA);
    final listingAsync =
        ref.watch(marketplaceDetailProvider(listingId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Listing',
          style:
              GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          listingAsync.when(
            data: (l) {
              if (l != null &&
                  currentUser != null &&
                  l.sellerUid == currentUser.uid) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, l),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Could not load listing.\n$e',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ),
        data: (l) {
          if (l == null) {
            return const Center(child: Text('Listing not found.'));
          }
          return _buildBody(context, l, isDark);
        },
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, MarketplaceListing listing, bool isDark) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _ImageGallery(urls: listing.imageUrls),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF161719),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${listing.priceInr.round()}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _conditionColor(listing.condition)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Condition: ${listing.condition.label}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _conditionColor(listing.condition),
                            ),
                          ),
                        ),
                        if (listing.category != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              listing.category!,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Description',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      listing.description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF161719),
                        height: 1.5,
                      ),
                    ),
                    if (listing.sellerName != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryColor
                                  .withValues(alpha: 0.15),
                              child: Text(
                                listing.sellerName!.isNotEmpty
                                    ? listing.sellerName![0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    listing.sellerName!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (listing.createdAt != null)
                                    Text(
                                      'Listed ${_fmtWhen(listing.createdAt!)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: listing.sellerPhone == null ||
                      listing.sellerPhone!.isEmpty
                  ? null
                  : () => _contactSeller(context, listing),
              icon: const Icon(Icons.chat),
              label: Text(
                listing.sellerPhone == null || listing.sellerPhone!.isEmpty
                    ? 'No contact info'
                    : 'Contact Seller on WhatsApp',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _contactSeller(
      BuildContext context, MarketplaceListing listing) async {
    final phone =
        listing.sellerPhone!.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent(
        'Hi! I\'m interested in your "${listing.title}" listing on Academic Ally.');
    final uri = Uri.parse('https://wa.me/$phone?text=$msg');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp.'),
            backgroundColor: Color(0xFFFF0101),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open WhatsApp: $e'),
            backgroundColor: const Color(0xFFFF0101),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, MarketplaceListing listing) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete listing?'),
        content: const Text(
            'The listing and its photos will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFFF0101)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await deleteListing(
      listingId: listing.id,
      imageCount: listing.imageUrls.length,
    );
    if (context.mounted) Navigator.pop(context);
  }

  Color _conditionColor(ListingCondition c) {
    switch (c) {
      case ListingCondition.brandNew:
        return const Color(0xFF4CAF50);
      case ListingCondition.likeNew:
        return AppTheme.primaryColor;
      case ListingCondition.good:
        return const Color(0xFFFFA726);
      case ListingCondition.fair:
        return Colors.grey;
    }
  }

  String _fmtWhen(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 30) return '${diff.inDays} d ago';
    return '${(diff.inDays / 30).floor()} mo ago';
  }
}

class _ImageGallery extends StatelessWidget {
  final List<String> urls;

  const _ImageGallery({required this.urls});

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return Container(
        height: 240,
        color: Colors.grey[200],
        child: Icon(Icons.image_outlined, size: 72, color: Colors.grey[500]),
      );
    }
    return SizedBox(
      height: 280,
      child: PageView.builder(
        itemCount: urls.length,
        itemBuilder: (_, i) => Image.network(
          urls[i],
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
          errorBuilder: (context, _, _) => Container(
            color: Colors.grey[200],
            child: Icon(Icons.broken_image_outlined,
                size: 48, color: Colors.grey[500]),
          ),
        ),
      ),
    );
  }
}
