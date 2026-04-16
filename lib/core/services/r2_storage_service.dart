import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Service for interacting with Cloudflare R2 storage.
/// R2 is S3-compatible, so we use standard S3 patterns.
class R2StorageService {
  // TODO: Fill these when R2 bucket is set up
  static const String publicBaseUrl = ''; // R2 public bucket URL

  /// Get the public URL for a resource stored in R2.
  static String getResourceUrl(String key) {
    return '$publicBaseUrl/$key';
  }

  /// Build the storage key path for a resource.
  static String buildResourceKey({
    required String university,
    required String course,
    required String branch,
    required String sem,
    required String subject,
    required String category,
    required String fileName,
  }) {
    return 'Universities/$university/$course/$branch/$sem/$subject/$category/$fileName';
  }

  /// Build the storage key path for a processed PDF (AllyBot).
  static String buildProcessedPdfKey({
    required String university,
    required String course,
    required String branch,
    required String sem,
    required String subject,
    required String category,
    required String uniqueId,
    required String fileName,
  }) {
    return 'Processed-pdfs/$university/$course/$branch/$sem/$subject/$category/$uniqueId/$fileName';
  }

  /// Download a file from a URL to the local device.
  static Future<String?> downloadFile({
    required String url,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final resourcesDir = Directory('${dir.path}/Resources');
      if (!resourcesDir.existsSync()) {
        resourcesDir.createSync(recursive: true);
      }

      final filePath = '${resourcesDir.path}/$fileName';
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      final List<int> bytes = [];

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && onProgress != null) {
          onProgress(receivedBytes / totalBytes);
        }
      }

      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  /// Check if a file exists locally.
  static Future<String?> getLocalFilePath(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/Resources/$fileName';
    final file = File(filePath);
    if (await file.exists()) {
      return filePath;
    }
    return null;
  }

  /// Delete a locally downloaded file.
  static Future<bool> deleteLocalFile(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/Resources/$fileName';
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      // Also delete metadata file
      final metaFile = File('$filePath.text');
      if (await metaFile.exists()) {
        await metaFile.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// List all locally downloaded files.
  static Future<List<FileSystemEntity>> listLocalFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final resourcesDir = Directory('${dir.path}/Resources');
    if (!resourcesDir.existsSync()) {
      return [];
    }
    return resourcesDir.listSync().where((f) => f.path.endsWith('.pdf')).toList();
  }
}
