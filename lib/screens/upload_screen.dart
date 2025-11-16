import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/encryption_service.dart';
import '../services/document_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _imagePicker = ImagePicker();
  final _encryptionService = EncryptionService();
  final _documentService = DocumentService();

  // Show dialog to rename file before upload
  Future<String?> _showRenameDialog(String originalName) async {
    final TextEditingController controller = TextEditingController(text: originalName);
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'File Name',
            hintText: 'Enter file name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(context, newName);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Common method to encrypt and save a file using hybrid encryption
  Future<void> _encryptAndSaveFile(File file, String fileName) async {
    try {
      // Read file bytes
      Uint8List fileBytes = await file.readAsBytes();

      // Encrypt file using hybrid encryption (AES + RSA)
      final encryptionResult = await _encryptionService.encryptFile(fileBytes);

      // Save the encrypted file locally
      Directory appDir = await getApplicationDocumentsDirectory();
      String encryptedPath = '${appDir.path}/$fileName.enc';
      File encryptedFile = File(encryptedPath);
      await encryptedFile.writeAsBytes(encryptionResult.encryptedData);

      // Convert encrypted key, IV, and HMAC to base64 for storage
      final base64Map = encryptionResult.toBase64Map();

      // Save document metadata to database
      await _documentService.addDocument(
        fileName,
        encryptedPath,
        base64Map['encryptedKey']!,
        base64Map['iv']!,
        hmac: base64Map['hmac'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Document uploaded and secured with hybrid encryption!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Encryption error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        File file = File(result.files.single.path!);
        String originalName = result.files.single.name;
        
        // Show rename dialog
        String? newName = await _showRenameDialog(originalName);
        if (newName != null && mounted) {
          await _encryptAndSaveFile(file, newName);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('File selection error: $e')));
      }
    }
  }

  Future<void> _takePictureAndUpload() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        File file = File(photo.path);
        String defaultName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        // Show rename dialog
        String? newName = await _showRenameDialog(defaultName);
        if (newName != null && mounted) {
          await _encryptAndSaveFile(file, newName);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Camera error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _takePictureAndUpload,
                icon: const Icon(Icons.camera_alt, size: 28),
                label: const Text(
                  'Take a Photo',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  minimumSize: const Size(double.infinity, 60),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickAndUploadFile,
                icon: const Icon(Icons.folder_open, size: 28),
                label: const Text(
                  'Select a File',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  minimumSize: const Size(double.infinity, 60),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
