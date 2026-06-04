import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import '../storage/storage_service.dart';

/// Manages saving/loading AI chat images to the local filesystem.
/// Stores only file paths in GetStorage instead of base64 data,
/// preventing storage corruption from large payloads.
class ImageCacheService extends GetxService {
  static ImageCacheService get to => Get.find();

  static const String _imagesDir = 'ai_chat_images';
  Directory? _cacheDir;

  Future<ImageCacheService> init() async {
    if (!kIsWeb) {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/$_imagesDir');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
    }
    return this;
  }

  /// Save a base64 data URI to the filesystem, returns the local file path.
  /// Returns null on web or if save fails.
  Future<String?> saveImage(String base64DataUri) async {
    if (kIsWeb || _cacheDir == null) return null;
    try {
      final ext = _extFromMimeType(base64DataUri);
      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}_$ext';
      final filePath = '${_cacheDir!.path}/$fileName';

      // Extract raw bytes from data URI
      final data = base64DataUri;
      final commaIdx = data.indexOf(',');
      if (commaIdx < 0) return null;
      final raw = data.substring(commaIdx + 1);
      final bytes = base64Decode(raw);

      await File(filePath).writeAsBytes(bytes, flush: true);
      return filePath;
    } catch (_) {
      return null;
    }
  }

  /// Save multiple images, returns list of file paths (null entries for failures).
  Future<List<String?>> saveImages(List<String> base64DataUris) async {
    final results = <String?>[];
    for (final uri in base64DataUris) {
      results.add(await saveImage(uri));
    }
    return results;
  }

  /// Load an image from its local file path as a base64 data URI.
  /// Returns null if file doesn't exist or on web.
  Future<String?> loadImage(String filePath) async {
    if (kIsWeb) return null;
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final ext = _extFromPath(filePath);
      final mime = _mimeFromExt(ext);
      return 'data:$mime;base64,${base64Encode(bytes)}';
    } catch (_) {
      return null;
    }
  }

  /// Delete image files for a given list of file paths.
  Future<void> deleteImages(List<String> filePaths) async {
    if (kIsWeb) return;
    for (final path in filePaths) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  /// Delete all cached images.
  Future<void> clearAll() async {
    if (kIsWeb || _cacheDir == null) return;
    try {
      if (await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create(recursive: true);
      }
    } catch (_) {}
  }

  /// Convert message images: if a path points to a local file, keep it;
  /// if it's a base64 data URI, save it to disk and return the path.
  /// Used when loading messages from storage (migration from old format).
  Future<List<String>> migrateImages(List<String> images) async {
    final migrated = <String>[];
    for (final img in images) {
      if (img.startsWith('data:image')) {
        // Old format: base64 data URI — save to filesystem
        final path = await saveImage(img);
        migrated.add(path ?? img); // fallback to keeping original if save fails
      } else {
        migrated.add(img);
      }
    }
    return migrated;
  }

  /// Check if a string looks like a local file path (not a data URI).
  static bool isFilePath(String s) => !s.startsWith('data:');

  String _extFromMimeType(String dataUri) {
    if (dataUri.contains('image/png')) return 'png';
    if (dataUri.contains('image/gif')) return 'gif';
    if (dataUri.contains('image/webp')) return 'webp';
    return 'jpg';
  }

  String _extFromPath(String path) {
    final dot = path.lastIndexOf('.');
    return dot >= 0 ? path.substring(dot + 1).toLowerCase() : 'jpg';
  }

  String _mimeFromExt(String ext) {
    switch (ext) {
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      default: return 'image/jpeg';
    }
  }
}
