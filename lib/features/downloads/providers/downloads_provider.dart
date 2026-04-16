import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../models/resource_model.dart';

class DownloadedFile {
  final String filePath;
  final ResourceModel resource;
  final DateTime downloadedAt;

  const DownloadedFile({
    required this.filePath,
    required this.resource,
    required this.downloadedAt,
  });
}

class DownloadsNotifier extends Notifier<List<DownloadedFile>> {
  @override
  List<DownloadedFile> build() {
    _loadDownloads();
    return [];
  }

  Future<String> get _resourcesDir async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/Resources';
  }

  String _fileName(ResourceModel resource) {
    return '${resource.name}_${resource.branch}_${resource.sem}.pdf';
  }

  Future<void> _loadDownloads() async {
    final dirPath = await _resourcesDir;
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      state = [];
      return;
    }

    final downloads = <DownloadedFile>[];
    final pdfFiles = dir.listSync().where((f) => f.path.endsWith('.pdf'));

    for (final file in pdfFiles) {
      final metaPath = '${file.path}.meta';
      final metaFile = File(metaPath);
      if (!metaFile.existsSync()) continue;

      try {
        final metaJson = await metaFile.readAsString();
        final metaData = jsonDecode(metaJson) as Map<String, dynamic>;
        final resource = ResourceModel(
          id: metaData['id'] ?? '',
          name: metaData['name'] ?? '',
          subject: metaData['subject'] ?? '',
          category: metaData['category'] ?? '',
          sem: metaData['sem'] ?? '',
          branch: metaData['branch'] ?? '',
          storageId: metaData['storageId'],
          university: metaData['university'],
          course: metaData['course'],
        );

        final stat = await File(file.path).stat();
        downloads.add(DownloadedFile(
          filePath: file.path,
          resource: resource,
          downloadedAt: stat.modified,
        ));
      } catch (_) {
        // Skip files with corrupted metadata
      }
    }

    downloads.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    state = downloads;
  }

  /// Check if a resource is downloaded locally.
  Future<String?> getLocalPath(ResourceModel resource) async {
    final dirPath = await _resourcesDir;
    final filePath = '$dirPath/${_fileName(resource)}';
    final file = File(filePath);
    if (await file.exists()) return filePath;
    return null;
  }

  /// Save metadata for a downloaded file.
  Future<void> saveDownloadMeta(ResourceModel resource, String filePath) async {
    final metaPath = '$filePath.meta';
    final metaData = {
      'id': resource.id,
      'name': resource.name,
      'subject': resource.subject,
      'category': resource.category,
      'sem': resource.sem,
      'branch': resource.branch,
      'storageId': resource.storageId,
      'university': resource.university,
      'course': resource.course,
    };
    await File(metaPath).writeAsString(jsonEncode(metaData));
    await _loadDownloads();
  }

  /// Delete a downloaded file and its metadata.
  Future<void> deleteDownload(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) await file.delete();

    final metaFile = File('$filePath.meta');
    if (await metaFile.exists()) await metaFile.delete();

    await _loadDownloads();
  }

  /// Delete all downloaded files.
  Future<void> clearAll() async {
    final dirPath = await _resourcesDir;
    final dir = Directory(dirPath);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
    state = [];
  }

  /// Get the expected file path for a resource download.
  Future<String> getDownloadPath(ResourceModel resource) async {
    final dirPath = await _resourcesDir;
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return '$dirPath/${_fileName(resource)}';
  }
}

final downloadsProvider =
    NotifierProvider<DownloadsNotifier, List<DownloadedFile>>(
        DownloadsNotifier.new);
