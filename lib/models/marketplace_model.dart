import 'package:cloud_firestore/cloud_firestore.dart';

enum ListingCondition { brandNew, likeNew, good, fair }

extension ListingConditionX on ListingCondition {
  String get wire {
    switch (this) {
      case ListingCondition.brandNew:
        return 'new';
      case ListingCondition.likeNew:
        return 'like-new';
      case ListingCondition.good:
        return 'good';
      case ListingCondition.fair:
        return 'fair';
    }
  }

  String get label {
    switch (this) {
      case ListingCondition.brandNew:
        return 'New';
      case ListingCondition.likeNew:
        return 'Like New';
      case ListingCondition.good:
        return 'Good';
      case ListingCondition.fair:
        return 'Fair';
    }
  }

  static ListingCondition fromWire(String? raw) {
    switch (raw) {
      case 'new':
        return ListingCondition.brandNew;
      case 'like-new':
        return ListingCondition.likeNew;
      case 'fair':
        return ListingCondition.fair;
      case 'good':
      default:
        return ListingCondition.good;
    }
  }
}

/// A buy/sell listing.
/// Stored at `Marketplace/{listingId}`.
class MarketplaceListing {
  final String id;
  final String title;
  final String description;
  final double priceInr;
  final ListingCondition condition;
  final String? category;
  final List<String> imageUrls;
  final String? sellerUid;
  final String? sellerName;
  final String? sellerPhone;
  final DateTime? createdAt;

  const MarketplaceListing({
    required this.id,
    required this.title,
    required this.description,
    required this.priceInr,
    required this.condition,
    this.category,
    this.imageUrls = const [],
    this.sellerUid,
    this.sellerName,
    this.sellerPhone,
    this.createdAt,
  });

  factory MarketplaceListing.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MarketplaceListing(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      priceInr: (d['priceInr'] as num?)?.toDouble() ?? 0.0,
      condition: ListingConditionX.fromWire(d['condition'] as String?),
      category: d['category'],
      imageUrls: List<String>.from(d['imageUrls'] ?? const []),
      sellerUid: d['sellerUid'],
      sellerName: d['sellerName'],
      sellerPhone: d['sellerPhone'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'priceInr': priceInr,
        'condition': condition.wire,
        if (category != null) 'category': category,
        'imageUrls': imageUrls,
        if (sellerUid != null) 'sellerUid': sellerUid,
        if (sellerName != null) 'sellerName': sellerName,
        if (sellerPhone != null) 'sellerPhone': sellerPhone,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
