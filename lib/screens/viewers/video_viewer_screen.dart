import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/video_player_widget.dart';

/// Video Viewer Screen for video files
class VideoViewerScreen extends StatefulWidget {
  final String encryptedPath;
  final String encryptedKey;
  final String iv;
  final String? hmac;
  final String fileName;
  final String? mimeType;

  const VideoViewerScreen({
    super.key,
    required this.encryptedPath,
    required this.encryptedKey,
    required this.iv,
    this.hmac,
    required this.fileName,
    this.mimeType,
  });

  @override
  State<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<VideoViewerScreen> {
  @override
  void dispose() {
    // Restore system UI and orientation when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _showVideoInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Info'),
        content: Text(
          'File: ${widget.fileName}\n'
          'Type: Video\n'
          '${widget.mimeType != null ? 'MIME: ${widget.mimeType}' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.fileName,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showVideoInfo,
            tooltip: 'Video Info',
          ),
        ],
      ),
      body: Center(
        child: VideoPlayerWidget(
          encryptedPath: widget.encryptedPath,
          encryptedKey: widget.encryptedKey,
          iv: widget.iv,
          hmac: widget.hmac,
          fileName: widget.fileName,
        ),
      ),
    );
  }
}
