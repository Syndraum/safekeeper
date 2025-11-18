import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/upload_view_model.dart';
import '../widgets/vocal_memo_recorder.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {

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

  Future<void> _pickAndUploadFile() async {
    final viewModel = context.read<UploadViewModel>();
    
    // First, let user pick the file - this will show the file picker
    // We pass a temporary name, but will rename after selection
    final result = await viewModel.pickAndUploadFile('temp_document');
    
    if (result == null) {
      // User cancelled or error occurred
      if (mounted && viewModel.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.error!.message),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // File was selected, now show rename dialog
    String? newName = await _showRenameDialog(result.fileName);
    if (newName == null || newName == result.fileName) {
      // User cancelled rename or kept same name, show success with original name
      if (mounted) {
        String message = 'Document uploaded and secured with hybrid encryption!\n'
            'Detected type: ${result.fileType}';
        
        if (result.backupStarted) {
          message += '\nBackup started...';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
      return;
    }
    
    // Rename the document
    final renameSuccess = await viewModel.renameDocument(result.documentId, newName);
    
    if (mounted) {
      if (renameSuccess) {
        String message = 'Document uploaded and renamed to "$newName"!\n'
            'Detected type: ${result.fileType}';
        
        if (result.backupStarted) {
          message += '\nBackup started...';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.error?.message ?? 'Failed to rename document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePictureAndUpload() async {
    final viewModel = context.read<UploadViewModel>();
    
    // Generate default name for the photo
    String defaultName = viewModel.generatePhotoName();
    
    // Take picture first
    final result = await viewModel.takePictureAndUpload(defaultName);
    
    if (result == null) {
      // User cancelled or error occurred
      if (mounted && viewModel.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.error!.message),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Photo was taken, now show rename dialog
    String? newName = await _showRenameDialog(result.fileName);
    if (newName == null || newName == result.fileName) {
      // User cancelled rename or kept same name
      if (mounted) {
        String message = 'Photo uploaded and secured!\n'
            'Detected type: ${result.fileType}';
        
        if (result.backupStarted) {
          message += '\nBackup started...';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
      return;
    }
    
    // Rename the document
    final renameSuccess = await viewModel.renameDocument(result.documentId, newName);
    
    if (mounted) {
      if (renameSuccess) {
        String message = 'Photo uploaded and renamed to "$newName"!\n'
            'Detected type: ${result.fileType}';
        
        if (result.backupStarted) {
          message += '\nBackup started...';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.error?.message ?? 'Failed to rename document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showVocalMemoRecorder() async {
    final viewModel = context.read<UploadViewModel>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VocalMemoRecorder(
        onRecordingComplete: (filePath) async {
          Navigator.of(context).pop();
          
          // Generate default name
          String defaultName = viewModel.generateVocalMemoName();
          
          // Show rename dialog
          String? fileName = await _showRenameDialog(defaultName);
          if (fileName != null && mounted) {
            final result = await viewModel.uploadVocalMemo(filePath, fileName);
            
            if (mounted) {
              if (result != null) {
                String message = 'Vocal memo uploaded and secured!\n'
                    'Detected type: ${result.fileType}';
                
                if (result.backupStarted) {
                  message += '\nBackup started...';
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (viewModel.hasError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(viewModel.error!.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
        onError: (error) {
          Navigator.of(context).pop();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Document'),
        automaticallyImplyLeading: false,
      ),
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
                onPressed: _showVocalMemoRecorder,
                icon: const Icon(Icons.mic, size: 28),
                label: const Text(
                  'Record Vocal Memo',
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
