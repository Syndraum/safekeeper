import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../services/video_player_service.dart';

/// Widget for playing video files with controls
class VideoPlayerWidget extends StatefulWidget {
  final String encryptedPath;
  final String encryptedKey;
  final String iv;
  final String? hmac;
  final String fileName;

  const VideoPlayerWidget({
    super.key,
    required this.encryptedPath,
    required this.encryptedKey,
    required this.iv,
    this.hmac,
    required this.fileName,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  final _videoPlayerService = VideoPlayerService();
  
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _showControls = true;
  bool _isFullscreen = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 1.0;
  
  Timer? _hideControlsTimer;
  StreamSubscription<VideoPlayerValue>? _stateSubscription;
  StreamSubscription<bool>? _initSubscription;
  StreamSubscription<String>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    // Listen to initialization
    _initSubscription = _videoPlayerService.initializationStream.listen((initialized) {
      if (mounted) {
        setState(() {
          _isInitialized = initialized;
        });
      }
    });

    // Listen to errors
    _errorSubscription = _videoPlayerService.errorStream.listen((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    // Initialize the video
    final success = await _videoPlayerService.initializeEncrypted(
      widget.encryptedPath,
      widget.encryptedKey,
      widget.iv,
      widget.hmac,
    );

    if (success && mounted) {
      // Listen to player state
      _stateSubscription = _videoPlayerService.playbackStateStream.listen((value) {
        if (mounted) {
          setState(() {
            _isPlaying = value.isPlaying;
            _isBuffering = value.isBuffering;
            _duration = value.duration;
            _position = value.position;
            _volume = value.volume;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _stateSubscription?.cancel();
    _initSubscription?.cancel();
    _errorSubscription?.cancel();
    _videoPlayerService.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _videoPlayerService.pause();
    } else {
      _videoPlayerService.play();
      _startHideControlsTimer();
    }
  }

  void _onSeek(double value) {
    final position = Duration(milliseconds: value.toInt());
    _videoPlayerService.seekTo(position);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls && _isPlaying) {
      _startHideControlsTimer();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      // Enter fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Exit fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  void _adjustVolume(double delta) {
    final newVolume = (_volume + delta).clamp(0.0, 1.0);
    _videoPlayerService.setVolume(newVolume);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _videoPlayerService.controller;
    if (controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Failed to load video',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video player
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),

            // Buffering indicator
            if (_isBuffering)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Controls overlay
            if (_showControls)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top bar with title
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.fileName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Center play/pause button
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _togglePlayPause,
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),

                    // Bottom controls
                    SafeArea(
                      child: Column(
                        children: [
                          // Progress bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Text(
                                  _formatDuration(_position),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 3,
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
                                      onChanged: _onSeek,
                                      activeColor: Colors.red,
                                      inactiveColor: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDuration(_duration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Control buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Volume controls
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => _adjustVolume(-0.1),
                                      icon: const Icon(
                                        Icons.volume_down,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 60,
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 2,
                                          thumbShape: const RoundSliderThumbShape(
                                            enabledThumbRadius: 4,
                                          ),
                                        ),
                                        child: Slider(
                                          value: _volume,
                                          onChanged: (value) {
                                            _videoPlayerService.setVolume(value);
                                          },
                                          activeColor: Colors.white,
                                          inactiveColor: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _adjustVolume(0.1),
                                      icon: const Icon(
                                        Icons.volume_up,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),

                                // Fullscreen toggle
                                IconButton(
                                  onPressed: _toggleFullscreen,
                                  icon: Icon(
                                    _isFullscreen
                                        ? Icons.fullscreen_exit
                                        : Icons.fullscreen,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
