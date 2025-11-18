import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../services/recording_service.dart';
import '../services/encryption_service.dart';
import '../services/document_service.dart';
import '../services/file_type_detector.dart';
import '../viewmodels/home_view_model.dart';
import '../screens/panic_lock_screen.dart';

/// Global wrapper that adds emergency recording functionality to all screens
/// Now works with the new bottom navigation design
class EmergencyRecordingWrapper extends StatefulWidget {
  final Widget child;
  final Function(VoidCallback)? onPanicCallback;
  final Function(VoidCallback)? onRecordingCallback;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  const EmergencyRecordingWrapper({
    super.key,
    required this.child,
    this.onPanicCallback,
    this.onRecordingCallback,
    this.scaffoldMessengerKey,
  });

  @override
  State<EmergencyRecordingWrapper> createState() =>
      _EmergencyRecordingWrapperState();
}

class _EmergencyRecordingWrapperState extends State<EmergencyRecordingWrapper> {
  final _recordingService = RecordingService();
  final _encryptionService = EncryptionService();
  final _documentService = DocumentService();
  bool _isProcessing = false;
  bool _isPanicLocked = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    // Listen to recording state changes
    _recordingService.recordingStateStream.listen((isRecording) {
      if (mounted) {
        setState(() {
          _isRecording = isRecording;
        });
      }
    });
    // Register callbacks for emergency actions after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPanicCallback?.call(_onPanicPressed);
      widget.onRecordingCallback?.call(_toggleRecording);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Handle recording completion - encrypt and save the file
  Future<void> _onRecordingComplete(String recordingPath) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {

      // Read the recorded file
      final recordingFile = File(recordingPath);
      if (!await recordingFile.exists()) {
        _showError('Recording file not found');
        return;
      }

      final fileBytes = await recordingFile.readAsBytes();

      // Extract filename from path
      final fileName = recordingPath.split('/').last;

      // Detect file type
      final fileTypeInfo = FileTypeDetector.detectFromBytes(
        fileBytes,
        fileName: fileName,
      );

      // Encrypt the file using hybrid encryption
      final encryptionResult = await _encryptionService.encryptFile(fileBytes);

      // Save encrypted file to permanent storage
      final appDir = await getApplicationDocumentsDirectory();
      final encryptedPath = '${appDir.path}/$fileName.enc';
      final encryptedFile = File(encryptedPath);
      await encryptedFile.writeAsBytes(encryptionResult.encryptedData);

      // Convert encryption metadata to base64
      final base64Map = encryptionResult.toBase64Map();

      // Save document metadata to database
      await _documentService.addDocument(
        fileName,
        encryptedPath,
        base64Map['encryptedKey']!,
        base64Map['iv']!,
        hmac: base64Map['hmac'],
        mimeType: fileTypeInfo.mimeType,
        fileType: fileTypeInfo.category.name,
      );

      // Delete the temporary recording file
      try {
        await recordingFile.delete();
      } catch (e) {
        print('Error deleting temp file: $e');
      }

      // Show success message
      if (mounted) {
        widget.scaffoldMessengerKey?.currentState?.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Emergency Recording Saved',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        fileName,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error processing recording: $e');
      _showError('Failed to save recording: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Show error message
  void _showError(String message) {
    if (!mounted) return;

    widget.scaffoldMessengerKey?.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Handle emergency recording toggle
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      final path = await _recordingService.stopRecording();
      if (path != null) {
        await _onRecordingComplete(path);
      } else {
        _showError('Failed to save recording');
      }
    } else {
      // Check permissions first
      final hasPermissions = await _recordingService.checkPermissions();
      if (!hasPermissions) {
        _showError(
          'Camera and microphone permissions are required. Please enable them in settings.',
        );
        return;
      }

      // Start recording
      final success = await _recordingService.startRecording();
      if (!success) {
        _showError(
          'Failed to start recording. Please check camera and microphone permissions.',
        );
      }
    }
  }

  /// Handle panic button press
  Future<void> _onPanicPressed() async {
    final homeViewModel = context.read<HomeViewModel>();
    
    setState(() {
      _isPanicLocked = true;
    });

    // Activate panic lock in the view model (clears cache)
    await homeViewModel.activatePanicLock();
  }

  /// Handle unlock attempt from panic screen
  Future<void> _onUnlockAttempt(String password) async {
    final homeViewModel = context.read<HomeViewModel>();
    
    final success = await homeViewModel.unlockFromPanic(password);
    
    if (success) {
      // Unlock successful
      if (mounted) {
        setState(() {
          _isPanicLocked = false;
        });
      }
    } else {
      // Unlock failed - throw error to be caught by PanicLockScreen
      throw Exception('Incorrect password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
        // Main app content
        widget.child,

        // Camera preview overlay when recording (full screen)
        if (_isRecording &&
            _recordingService.cameraController != null &&
            !_isPanicLocked)
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: _recordingService.cameraController!.value.isInitialized
                  ? Stack(
                      children: [
                        // Camera preview
                        Positioned.fill(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _recordingService
                                  .cameraController!.value.previewSize!.height,
                              height: _recordingService
                                  .cameraController!.value.previewSize!.width,
                              child: CameraPreview(
                                  _recordingService.cameraController!),
                            ),
                          ),
                        ),
                        // Recording indicator overlay
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.transparent
                                  ],
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: StreamBuilder<Duration>(
                                      stream: _recordingService.durationStream,
                                      builder: (context, snapshot) {
                                        final duration =
                                            snapshot.data ?? Duration.zero;
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              _formatDuration(duration),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'EMERGENCY RECORDING',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          offset: Offset(0, 1),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Stop button overlay at bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.transparent
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Stop button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _toggleRecording,
                                        borderRadius: BorderRadius.circular(40),
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.5),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.stop,
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Stop label
                                    const Text(
                                      'TAP TO STOP',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            offset: Offset(0, 1),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),

        // Panic lock screen overlay (blocks everything when active)
        if (_isPanicLocked)
          Positioned.fill(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color.fromARGB(255, 36, 77, 124),
                ),
                useMaterial3: true,
              ),
              home: PanicLockScreen(
                onUnlock: _onUnlockAttempt,
                onUnlockSuccess: () {
                  if (mounted) {
                    setState(() {
                      _isPanicLocked = false;
                    });
                  }
                },
              ),
            ),
          ),

        // Processing overlay
        if (_isProcessing && !_isPanicLocked)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Encrypting and saving...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
