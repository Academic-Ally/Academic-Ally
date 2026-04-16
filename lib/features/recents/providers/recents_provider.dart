import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/recent_pdf_model.dart';
import '../../../models/resource_model.dart';

const _maxRecents = 50;

class RecentsNotifier extends Notifier<List<RecentPdfModel>> {
  @override
  List<RecentPdfModel> build() {
    _loadRecents();
    return [];
  }

  Future<void> _loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(AppConstants.recentPdfsKey);
    if (jsonStr == null) return;

    final list = (jsonDecode(jsonStr) as List<dynamic>)
        .map((item) => RecentPdfModel.fromMap(item as Map<String, dynamic>))
        .toList();

    // Sort by most recent first
    list.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
    state = list;
  }

  Future<void> _saveRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(state.map((r) => r.toMap()).toList());
    await prefs.setString(AppConstants.recentPdfsKey, jsonStr);
  }

  /// Add a resource to recents.
  Future<void> addRecent(ResourceModel resource) async {
    // Remove if already exists (will re-add at top)
    final updated = state.where((r) => r.id != resource.id).toList();

    final recent = RecentPdfModel(
      id: resource.id,
      name: resource.name,
      subject: resource.subject,
      category: resource.category,
      sem: resource.sem,
      branch: resource.branch,
      storageId: resource.storageId,
      university: resource.university,
      course: resource.course,
      viewedAt: DateTime.now(),
    );

    updated.insert(0, recent);

    // Trim to max size
    if (updated.length > _maxRecents) {
      updated.removeRange(_maxRecents, updated.length);
    }

    state = updated;
    await _saveRecents();
  }

  /// Remove a single recent entry.
  Future<void> removeRecent(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _saveRecents();
  }

  /// Clear all recents.
  Future<void> clearAll() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.recentPdfsKey);
  }
}

final recentsProvider =
    NotifierProvider<RecentsNotifier, List<RecentPdfModel>>(
        RecentsNotifier.new);
