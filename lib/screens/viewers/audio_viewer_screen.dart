import 'package:flutter/material.dart';
import '../../widgets/audio_player_widget.dart';

/// Audio Viewer Screen for audio files
class AudioViewerScreen extends StatelessWidget {
  final String encryptedPath;
  final String encryptedKey;
  final String iv;
  final String? hmac;
  final String fileName;
  final String? mimeType;

  const AudioViewerScreen({
    super.key,
    required this.encryptedPath,
    required this.encryptedKey,
    required this.iv,
    this.hmac,
    required this.fileName,
    this.mimeType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Audio Info'),
                  content: Text(
                    'File: $fileName\n'
                    'Type: Audio\n'
                    '${mimeType != null ? 'MIME: $mimeType' : ''}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Audio icon
              Icon(
                Icons.audiotrack,
                size: 100,
                color: Colors.red[700],
              ),
              const SizedBox(height: 40),

              // Audio player widget
              AudioPlayerWidget(
                encryptedPath: encryptedPath,
                encryptedKey: encryptedKey,
                iv: iv,
                hmac: hmac,
                fileName: fileName,
              ),
              const SizedBox(height: 40),

              // Info text
              Text(
                'Tap play to listen to your vocal memo',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
