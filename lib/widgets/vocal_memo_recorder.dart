import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/audio_recording_service.dart';

/// Widget for recording vocal memos with visual feedback
class VocalMemoRecorder extends StatefulWidget {
  final Function(String filePath) onRecordingComplete;
  final Function(String error) onError;

  const VocalMemoRecorder({
    super.key,
    required this.onRecordingComplete,
    required this.onError,
  });

  @override
  State<VocalMemoRecorder> createState() => _VocalMemoRecorderState();
}

class _VocalMemoRecorderState extends State<VocalMemoRecorder>
    with SingleTickerProviderStateMixin {
  final _audioRecordingService = AudioRecordingService();
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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Listen to recording state changes
    _stateSubscription = _audioRecordingService.recordingStateStream.listen((
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
    _durationSubscription = _audioRecordingService.durationStream.listen((duration) {
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

  Future<void> _startRecording() async {
    final success = await _audioRecordingService.startRecording();
    if (!success) {
      widget.onError(
        'Failed to start recording. Please check microphone permissions.',
      );
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecordingService.stopRecording();
    if (path != null) {
      widget.onRecordingComplete(path);
    } else {
      widget.onError('Failed to save recording');
    }
  }

  Future<void> _cancelRecording() async {
    await _audioRecordingService.cancelRecording();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording cancelled'),
          duration: Duration(seconds: 2),
        ),
      );
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusLarge,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              _isRecording ? 'Recording...' : 'Record Vocal Memo',
              style: AppTheme.heading4.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Recording animation and duration
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRecording ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
                      border: Border.all(
                        color: _isRecording ? Colors.red : Colors.grey,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.mic,
                      size: 60,
                      color: _isRecording ? Colors.red : Colors.grey,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Duration display
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing12,
              ),
              decoration: BoxDecoration(
                color: _isRecording
                    ? AppTheme.error.withValues(alpha: 0.1)
                    : AppTheme.neutral100,
                borderRadius: AppTheme.borderRadiusXLarge,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isRecording)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (_isRecording) const SizedBox(width: 12),
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _isRecording ? Colors.red : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            if (!_isRecording) ...[
              // Start recording button
              ElevatedButton.icon(
                onPressed: _startRecording,
                icon: const Icon(Icons.fiber_manual_record, size: 24),
                label: const Text(
                  'Start Recording',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing32,
                    vertical: AppTheme.spacing16,
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ] else ...[
              // Stop and cancel buttons when recording
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cancelRecording,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _stopRecording,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: AppTheme.spacing16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
