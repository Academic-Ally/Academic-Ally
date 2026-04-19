import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../models/marketplace_model.dart';
import '../../auth/providers/auth_provider.dart';

/// Stream of all listings, newest first.
final marketplaceListProvider =
    StreamProvider<List<MarketplaceListing>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestorePaths.marketplace())
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => MarketplaceListing.fromFirestore(d)).toList());
});

/// Single listing stream.
final marketplaceDetailProvider =
    StreamProvider.family<MarketplaceListing?, String>((ref, listingId) {
  return FirebaseFirestore.instance
      .doc(FirestorePaths.marketplaceListing(listingId))
      .snapshots()
      .map((doc) =>
          doc.exists ? MarketplaceListing.fromFirestore(doc) : null);
});

/// Creates a listing with optional image uploads to Firebase Storage.
///
/// Flow:
///  1. Pre-generate listing ID (no write yet)
///  2. Upload each local image file to Storage at
///     `Marketplace/{listingId}/{index}.jpg`, collect download URLs
///  3. Write the Firestore doc with the image URLs
///
/// If any image upload fails, the whole op throws — caller surfaces the
/// error. No partial listings are created.
Future<String?> createListing({
  required WidgetRef ref,
  required String title,
  required String description,
  required double priceInr,
  required ListingCondition condition,
  String? category,
  String? sellerPhone,
  List<File> imageFiles = const [],
  void Function(int current, int total)? onImageProgress,
}) async {
  final user = ref.read(currentUserProvider);
  final profile = ref.read(userProfileProvider).value;
  if (user == null) {
    throw StateError('Must be signed in to post a listing.');
  }

  final docRef = FirebaseFirestore.instance
      .collection(FirestorePaths.marketplace())
      .doc();

  final urls = <String>[];
  for (var i = 0; i < imageFiles.length; i++) {
    onImageProgress?.call(i + 1, imageFiles.length);
    final storageRef = FirebaseStorage.instance
        .ref('Marketplace/${docRef.id}/$i.jpg');
    await storageRef.putFile(imageFiles[i]).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException(
              'Image upload timed out. Check your connection and retry.'),
        );
    final url = await storageRef.getDownloadURL();
    urls.add(url);
  }

  final listing = MarketplaceListing(
    id: docRef.id,
    title: title,
    description: description,
    priceInr: priceInr,
    condition: condition,
    category: category,
    imageUrls: urls,
    sellerUid: user.uid,
    sellerName: profile?.name,
    sellerPhone: sellerPhone,
    createdAt: DateTime.now(),
  );
  await docRef.set(listing.toMap());
  return docRef.id;
}

/// Deletes a listing + its Storage folder. Caller should verify ownership
/// client-side (Phase 4 rules will enforce server-side).
Future<void> deleteListing({
  required String listingId,
  required int imageCount,
}) async {
  // Delete Firestore doc first — it's what gates visibility.
  await FirebaseFirestore.instance
      .doc(FirestorePaths.marketplaceListing(listingId))
      .delete();

  // Best-effort Storage cleanup. Failures are non-fatal: orphaned files
  // waste ~MB but the listing is gone from every user's UI.
  for (var i = 0; i < imageCount; i++) {
    try {
      await FirebaseStorage.instance
          .ref('Marketplace/$listingId/$i.jpg')
          .delete();
    } catch (_) {/* ignore */}
  }
}

/// Idempotent seeder — 4 demo listings with no images so the list feels
/// alive without requiring cached network images. Creates only if empty.
Future<void> seedDemoListings(WidgetRef ref) async {
  final snap = await FirebaseFirestore.instance
      .collection(FirestorePaths.marketplace())
      .limit(1)
      .get();
  if (snap.docs.isNotEmpty) return;

  final seeds = <({
    String title,
    String description,
    double price,
    ListingCondition cond,
    String category,
    String phone,
  })>[
    (
      title: 'Cormen CLRS (3rd edition)',
      description:
          'Like-new Algorithms textbook, barely used. Some pencil highlighting in chapter 3. Perfect for DAA coursework.',
      price: 650,
      cond: ListingCondition.likeNew,
      category: 'CSE',
      phone: '919000000001',
    ),
    (
      title: 'Signals & Systems — Oppenheim',
      description:
          'Used for ECE Sem 4. Clean copy, no markings. Selling because I\'m past this semester.',
      price: 400,
      cond: ListingCondition.good,
      category: 'ECE',
      phone: '919000000002',
    ),
    (
      title: 'Scientific Calculator (Casio FX-991ES)',
      description:
          'Allowed in every campus exam. Working perfectly, only cosmetic wear on back.',
      price: 800,
      cond: ListingCondition.good,
      category: 'All branches',
      phone: '919000000003',
    ),
    (
      title: 'DBMS + OS combo pack',
      description:
          'Both books cover all Sem 3 syllabus for JNTUH CSE. Authors: Ramakrishnan (DBMS), Silberschatz (OS).',
      price: 900,
      cond: ListingCondition.good,
      category: 'CSE',
      phone: '919000000004',
    ),
  ];

  for (final s in seeds) {
    await createListing(
      ref: ref,
      title: s.title,
      description: s.description,
      priceInr: s.price,
      condition: s.cond,
      category: s.category,
      sellerPhone: s.phone,
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}
