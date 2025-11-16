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

  /// Get camera controller for preview
  CameraController? get cameraController => _cameraController;

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

  /// Generate full file path in app documents directory
  Future<String> _generateFilePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final filename = _generateFilename();
    return '${appDir.path}/$filename';
  }

  /// Clean up camera resources
  Future<void> _cleanupCamera() async {
    try {
      await _cameraController?.dispose();
      _cameraController = null;
    } catch (e) {
      print('Error disposing camera: $e');
    }
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

      // Generate file path in app documents directory (not temp)
      // This avoids iOS issues with moving files from temp directory
      _currentRecordingPath = await _generateFilePath();

      // Start video recording directly to final destination
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
      
      // Clean up camera resources on failure
      await _cleanupCamera();
      
      // Reset state
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

      // On iOS, the video file is already in the correct location
      // On Android, we may need to move it
      String finalPath = videoFile.path;

      if (_currentRecordingPath != null &&
          videoFile.path != _currentRecordingPath) {
        try {
          // Try to move/copy the file to our designated path
          final sourceFile = File(videoFile.path);
          final targetFile = File(_currentRecordingPath!);

          // Copy file content
          await sourceFile.copy(_currentRecordingPath!);

          // Verify target file exists
          if (await targetFile.exists()) {
            finalPath = _currentRecordingPath!;

            // Try to delete source file (may fail on some platforms, that's ok)
            try {
              await sourceFile.delete();
            } catch (e) {
              print('Could not delete source file: $e');
            }
          }
        } catch (e) {
          print('Could not move file, using original path: $e');
          // If move fails, use the original path
          finalPath = videoFile.path;
        }
      }

      _currentRecordingPath = null;

      // Clean up camera resources after successful recording
      await _cleanupCamera();

      // Verify final file exists
      final finalFile = File(finalPath);
      if (await finalFile.exists()) {
        print('Recording saved successfully: $finalPath');
        return finalPath;
      } else {
        print('Recording file not found at: $finalPath');
        return null;
      }
    } catch (e) {
      print('Error stopping video recording: $e');
      
      // Clean up camera resources on failure
      await _cleanupCamera();
      
      // Reset state
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
      // Clean up camera resources
      await _cleanupCamera();
      
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
    _cameraController?.dispose();
    _recordingStateController.close();
    _durationController.close();
  }
}
