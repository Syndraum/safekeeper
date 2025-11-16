import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing emergency video recordings
class RecordingService {
  static final RecordingService _instance = RecordingService._internal();
  factory RecordingService() => _instance;
  RecordingService._internal();

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

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

  /// Check and request camera and microphone permissions
  Future<bool> _requestPermissions() async {
    // Check current permission status
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;

    // If permissions are permanently denied, return false
    if (cameraStatus.isPermanentlyDenied ||
        microphoneStatus.isPermanentlyDenied) {
      print('Permissions permanently denied. Please enable in settings.');
      return false;
    }

    // Request permissions if not granted
    if (!cameraStatus.isGranted || !microphoneStatus.isGranted) {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      return statuses[Permission.camera]!.isGranted &&
          statuses[Permission.microphone]!.isGranted;
    }

    return true;
  }

  /// Check if permissions are granted (without requesting)
  Future<bool> checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;
    return cameraStatus.isGranted && microphoneStatus.isGranted;
  }

  /// Initialize camera
  Future<bool> _initializeCamera() async {
    try {
      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        print('No cameras available');
        return false;
      }

      // Use the first available camera (usually back camera)
      final camera = _cameras!.first;

      // Create camera controller
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      // Initialize the controller
      await _cameraController!.initialize();

      return true;
    } catch (e) {
      print('Error initializing camera: $e');
      return false;
    }
  }

  /// Generate filename with timestamp
  String _generateFilename() {
    final now = DateTime.now();
    final timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
    return 'emergency_video_$timestamp.mp4';
  }

  /// Start recording
  Future<bool> startRecording() async {
    if (_isRecording) {
      print('Already recording');
      return false;
    }

    try {
      // Request permissions
      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        print('Camera or microphone permission denied');
        return false;
      }

      // Initialize camera if not already initialized
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        final initialized = await _initializeCamera();
        if (!initialized) {
          print('Failed to initialize camera');
          return false;
        }
      }

      // Get temporary directory for recording
      final tempDir = await getTemporaryDirectory();
      final filename = _generateFilename();
      _currentRecordingPath = '${tempDir.path}/$filename';

      // Start video recording
      await _cameraController!.startVideoRecording();

      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _recordingStateController.add(true);

      // Start duration timer
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_recordingStartTime != null) {
          _durationController.add(currentDuration);
        }
      });

      print('Video recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      print('Error starting video recording: $e');
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
      // Stop video recording
      final videoFile = await _cameraController!.stopVideoRecording();

      _isRecording = false;
      _recordingStartTime = null;
      _recordingStateController.add(false);

      // Cancel duration timer
      _durationTimer?.cancel();
      _durationTimer = null;
      _durationController.add(Duration.zero);

      print('Video recording stopped: ${videoFile.path}');

      // Move file to our designated path if different
      if (_currentRecordingPath != null &&
          videoFile.path != _currentRecordingPath) {
        final targetFile = File(_currentRecordingPath!);
        await videoFile.saveTo(_currentRecordingPath!);

        // Verify file exists at target location
        if (await targetFile.exists()) {
          final recordingPath = _currentRecordingPath;
          _currentRecordingPath = null;
          return recordingPath;
        }
      }

      // Return the video file path
      final recordingPath = videoFile.path;
      _currentRecordingPath = null;
      return recordingPath;
    } catch (e) {
      print('Error stopping video recording: $e');
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
      // Stop recording
      final videoFile = await _cameraController!.stopVideoRecording();

      // Delete the recording file
      final file = File(videoFile.path);
      if (await file.exists()) {
        await file.delete();
      }

      // Also delete from current recording path if different
      if (_currentRecordingPath != null &&
          _currentRecordingPath != videoFile.path) {
        final currentFile = File(_currentRecordingPath!);
        if (await currentFile.exists()) {
          await currentFile.delete();
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
    _cameraController?.dispose();
    _recordingStateController.close();
    _durationController.close();
  }
}
