import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'encryption_service.dart';
import 'cache_service.dart';

/// Service for managing video playback with support for encrypted files
class VideoPlayerService {
  static final VideoPlayerService _instance = VideoPlayerService._internal();
  factory VideoPlayerService() => _instance;
  VideoPlayerService._internal();

  VideoPlayerController? _videoPlayerController;
  final EncryptionService _encryptionService = EncryptionService();
  final CacheService _cacheService = CacheService();

  String? _decryptedTempPath;

  final _playbackStateController = StreamController<VideoPlayerValue>.broadcast();
  final _initializationController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  /// Stream of playback state
  Stream<VideoPlayerValue> get playbackStateStream =>
      _playbackStateController.stream;

  /// Stream of initialization status
  Stream<bool> get initializationStream => _initializationController.stream;

  /// Stream of errors
  Stream<String> get errorStream => _errorController.stream;

  /// Get current video player controller
  VideoPlayerController? get controller => _videoPlayerController;

  /// Check if video is initialized
  bool get isInitialized => _videoPlayerController?.value.isInitialized ?? false;

  /// Check if currently playing
  bool get isPlaying => _videoPlayerController?.value.isPlaying ?? false;

  /// Check if paused
  bool get isPaused =>
      isInitialized && !isPlaying && (_videoPlayerController?.value.position.inMilliseconds ?? 0) > 0;

  /// Check if buffering
  bool get isBuffering => _videoPlayerController?.value.isBuffering ?? false;

  /// Get current position
  Duration get position => _videoPlayerController?.value.position ?? Duration.zero;

  /// Get total duration
  Duration get duration => _videoPlayerController?.value.duration ?? Duration.zero;

  /// Get aspect ratio
  double get aspectRatio => _videoPlayerController?.value.aspectRatio ?? 16 / 9;

  /// Get volume
  double get volume => _videoPlayerController?.value.volume ?? 1.0;

  /// Decrypt and prepare encrypted video file for playback
  Future<String?> _prepareEncryptedFile(
    String encryptedPath,
    String encryptedKey,
    String iv,
    String? hmac,
  ) async {
    try {
      // Read encrypted file
      final encryptedFile = File(encryptedPath);
      if (!await encryptedFile.exists()) {
        print('Encrypted file not found: $encryptedPath');
        _errorController.add('Video file not found');
        return null;
      }

      final encryptedData = await encryptedFile.readAsBytes();

      // Convert base64 strings to Uint8List
      final encryptedKeyBytes = Uint8List.fromList(base64.decode(encryptedKey));
      final ivBytes = Uint8List.fromList(base64.decode(iv));
      final hmacBytes = hmac != null ? Uint8List.fromList(base64.decode(hmac)) : null;

      // Decrypt the file
      final decryptedData = await _encryptionService.decryptFile(
        encryptedData,
        encryptedKeyBytes,
        ivBytes,
        hmacBytes,
      );

      // Save to temporary file for playback
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath = '${tempDir.path}/temp_video_$timestamp.mp4';

      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(decryptedData);

      // Track the temporary file for cleanup
      _cacheService.trackFile(tempPath);

      return tempPath;
    } catch (e) {
      print('Error preparing encrypted file: $e');
      _errorController.add('Failed to decrypt video: $e');
      return null;
    }
  }

  /// Initialize video player with encrypted file
  Future<bool> initializeEncrypted(
    String encryptedPath,
    String encryptedKey,
    String iv,
    String? hmac,
  ) async {
    try {
      // Stop current playback if any
      await dispose();

      // Prepare decrypted file
      _decryptedTempPath = await _prepareEncryptedFile(
        encryptedPath,
        encryptedKey,
        iv,
        hmac,
      );

      if (_decryptedTempPath == null) {
        print('Failed to prepare video file');
        _initializationController.add(false);
        return false;
      }

      // Initialize video player
      _videoPlayerController = VideoPlayerController.file(File(_decryptedTempPath!));

      // Listen to player updates
      _videoPlayerController!.addListener(() {
        if (_videoPlayerController != null) {
          _playbackStateController.add(_videoPlayerController!.value);
        }
      });

      // Initialize the controller
      await _videoPlayerController!.initialize();
      
      _initializationController.add(true);
      return true;
    } catch (e) {
      print('Error initializing video: $e');
      _errorController.add('Failed to initialize video: $e');
      _initializationController.add(false);
      return false;
    }
  }

  /// Initialize video player with non-encrypted file
  Future<bool> initialize(String filePath) async {
    try {
      await dispose();

      _videoPlayerController = VideoPlayerController.file(File(filePath));

      // Listen to player updates
      _videoPlayerController!.addListener(() {
        if (_videoPlayerController != null) {
          _playbackStateController.add(_videoPlayerController!.value);
        }
      });

      await _videoPlayerController!.initialize();
      
      _initializationController.add(true);
      return true;
    } catch (e) {
      print('Error initializing video: $e');
      _errorController.add('Failed to initialize video: $e');
      _initializationController.add(false);
      return false;
    }
  }

  /// Play video
  Future<void> play() async {
    try {
      if (_videoPlayerController != null && isInitialized) {
        await _videoPlayerController!.play();
      }
    } catch (e) {
      print('Error playing video: $e');
      _errorController.add('Failed to play video: $e');
    }
  }

  /// Pause video
  Future<void> pause() async {
    try {
      if (_videoPlayerController != null && isInitialized) {
        await _videoPlayerController!.pause();
      }
    } catch (e) {
      print('Error pausing video: $e');
      _errorController.add('Failed to pause video: $e');
    }
  }

  /// Seek to position
  Future<void> seekTo(Duration position) async {
    try {
      if (_videoPlayerController != null && isInitialized) {
        await _videoPlayerController!.seekTo(position);
      }
    } catch (e) {
      print('Error seeking: $e');
      _errorController.add('Failed to seek: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      if (_videoPlayerController != null && isInitialized) {
        await _videoPlayerController!.setVolume(volume.clamp(0.0, 1.0));
      }
    } catch (e) {
      print('Error setting volume: $e');
      _errorController.add('Failed to set volume: $e');
    }
  }

  /// Set looping
  Future<void> setLooping(bool looping) async {
    try {
      if (_videoPlayerController != null && isInitialized) {
        await _videoPlayerController!.setLooping(looping);
      }
    } catch (e) {
      print('Error setting looping: $e');
    }
  }

  /// Dispose video player and clean up resources
  Future<void> dispose() async {
    try {
      if (_videoPlayerController != null) {
        await _videoPlayerController!.pause();
        await _videoPlayerController!.dispose();
        _videoPlayerController = null;
      }

      // Clean up temporary decrypted file
      if (_decryptedTempPath != null) {
        await _cacheService.deleteTrackedFile(_decryptedTempPath!);
        _decryptedTempPath = null;
      }
    } catch (e) {
      print('Error disposing video player: $e');
    }
  }

  /// Dispose all resources including streams
  Future<void> disposeAll() async {
    await dispose();
    await _playbackStateController.close();
    await _initializationController.close();
    await _errorController.close();
  }
}
