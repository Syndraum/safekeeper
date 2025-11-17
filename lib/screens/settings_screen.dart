import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/settings_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsViewModel>().initialize();
    });
  }

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

  Future<void> _syncAllDocuments() async {
    final viewModel = context.read<SettingsViewModel>();
    final success = await viewModel.syncAllDocuments();
    
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

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Backup Settings'),
      ),
      body: ListView(
        children: [
          // Main backup toggle
          SwitchListTile(
            title: const Text('Enable Cloud Backup'),
            subtitle: const Text('Backup encrypted files to cloud storage'),
            value: viewModel.isBackupEnabled,
            onChanged: (value) => viewModel.toggleBackup(value),
          ),
          const Divider(),

          // Backup options
          ListTile(
            title: const Text('Backup Options'),
            subtitle: const Text('Configure backup behavior'),
            enabled: viewModel.isBackupEnabled,
          ),
          SwitchListTile(
            title: const Text('Auto Backup'),
            subtitle: const Text('Automatically backup after upload'),
            value: viewModel.isAutoBackupEnabled,
            onChanged: viewModel.isBackupEnabled 
                ? (value) => viewModel.toggleAutoBackup(value) 
                : null,
          ),
          SwitchListTile(
            title: const Text('WiFi Only'),
            subtitle: const Text('Only backup when connected to WiFi'),
            value: viewModel.isBackupEnabled,
            onChanged: viewModel.isBackupEnabled 
                ? (value) async {
                    // WiFi only toggle - not implemented in ViewModel yet
                    // Keep this as placeholder
                  }
                : null,
          ),
          const Divider(),

          // Cloud providers
          ListTile(
            title: const Text('Cloud Providers'),
            subtitle: const Text('Select where to backup your files'),
            enabled: viewModel.isBackupEnabled,
          ),

          // Google Drive
          ListTile(
            leading: const Icon(Icons.cloud, color: Colors.blue),
            title: const Text('Google Drive'),
            subtitle: Text(
              viewModel.isGoogleDriveAuthenticated ? 'Connected' : 'Not connected',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (viewModel.isGoogleDriveAuthenticated)
                  Switch(
                    value: viewModel.isGoogleDriveEnabled,
                    onChanged: viewModel.isBackupEnabled 
                        ? (value) {
                            // Toggle is handled by connect/disconnect
                          }
                        : null,
                  )
                else
                  ElevatedButton(
                    onPressed: viewModel.isBackupEnabled ? _connectGoogleDrive : null,
                    child: const Text('Connect'),
                  ),
                if (viewModel.isGoogleDriveAuthenticated)
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: _disconnectGoogleDrive,
                    tooltip: 'Disconnect',
                  ),
              ],
            ),
          ),

          // Dropbox
          ListTile(
            leading: const Icon(Icons.cloud_queue, color: Colors.indigo),
            title: const Text('Dropbox'),
            subtitle: Text(
              viewModel.isDropboxAuthenticated ? 'Connected' : 'Not connected',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (viewModel.isDropboxAuthenticated)
                  Switch(
                    value: viewModel.isDropboxEnabled,
                    onChanged: viewModel.isBackupEnabled 
                        ? (value) {
                            // Toggle is handled by connect/disconnect
                          }
                        : null,
                  )
                else
                  ElevatedButton(
                    onPressed: viewModel.isBackupEnabled ? _connectDropbox : null,
                    child: const Text('Connect'),
                  ),
                if (viewModel.isDropboxAuthenticated)
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: _disconnectDropbox,
                    tooltip: 'Disconnect',
                  ),
              ],
            ),
          ),
          const Divider(),

          // Sync button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: viewModel.isBackupEnabled && !viewModel.isBusy
                  ? _syncAllDocuments
                  : null,
              icon: viewModel.isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(viewModel.isBusy ? 'Syncing...' : 'Sync All Documents'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),

          // Info card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'About Cloud Backup',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Your files are encrypted before upload\n'
                      '• Only encrypted data is stored in the cloud\n'
                      '• You can backup to multiple providers\n'
                      '• Backups happen automatically after upload\n'
                      '• You can manually sync at any time',
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
