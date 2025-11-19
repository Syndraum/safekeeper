import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../core/logger_service.dart';
import 'encryption_service.dart';
import 'cache_service.dart';

/// Service for managing audio playback with support for encrypted files
class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final EncryptionService _encryptionService = EncryptionService();
  final CacheService _cacheService = CacheService();

  String? _decryptedTempPath;

  final _playbackStateController = StreamController<PlayerState>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();

  /// Stream of playback state
  Stream<PlayerState> get playbackStateStream =>
      _playbackStateController.stream;

  /// Stream of audio duration
  Stream<Duration> get durationStream => _durationController.stream;

  /// Stream of current position
  Stream<Duration> get positionStream => _positionController.stream;

  /// Get current playback state
  PlayerState get state => _audioPlayer.state;

  /// Get current position (will be updated via stream)
  Duration _currentPosition = Duration.zero;
  Duration get currentPosition => _currentPosition;

  /// Get total duration (will be updated via stream)
  Duration _currentDuration = Duration.zero;
  Duration get duration => _currentDuration;

  /// Initialize the audio player service
  Future<void> initialize() async {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _playbackStateController.add(state);
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      _currentDuration = duration;
      _durationController.add(duration);
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((position) {
      _currentPosition = position;
      _positionController.add(position);
    });

    // Listen to completion
    _audioPlayer.onPlayerComplete.listen((_) {
      _positionController.add(Duration.zero);
    });
  }

  /// Decrypt and prepare encrypted audio file for playback
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
        AppLogger.error('Encrypted file not found: $encryptedPath');
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
      final tempPath = '${tempDir.path}/temp_audio_$timestamp.m4a';

      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(decryptedData);

      // Track the temporary file for cleanup
      _cacheService.trackFile(tempPath);

      return tempPath;
    } catch (e) {
      AppLogger.error('Error preparing encrypted file', e);
      return null;
    }
  }

  /// Play encrypted audio file
  Future<bool> playEncrypted(
    String encryptedPath,
    String encryptedKey,
    String iv,
    String? hmac,
  ) async {
    try {
      // Stop current playback if any
      await stop();

      // Prepare decrypted file
      _decryptedTempPath = await _prepareEncryptedFile(
        encryptedPath,
        encryptedKey,
        iv,
        hmac,
      );

      if (_decryptedTempPath == null) {
        AppLogger.error('Failed to prepare audio file');
        return false;
      }

      // Play the decrypted file
      await _audioPlayer.play(DeviceFileSource(_decryptedTempPath!));
      return true;
    } catch (e) {
      AppLogger.error('Error playing audio', e);
      return false;
    }
  }

  /// Play audio file (non-encrypted)
  Future<bool> play(String filePath) async {
    try {
      await stop();
      await _audioPlayer.play(DeviceFileSource(filePath));
      return true;
    } catch (e) {
      AppLogger.error('Error playing audio', e);
      return false;
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      AppLogger.error('Error pausing audio', e);
    }
  }

  /// Resume playback
  Future<void> resume() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      AppLogger.error('Error resuming audio', e);
    }
  }

  /// Stop playback and clean up
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();

      // Clean up temporary decrypted file
      if (_decryptedTempPath != null) {
        await _cacheService.deleteTrackedFile(_decryptedTempPath!);
        _decryptedTempPath = null;
      }
    } catch (e) {
      AppLogger.error('Error stopping audio', e);
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      AppLogger.error('Error seeking', e);
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      AppLogger.error('Error setting volume', e);
    }
  }

  /// Check if currently playing
  bool get isPlaying => _audioPlayer.state == PlayerState.playing;

  /// Check if paused
  bool get isPaused => _audioPlayer.state == PlayerState.paused;

  /// Check if stopped
  bool get isStopped =>
      _audioPlayer.state == PlayerState.stopped ||
      _audioPlayer.state == PlayerState.completed;

  /// Dispose resources
  Future<void> dispose() async {
    await stop();
    await _audioPlayer.dispose();
    await _playbackStateController.close();
    await _durationController.close();
    await _positionController.close();
  }
}
