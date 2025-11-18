import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../services/recording_service.dart';
import '../services/encryption_service.dart';
import '../services/document_service.dart';
import '../services/file_type_detector.dart';
import '../viewmodels/home_view_model.dart';
import '../screens/panic_lock_screen.dart';
import 'emergency_recording_button.dart';
import 'panic_button.dart';

/// Global wrapper that adds emergency recording functionality to all screens
class EmergencyRecordingWrapper extends StatefulWidget {
  final Widget child;

  const EmergencyRecordingWrapper({super.key, required this.child});

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
        ScaffoldMessenger.of(context).showSnackBar(
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

    ScaffoldMessenger.of(context).showSnackBar(
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
    return Stack(
      children: [
        // Main app content
        widget.child,

        // Panic lock screen overlay (blocks everything when active)
        if (_isPanicLocked)
          Positioned.fill(
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => PanicLockScreen(
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
              ],
            ),
          ),

        // Emergency recording button overlay (bottom right)
        if (!_isPanicLocked)
          EmergencyRecordingButton(
            onRecordingComplete: _onRecordingComplete,
            onError: _showError,
          ),

        // Panic button overlay (bottom left)
        if (!_isPanicLocked)
          PanicButton(
            onPanic: _onPanicPressed,
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
    );
  }
}
