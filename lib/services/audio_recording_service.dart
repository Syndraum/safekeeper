import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../core/logger_service.dart';

/// Service for managing audio-only recordings (vocal memos)
class AudioRecordingService {
  static final AudioRecordingService _instance = AudioRecordingService._internal();
  factory AudioRecordingService() => _instance;
  AudioRecordingService._internal();

  AudioRecorder? _audioRecorder;

  bool _isRecording = false;
  DateTime? _recordingStartTime;
  Timer? _durationTimer;
  String? _currentRecordingPath;

  final _recordingStateController = StreamController<bool>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();

  /// Stream of recording state (true = recording, false = not recording)
  Stream<bool> get recordingStateStream => _recordingStateController.stream;

  /// Stream of recording duration
  Stream<Duration> get durationStream => _durationController.stream;

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Get current recording duration
  Duration get currentDuration {
    if (_recordingStartTime == null) return Duration.zero;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Check and request microphone permission
  Future<bool> _requestPermissions() async {
    // Check current permission status
    final microphoneStatus = await Permission.microphone.status;

    // If permission is permanently denied, return false
    if (microphoneStatus.isPermanentlyDenied) {
      AppLogger.warning('Microphone permission permanently denied. Please enable in settings.');
      return false;
    }

    // Request permission if not granted
    if (!microphoneStatus.isGranted) {
      final status = await Permission.microphone.request();
      return status.isGranted;
    }

    return true;
  }

  /// Check if permissions are granted (without requesting)
  Future<bool> checkPermissions() async {
    final microphoneStatus = await Permission.microphone.status;
    return microphoneStatus.isGranted;
  }

  /// Generate filename with timestamp
  String _generateFilename() {
    final now = DateTime.now();
    final timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
    return 'vocal_memo_$timestamp.m4a';
  }

  /// Generate full file path in app documents directory
  Future<String> _generateFilePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final filename = _generateFilename();
    return '${appDir.path}/$filename';
  }

  /// Start audio recording
  Future<bool> startRecording() async {
    if (_isRecording) {
      AppLogger.warning('Already recording');
      return false;
    }

    try {
      // Request permissions
      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        AppLogger.warning('Microphone permission denied');
        return false;
      }

      // Create a new recorder instance
      _audioRecorder = AudioRecorder();

      // Check if the recorder has permission
      if (!await _audioRecorder!.hasPermission()) {
        AppLogger.warning('Audio recorder does not have permission');
        return false;
      }

      // Generate file path
      _currentRecordingPath = await _generateFilePath();

      // Configure audio recording settings
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc, // AAC-LC encoder for good quality and compatibility
        bitRate: 128000, // 128 kbps
        sampleRate: 44100, // 44.1 kHz
        numChannels: 1, // Mono
      );

      // Start recording
      await _audioRecorder!.start(
        config,
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _recordingStateController.add(true);

      // Start duration timer
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_recordingStartTime != null) {
          _durationController.add(currentDuration);
        }
      });

      AppLogger.info('Audio recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      AppLogger.error('Error starting audio recording', e);
      
      // Reset state on failure
      _audioRecorder?.dispose();
      _audioRecorder = null;
      _isRecording = false;
      _recordingStartTime = null;
      _currentRecordingPath = null;
      _recordingStateController.add(false);
      _durationTimer?.cancel();
      _durationTimer = null;
      _durationController.add(Duration.zero);
      
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    if (!_isRecording || _audioRecorder == null) {
      AppLogger.warning('Not currently recording');
      return null;
    }

    try {
      // Stop audio recording
      final path = await _audioRecorder!.stop();

      _isRecording = false;
      _recordingStartTime = null;
      _recordingStateController.add(false);

      // Cancel duration timer
      _durationTimer?.cancel();
      _durationTimer = null;
      _durationController.add(Duration.zero);

      // Dispose the recorder
      await _audioRecorder!.dispose();
      _audioRecorder = null;

      if (path != null) {
        AppLogger.info('Audio recording stopped: $path');

        // Verify file exists
        final file = File(path);
        if (await file.exists()) {
          final filePath = _currentRecordingPath ?? path;
          _currentRecordingPath = null;
          return filePath;
        } else {
          AppLogger.warning('Recording file not found at: $path');
          _currentRecordingPath = null;
          return null;
        }
      } else {
        AppLogger.warning('Recording path is null');
        _currentRecordingPath = null;
        return null;
      }
    } catch (e) {
      AppLogger.error('Error stopping audio recording', e);
      
      // Reset state on failure
      _audioRecorder?.dispose();
      _audioRecorder = null;
      _isRecording = false;
      _recordingStartTime = null;
      _currentRecordingPath = null;
      _recordingStateController.add(false);
      _durationTimer?.cancel();
      _durationTimer = null;
      _durationController.add(Duration.zero);
      
      return null;
    }
  }

  /// Cancel recording without saving
  Future<void> cancelRecording() async {
    if (!_isRecording || _audioRecorder == null) return;

    try {
      // Stop recording
      final path = await _audioRecorder!.stop();

      // Delete the recording file if it exists
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Also delete from current recording path if different
      if (_currentRecordingPath != null && _currentRecordingPath != path) {
        final currentFile = File(_currentRecordingPath!);
        if (await currentFile.exists()) {
          await currentFile.delete();
        }
      }
    } catch (e) {
      AppLogger.error('Error canceling recording', e);
    } finally {
      // Dispose the recorder
      _audioRecorder?.dispose();
      _audioRecorder = null;
      
      // Reset state
      _isRecording = false;
      _recordingStartTime = null;
      _currentRecordingPath = null;
      _recordingStateController.add(false);
      _durationTimer?.cancel();
      _durationTimer = null;
      _durationController.add(Duration.zero);
    }
  }

  /// Dispose resources
  void dispose() {
    _durationTimer?.cancel();
    _audioRecorder?.dispose();
    _recordingStateController.close();
    _durationController.close();
  }
}
