import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

class VideoPreloadService {
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  // Preload multiple videos based on URLs
  Future<void> preloadVideos(List<String> urls) async {
    for (final url in urls) {
      if (url.isEmpty) continue;

      try {
        // downloadFile starts the download if not already cached
        // We don't await it here to allow background concurrent downloads
        _cacheManager
            .downloadFile(url)
            .then((fileInfo) {
              debugPrint('Successfully preloaded video: $url');
            })
            .catchError((e) {
              debugPrint('Error preloading video $url: $e');
            });
      } catch (e) {
        debugPrint('Error preloading video $url: $e');
      }
    }
  }

  // Get cached file if it exists, otherwise return null
  Future<File?> getCachedVideo(String url) async {
    try {
      final fileInfo = await _cacheManager.getFileFromCache(url);
      if (fileInfo != null && await fileInfo.file.exists()) {
        return fileInfo.file;
      }
    } catch (e) {
      debugPrint('Error checking cache for $url: $e');
    }
    return null;
  }

  // Method to get file and wait if necessary (used by VideoPlayer)
  Future<File> getSingleVideo(String url) async {
    final fileInfo = await _cacheManager.getSingleFile(url);
    return fileInfo;
  }
}

final videoPreloadServiceProvider = Provider<VideoPreloadService>((ref) {
  return VideoPreloadService();
});
