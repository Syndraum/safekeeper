import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings_view_model.dart';

class CloudProvidersScreen extends StatefulWidget {
  const CloudProvidersScreen({super.key});

  @override
  State<CloudProvidersScreen> createState() => _CloudProvidersScreenState();
}

class _CloudProvidersScreenState extends State<CloudProvidersScreen> {
  Future<void> _connectGoogleDrive() async {
    final viewModel = context.read<SettingsViewModel>();
    final success = await viewModel.connectGoogleDrive();
    
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

  Future<void> _connectDropbox() async {
    final viewModel = context.read<SettingsViewModel>();
    final success = await viewModel.connectDropbox();
    
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

  Future<void> _disconnectGoogleDrive() async {
    final viewModel = context.read<SettingsViewModel>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Google Drive?'),
        content: const Text(
          'This will remove your Google Drive connection. Your files will remain in Google Drive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await viewModel.disconnectGoogleDrive();
      if (mounted && success && viewModel.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.successMessage!),
          ),
        );
      }
    }
  }

  Future<void> _disconnectDropbox() async {
    final viewModel = context.read<SettingsViewModel>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Dropbox?'),
        content: const Text(
          'This will remove your Dropbox connection. Your files will remain in Dropbox.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await viewModel.disconnectDropbox();
      if (mounted && success && viewModel.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.successMessage!),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Providers'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Connect your cloud storage accounts to backup your encrypted files.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          
          const Divider(),

          // Google Drive
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(Icons.cloud, color: Colors.blue, size: 32),
                  ),
                  title: const Text(
                    'Google Drive',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    viewModel.isGoogleDriveAuthenticated 
                        ? 'Connected and active' 
                        : 'Not connected',
                    style: TextStyle(
                      color: viewModel.isGoogleDriveAuthenticated 
                          ? Colors.green 
                          : Colors.grey,
                    ),
                  ),
                ),
                if (viewModel.isGoogleDriveAuthenticated)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _disconnectGoogleDrive,
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text('Disconnect'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: viewModel.isBackupEnabled ? _connectGoogleDrive : null,
                            icon: const Icon(Icons.link, size: 18),
                            label: const Text('Connect'),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Dropbox
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(Icons.cloud_queue, color: Colors.indigo, size: 32),
                  ),
                  title: const Text(
                    'Dropbox',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    viewModel.isDropboxAuthenticated 
                        ? 'Connected and active' 
                        : 'Not connected',
                    style: TextStyle(
                      color: viewModel.isDropboxAuthenticated 
                          ? Colors.green 
                          : Colors.grey,
                    ),
                  ),
                ),
                if (viewModel.isDropboxAuthenticated)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _disconnectDropbox,
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text('Disconnect'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: viewModel.isBackupEnabled ? _connectDropbox : null,
                            icon: const Icon(Icons.link, size: 18),
                            label: const Text('Connect'),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Info card
          if (!viewModel.isBackupEnabled)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Enable cloud backup in Backup Settings to connect providers',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Security info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.security, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Security',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• All files are encrypted before upload\n'
                      '• Cloud providers only store encrypted data\n'
                      '• Your encryption key never leaves your device\n'
                      '• You can use multiple providers simultaneously',
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
