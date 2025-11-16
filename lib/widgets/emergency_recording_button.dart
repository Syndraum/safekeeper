import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/recording_service.dart';

/// Floating emergency recording button with recording state UI and camera preview
class EmergencyRecordingButton extends StatefulWidget {
  final VoidCallback onRecordingComplete;
  final Function(String) onError;

  const EmergencyRecordingButton({
    super.key,
    required this.onRecordingComplete,
    required this.onError,
  });

  @override
  State<EmergencyRecordingButton> createState() =>
      _EmergencyRecordingButtonState();
}

class _EmergencyRecordingButtonState extends State<EmergencyRecordingButton>
    with SingleTickerProviderStateMixin {
  final _recordingService = RecordingService();
  bool _isRecording = false;
  Duration _duration = Duration.zero;
  StreamSubscription<bool>? _stateSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Setup pulse animation for recording state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Listen to recording state changes
    _stateSubscription = _recordingService.recordingStateStream.listen((
      isRecording,
    ) {
      if (mounted) {
        setState(() {
          _isRecording = isRecording;
        });

        if (isRecording) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }
      }
    });

    // Listen to duration changes
    _durationSubscription = _recordingService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _durationSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      final path = await _recordingService.stopRecording();
      if (path != null) {
        widget.onRecordingComplete();
      } else {
        widget.onError('Failed to save recording');
      }
    } else {
      // Check permissions first
      final hasPermissions = await _recordingService.checkPermissions();
      if (!hasPermissions) {
        widget.onError(
          'Camera and microphone permissions are required. Please enable them in settings.',
        );
        return;
      }

      // Start recording
      final success = await _recordingService.startRecording();
      if (!success) {
        widget.onError(
          'Failed to start recording. Please check camera and microphone permissions.',
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera preview overlay when recording
        if (_isRecording && _recordingService.cameraController != null)
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: _recordingService.cameraController!.value.isInitialized
                  ? CameraPreview(_recordingService.cameraController!)
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),

        // Recording controls overlay
        if (_isRecording)
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
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Column(
                  children: [
                    // Recording indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
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
                            _formatDuration(_duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Recording label
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

        // Bottom button (always visible)
        Positioned(
          left: 0,
          right: 0,
          bottom: 24 + MediaQuery.of(context).padding.bottom,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              // Responsive button size
              final screenWidth = MediaQuery.of(context).size.width;
              final buttonSize = (screenWidth * 0.18).clamp(56.0, 80.0);
              final iconSize = (buttonSize * 0.5).clamp(28.0, 40.0);

              return Transform.scale(
                scale: _isRecording ? _pulseAnimation.value : 1.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Button
                    SizedBox(
                      width: buttonSize,
                      height: buttonSize,
                      child: FloatingActionButton(
                        onPressed: _toggleRecording,
                        backgroundColor: _isRecording
                            ? Colors.red[700]
                            : Colors.red,
                        elevation: 8,
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.videocam,
                          size: iconSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Integrated label
                    const SizedBox(height: 6),
                    Text(
                      _isRecording ? 'STOP' : 'EMERGENCY',
                      style: TextStyle(
                        color: _isRecording ? Colors.white : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
