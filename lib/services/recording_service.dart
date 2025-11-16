import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing emergency audio recordings
class RecordingService {
  static final RecordingService _instance = RecordingService._internal();
  factory RecordingService() => _instance;
  RecordingService._internal();

  final AudioRecorder _recorder = AudioRecorder();

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

  /// Request microphone permission
  Future<bool> _requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Generate filename with timestamp
  String _generateFilename() {
    final now = DateTime.now();
    final timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
    return 'emergency_record_$timestamp.m4a';
  }

  /// Start recording
  Future<bool> startRecording() async {
    if (_isRecording) {
      print('Already recording');
      return false;
    }

    try {
      // Request permission
      final hasPermission = await _requestPermission();
      if (!hasPermission) {
        print('Microphone permission denied');
        return false;
      }

      // Check if recorder is available
      if (!await _recorder.hasPermission()) {
        print('No recording permission');
        return false;
      }

      // Get temporary directory for recording
      final tempDir = await getTemporaryDirectory();
      final filename = _generateFilename();
      _currentRecordingPath = '${tempDir.path}/$filename';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
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

      print('Recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      print('Error starting recording: $e');
      _isRecording = false;
      _recordingStateController.add(false);
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      print('Not currently recording');
      return null;
    }

    try {
      // Stop recording
      final path = await _recorder.stop();

      _isRecording = false;
      _recordingStartTime = null;
      _recordingStateController.add(false);

      // Cancel duration timer
      _durationTimer?.cancel();
      _durationTimer = null;
      _durationController.add(Duration.zero);

      print('Recording stopped: $path');

      // Verify file exists
      if (path != null && await File(path).exists()) {
        final recordingPath = _currentRecordingPath;
        _currentRecordingPath = null;
        return recordingPath ?? path;
      } else {
        print('Recording file not found');
        return null;
      }
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      _recordingStateController.add(false);
      _durationTimer?.cancel();
      return null;
    }
  }

  /// Cancel recording without saving
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stop();

      // Delete the recording file
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Error canceling recording: $e');
    } finally {
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
    _recorder.dispose();
    _recordingStateController.close();
    _durationController.close();
  }
}
