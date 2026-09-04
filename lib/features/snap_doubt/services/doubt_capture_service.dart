import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persist context before Android leaves Flutter for the camera/gallery.
class DoubtCaptureService {
  DoubtCaptureService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  static const _key = 'pending_doubt_capture';

  Future<bool> hasPending(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return false;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return data['uid'] == uid && data['subject'] is String;
    } on FormatException {
      await prefs.remove(_key);
      return false;
    } on TypeError {
      await prefs.remove(_key);
      return false;
    }
  }

  Future<XFile?> pick({
    required String uid,
    required String subject,
    required ImageSource source,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode({'uid': uid, 'subject': subject}));
    try {
      return await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
    } finally {
      // This won't execute if Android kills the process. On the next launch
      // recover() consumes the plugin's saved result with this subject/owner.
      await prefs.remove(_key);
    }
  }

  Future<({String imagePath, String subject})?> recover(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (defaultTargetPlatform != TargetPlatform.android) return null;
      final lost = await _picker.retrieveLostData();
      // Consume stale captures without showing another account's photo.
      if (data['uid'] != uid) return null;
      if (lost.exception != null) throw lost.exception!;
      final files = lost.files;
      if (files == null || files.isEmpty) return null;
      return (imagePath: files.first.path, subject: data['subject'] as String);
    } finally {
      await prefs.remove(_key);
    }
  }
}
