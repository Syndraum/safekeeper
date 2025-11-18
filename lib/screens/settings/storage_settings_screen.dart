import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings_view_model.dart';

class StorageSettingsScreen extends StatefulWidget {
  const StorageSettingsScreen({super.key});

  @override
  State<StorageSettingsScreen> createState() => _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends State<StorageSettingsScreen> {
  Future<void> _clearCache() async {
    final viewModel = context.read<SettingsViewModel>();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Cache?'),
        content: const Text(
          'This will delete all temporary decrypted files. This is recommended for security.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await viewModel.clearCache();
      if (mounted) {
        if (success && viewModel.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.successMessage!),
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
  }

  Future<void> _clearImageCache() async {
    final viewModel = context.read<SettingsViewModel>();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Image Cache?'),
        content: const Text(
          'This will delete all temporary decrypted image files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await viewModel.clearImageCache();
      if (mounted) {
        if (success && viewModel.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.successMessage!),
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
  }

  Future<void> _clearAudioCache() async {
    final viewModel = context.read<SettingsViewModel>();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Audio Cache?'),
        content: const Text(
          'This will delete all temporary decrypted audio files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await viewModel.clearAudioCache();
      if (mounted) {
        if (success && viewModel.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.successMessage!),
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
  }

  Future<void> _clearPdfCache() async {
    final viewModel = context.read<SettingsViewModel>();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear PDF Cache?'),
        content: const Text(
          'This will delete all temporary decrypted PDF files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await viewModel.clearPdfCache();
      if (mounted) {
        if (success && viewModel.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.successMessage!),
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
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage & Cache'),
      ),
      body: ListView(
        children: [
          // Cache size overview
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: const Icon(
                          Icons.storage,
                          color: Colors.orange,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Cache Size',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              viewModel.cacheSize,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: !viewModel.isBusy ? _clearCache : null,
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Clear All Cache'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(),

          // Clear by type section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Clear by Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Image cache
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Icon(Icons.image, color: Colors.blue),
            ),
            title: const Text('Image Cache'),
            subtitle: const Text('Clear temporary image files'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: !viewModel.isBusy ? _clearImageCache : null,
              color: Colors.red,
            ),
          ),

          // Audio cache
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Icon(Icons.audiotrack, color: Colors.purple),
            ),
            title: const Text('Audio Cache'),
            subtitle: const Text('Clear temporary audio files'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: !viewModel.isBusy ? _clearAudioCache : null,
              color: Colors.red,
            ),
          ),

          // PDF cache
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Icon(Icons.picture_as_pdf, color: Colors.red),
            ),
            title: const Text('PDF Cache'),
            subtitle: const Text('Clear temporary PDF files'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: !viewModel.isBusy ? _clearPdfCache : null,
              color: Colors.red,
            ),
          ),

          const Divider(),

          // Security info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.security, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Security Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Cache contains temporarily decrypted files\n'
                      '• Cache is automatically cleared when you lock the app\n'
                      '• Regular cache clearing is recommended for security\n'
                      '• Clearing cache does not delete your encrypted files',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
