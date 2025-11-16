import 'dart:async';
import 'package:flutter/material.dart';
import '../services/recording_service.dart';

/// Floating emergency recording button with recording state UI
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
      // Start recording
      final success = await _recordingService.startRecording();
      if (!success) {
        widget.onError(
          'Failed to start recording. Please check microphone permissions.',
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
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Recording duration display
          if (_isRecording) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
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
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Main recording button
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isRecording ? _pulseAnimation.value : 1.0,
                child: FloatingActionButton.large(
                  onPressed: _toggleRecording,
                  backgroundColor: _isRecording ? Colors.red[700] : Colors.red,
                  elevation: 8,
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),

          // Label
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _isRecording ? 'RECORDING' : 'EMERGENCY',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
