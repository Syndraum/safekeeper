import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Service for managing temporary cache files for security purposes
/// Ensures decrypted files are properly cleaned up
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Track temporary files created by the app
  final Set<String> _trackedFiles = {};
  
  // Track if service is initialized
  bool _isInitialized = false;

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Clear any leftover cache from previous sessions
      await clearAllCache();
      _isInitialized = true;
      print('CacheService initialized and cleaned');
    } catch (e) {
      print('Error initializing CacheService: $e');
    }
  }

  /// Register a temporary file for tracking
  void trackFile(String filePath) {
    _trackedFiles.add(filePath);
    print('Tracking temp file: $filePath');
  }

  /// Unregister a temporary file
  void untrackFile(String filePath) {
    _trackedFiles.remove(filePath);
  }

  /// Delete a specific tracked file
  Future<bool> deleteTrackedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('Deleted tracked file: $filePath');
      }
      _trackedFiles.remove(filePath);
      return true;
    } catch (e) {
      print('Error deleting tracked file $filePath: $e');
      return false;
    }
  }

  /// Clear all tracked temporary files
  Future<int> clearTrackedFiles() async {
    int deletedCount = 0;
    final filesToDelete = List<String>.from(_trackedFiles);
    
    for (final filePath in filesToDelete) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          deletedCount++;
          print('Deleted tracked file: $filePath');
        }
        _trackedFiles.remove(filePath);
      } catch (e) {
        print('Error deleting tracked file $filePath: $e');
      }
    }
    
    return deletedCount;
  }

  /// Clear all cache files in the temporary directory
  /// This includes all decrypted files (images, PDFs, audio, etc.)
  Future<int> clearAllCache() async {
    int deletedCount = 0;
    
    try {
      final tempDir = await getTemporaryDirectory();
      
      if (await tempDir.exists()) {
        final List<FileSystemEntity> files = tempDir.listSync();
        
        for (final file in files) {
          try {
            if (file is File) {
              await file.delete();
              deletedCount++;
              print('Deleted cache file: ${file.path}');
            } else if (file is Directory) {
              // Recursively delete subdirectories
              await file.delete(recursive: true);
              deletedCount++;
              print('Deleted cache directory: ${file.path}');
            }
          } catch (e) {
            print('Error deleting ${file.path}: $e');
          }
        }
      }
      
      // Clear tracked files set
      _trackedFiles.clear();
      
      print('Cache cleared: $deletedCount items deleted');
    } catch (e) {
      print('Error clearing cache: $e');
    }
    
    return deletedCount;
  }

  /// Clear only image cache files
  Future<int> clearImageCache() async {
    return await _clearCacheByExtensions([
      '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.heic', '.heif'
    ]);
  }

  /// Clear only audio cache files
  Future<int> clearAudioCache() async {
    return await _clearCacheByExtensions([
      '.m4a', '.mp3', '.wav', '.aac', '.ogg', '.flac'
    ]);
  }

  /// Clear only PDF cache files
  Future<int> clearPdfCache() async {
    return await _clearCacheByExtensions(['.pdf']);
  }

  /// Clear cache files by specific extensions
  Future<int> _clearCacheByExtensions(List<String> extensions) async {
    int deletedCount = 0;
    
    try {
      final tempDir = await getTemporaryDirectory();
      
      if (await tempDir.exists()) {
        final List<FileSystemEntity> files = tempDir.listSync();
        
        for (final file in files) {
          if (file is File) {
            final fileName = file.path.toLowerCase();
            if (extensions.any((ext) => fileName.endsWith(ext))) {
              try {
                await file.delete();
                deletedCount++;
                _trackedFiles.remove(file.path);
                print('Deleted cache file: ${file.path}');
              } catch (e) {
                print('Error deleting ${file.path}: $e');
              }
            }
          }
        }
      }
      
      print('Cleared $deletedCount files with extensions: $extensions');
    } catch (e) {
      print('Error clearing cache by extensions: $e');
    }
    
    return deletedCount;
  }

  /// Get the total size of cache in bytes
  Future<int> getCacheSize() async {
    int totalSize = 0;
    
    try {
      final tempDir = await getTemporaryDirectory();
      
      if (await tempDir.exists()) {
        final List<FileSystemEntity> files = tempDir.listSync(recursive: true);
        
        for (final file in files) {
          if (file is File) {
            try {
              final stat = await file.stat();
              totalSize += stat.size;
            } catch (e) {
              print('Error getting size of ${file.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error calculating cache size: $e');
    }
    
    return totalSize;
  }

  /// Format bytes to human-readable string
  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Get number of tracked files
  int get trackedFileCount => _trackedFiles.length;

  /// Check if a file is being tracked
  bool isTracked(String filePath) => _trackedFiles.contains(filePath);

  /// Clear cache on app termination or lock
  Future<void> clearOnExit() async {
    print('Clearing cache on exit...');
    await clearAllCache();
  }
}
