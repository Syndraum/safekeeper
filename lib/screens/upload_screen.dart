import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../viewmodels/upload_view_model.dart';
import '../viewmodels/document_list_view_model.dart';
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
            backgroundColor: AppTheme.error,
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
            backgroundColor: AppTheme.success,
          ),
        );
        
        // Refresh document list after successful upload
        _refreshDocumentList();
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
            backgroundColor: AppTheme.success,
          ),
        );
        
        // Refresh document list after successful upload
        _refreshDocumentList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.error?.message ?? 'Failed to rename document'),
            backgroundColor: AppTheme.error,
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
            backgroundColor: AppTheme.error,
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
            backgroundColor: AppTheme.success,
          ),
        );
        
        // Refresh document list after successful upload
        _refreshDocumentList();
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
            backgroundColor: AppTheme.success,
          ),
        );
        
        // Refresh document list after successful upload
        _refreshDocumentList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.error?.message ?? 'Failed to rename document'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showVocalMemoRecorder() async {
    final viewModel = context.read<UploadViewModel>();
    // Store the upload screen's context before showing dialog
    final uploadScreenContext = context;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => VocalMemoRecorder(
        onRecordingComplete: (filePath) async {
          // Close the dialog first
          Navigator.of(dialogContext).pop();
          
          // Generate default name
          String defaultName = viewModel.generateVocalMemoName();
          
          // Show rename dialog using the upload screen's context
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
                
                ScaffoldMessenger.of(uploadScreenContext).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: AppTheme.success,
                  ),
                );
                
                // Refresh document list after successful upload
                _refreshDocumentList();
              } else if (viewModel.hasError) {
                ScaffoldMessenger.of(uploadScreenContext).showSnackBar(
                  SnackBar(
                    content: Text(viewModel.error!.message),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            }
          }
        },
        onError: (error) {
          Navigator.of(dialogContext).pop();
          if (mounted) {
            ScaffoldMessenger.of(uploadScreenContext).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        },
      ),
    );
  }

  /// Refresh the document list view model
  void _refreshDocumentList() {
    try {
      // Use post frame callback to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            context.read<DocumentListViewModel>().loadDocuments();
          } catch (e) {
            // Silently fail if DocumentListViewModel is not available
            print('Could not refresh document list: $e');
          }
        }
      });
    } catch (e) {
      print('Could not schedule document list refresh: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Document'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section
              Text(
                'Upload Your Documents',
                style: AppTheme.heading3,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Choose how you want to add your secure documents',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.neutral600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing48),
              
              // Upload options
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildUploadButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Take a Photo',
                      description: 'Capture documents with your camera',
                      onPressed: _takePictureAndUpload,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildUploadButton(
                      icon: Icons.mic_rounded,
                      label: 'Record Vocal Memo',
                      description: 'Record audio notes securely',
                      onPressed: _showVocalMemoRecorder,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildUploadButton(
                      icon: Icons.folder_open_rounded,
                      label: 'Select a File',
                      description: 'Choose from your device storage',
                      onPressed: _pickAndUploadFile,
                    ),
                  ],
                ),
              ),
              
              // Info footer
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: AppTheme.borderRadiusMedium,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 20,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Text(
                        'All files are encrypted before storage',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.neutral700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppTheme.borderRadiusMedium,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: AppTheme.iconContainerDecoration(AppTheme.primary),
                  child: Icon(
                    icon,
                    size: 32,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTheme.heading6,
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        description,
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.neutral400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
