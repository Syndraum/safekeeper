import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../viewmodels/document_list_view_model.dart';
import '../services/file_type_detector.dart';
import 'viewers/pdf_viewer_screen.dart';
import 'viewers/image_viewer_screen.dart';
import 'viewers/generic_file_viewer_screen.dart';
import 'viewers/audio_viewer_screen.dart';
import 'viewers/video_viewer_screen.dart';

class DocumentListScreen extends StatefulWidget {
  final VoidCallback? onVisibilityChanged;
  
  const DocumentListScreen({
    super.key,
    this.onVisibilityChanged,
  });

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  bool _isVisible = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addObserver(this);
    // Initialize ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentListViewModel>().initialize();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload documents when app comes to foreground
    if (state == AppLifecycleState.resumed && _isVisible) {
      _refreshDocuments();
    }
  }

  /// Public method to refresh documents (can be called from parent)
  void refreshDocuments() {
    _refreshDocuments();
  }

  /// Internal method to refresh documents
  void _refreshDocuments() {
    if (mounted) {
      // Use post frame callback to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<DocumentListViewModel>().loadDocuments();
        }
      });
    }
  }

  /// Called when this screen becomes visible
  void setVisible(bool visible) {
    if (_isVisible != visible) {
      _isVisible = visible;
      if (visible && mounted) {
        // Refresh documents when screen becomes visible
        _refreshDocuments();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<DocumentListViewModel>().updateSearchQuery(_searchController.text);
  }

  Future<void> _showRenameDialog(int id, String currentName) async {
    final TextEditingController controller = TextEditingController(text: currentName);
    final viewModel = context.read<DocumentListViewModel>();
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Document Name',
            hintText: 'Enter new name',
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
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName != currentName) {
      final success = await viewModel.renameDocument(id, newName);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.successMessage ?? 'Document renamed successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else if (mounted && viewModel.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.error!.message),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteDocument(int id) async {
    final viewModel = context.read<DocumentListViewModel>();
    final success = await viewModel.deleteDocument(id);
    
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.successMessage ?? 'Document deleted successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else if (mounted && viewModel.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.error!.message),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _openDocument(
    int documentId,
    String encryptedPath,
    String name,
  ) async {
    final viewModel = context.read<DocumentListViewModel>();
    final result = await viewModel.openDocument(documentId, encryptedPath, name);
    
    if (result == null) {
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

    // Navigate to appropriate viewer based on file type
    if (mounted) {
      switch (result.fileType) {
        case FileTypeCategory.pdf:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerScreen(
                filePath: result.tempPath,
                fileName: result.fileName,
                mimeType: result.mimeType,
              ),
            ),
          );
          break;
        case FileTypeCategory.image:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageViewerScreen(
                filePath: result.tempPath,
                fileName: result.fileName,
                mimeType: result.mimeType,
              ),
            ),
          );
          break;
        case FileTypeCategory.audio:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AudioViewerScreen(
                encryptedPath: result.encryptedPath,
                encryptedKey: result.encryptedKey,
                iv: result.iv,
                hmac: result.hmac,
                fileName: result.fileName,
                mimeType: result.mimeType,
              ),
            ),
          );
          break;
        case FileTypeCategory.video:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoViewerScreen(
                encryptedPath: result.encryptedPath,
                encryptedKey: result.encryptedKey,
                iv: result.iv,
                hmac: result.hmac,
                fileName: result.fileName,
                mimeType: result.mimeType,
              ),
            ),
          );
          break;
        default:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GenericFileViewerScreen(
                filePath: result.tempPath,
                fileName: result.fileName,
                fileType: result.fileType,
                mimeType: result.mimeType,
              ),
            ),
          );
      }
    }
  }

  Future<void> _syncAllDocuments() async {
    final viewModel = context.read<DocumentListViewModel>();
    final success = await viewModel.syncAllDocuments();
    
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.successMessage ?? 'All documents synced successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else if (mounted && viewModel.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.error!.message),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Widget _buildBackupStatusIcon(int documentId) {
    final viewModel = context.watch<DocumentListViewModel>();
    final status = viewModel.getBackupStatus(documentId);
    
    if (status == null || !status.isBackedUp) {
      return const SizedBox.shrink();
    }

    if (status.isUploading) {
      return Padding(
        padding: const EdgeInsets.only(left: AppTheme.spacing8),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primary,
          ),
        ),
      );
    }

    if (status.hasFailed) {
      return const Padding(
        padding: EdgeInsets.only(left: AppTheme.spacing8),
        child: Icon(Icons.cloud_off, size: 16, color: AppTheme.warning),
      );
    }

    return const Padding(
      padding: EdgeInsets.only(left: AppTheme.spacing8),
      child: Icon(Icons.cloud_done, size: 16, color: AppTheme.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final viewModel = context.watch<DocumentListViewModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncAllDocuments,
            tooltip: 'Sync all documents',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacing16,
              AppTheme.spacing8,
              AppTheme.spacing16,
              AppTheme.spacing16,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search documents...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: viewModel.isBusy
          ? const Center(child: CircularProgressIndicator())
          : !viewModel.hasDocuments
              ? const Center(child: Text('No documents uploaded yet.'))
              : !viewModel.hasFilteredDocuments
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppTheme.neutral400,
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          Text(
                            'No documents found for "${viewModel.searchQuery}"',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.neutral500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: viewModel.documents.length,
                      itemBuilder: (context, index) {
                        final doc = viewModel.documents[index];
                    final uploadDate = doc['upload_date'] != null
                        ? DateTime.parse(doc['upload_date'])
                        : null;
                    final fileType = doc['file_type'];
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing16,
                        vertical: AppTheme.spacing8,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing16,
                          vertical: AppTheme.spacing8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(AppTheme.spacing8),
                          decoration: AppTheme.iconContainerDecoration(
                            AppTheme.primary,
                          ),
                          child: Icon(
                            _getFileTypeIcon(fileType),
                            size: 24,
                            color: AppTheme.primary,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                doc['name'],
                                style: AppTheme.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _buildBackupStatusIcon(doc['id']),
                          ],
                        ),
                        subtitle: uploadDate != null
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  top: AppTheme.spacing4,
                                ),
                                child: Text(
                                  viewModel.formatDate(uploadDate),
                                  style: AppTheme.caption,
                                ),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                color: AppTheme.neutral600,
                              ),
                              onPressed: () => _showRenameDialog(
                                doc['id'],
                                doc['name'],
                              ),
                              tooltip: 'Rename',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppTheme.error,
                              ),
                              onPressed: () => _showDeleteDialog(doc['id']),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                        onTap: () =>
                            _openDocument(doc['id'], doc['path'], doc['name']),
                      ),
                    );
                    },
                  ),
    );
  }

  IconData _getFileTypeIcon(String? fileType) {
    if (fileType == null) return Icons.insert_drive_file;
    
    switch (fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'text':
        return Icons.text_snippet;
      case 'document':
        return Icons.description;
      case 'archive':
        return Icons.folder_zip;
      case 'video':
        return Icons.video_file;
      case 'audio':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete document?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteDocument(id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
