import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/audio_player_service.dart';

/// Widget for playing audio files with controls
class AudioPlayerWidget extends StatefulWidget {
  final String encryptedPath;
  final String encryptedKey;
  final String iv;
  final String? hmac;
  final String fileName;

  const AudioPlayerWidget({
    super.key,
    required this.encryptedPath,
    required this.encryptedKey,
    required this.iv,
    this.hmac,
    required this.fileName,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final _audioPlayerService = AudioPlayerService();
  
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    await _audioPlayerService.initialize();

    // Listen to player state
    _stateSubscription = _audioPlayerService.playbackStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });

    // Listen to duration
    _durationSubscription = _audioPlayerService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    // Listen to position
    _positionSubscription = _audioPlayerService.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _audioPlayerService.stop();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (_isLoading) return;

    if (_playerState == PlayerState.playing) {
      await _audioPlayerService.pause();
    } else if (_playerState == PlayerState.paused) {
      await _audioPlayerService.resume();
    } else {
      // Start playing
      setState(() {
        _isLoading = true;
      });

      final success = await _audioPlayerService.playEncrypted(
        widget.encryptedPath,
        widget.encryptedKey,
        widget.iv,
        widget.hmac,
      );

      setState(() {
        _isLoading = false;
      });

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to play audio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stop() async {
    await _audioPlayerService.stop();
  }

  void _onSeek(double value) {
    final position = Duration(milliseconds: value.toInt());
    _audioPlayerService.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playerState == PlayerState.playing;
    final isStopped = _playerState == PlayerState.stopped || 
                      _playerState == PlayerState.completed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // File name
          Row(
            children: [
              Icon(Icons.audiotrack, color: Colors.red[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                ),
                child: Slider(
                  value: _position.inMilliseconds.toDouble(),
                  max: _duration.inMilliseconds.toDouble() > 0
                      ? _duration.inMilliseconds.toDouble()
                      : 1.0,
                  onChanged: isStopped ? null : _onSeek,
                  activeColor: Colors.red,
                  inactiveColor: Colors.grey[300],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stop button
              if (!isStopped)
                IconButton(
                  onPressed: _stop,
                  icon: const Icon(Icons.stop),
                  iconSize: 32,
                  color: Colors.grey[700],
                ),
              const SizedBox(width: 16),

              // Play/Pause button
              _isLoading
                  ? const SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _playPause,
                        icon: Icon(
                          isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        iconSize: 32,
                        color: Colors.white,
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
