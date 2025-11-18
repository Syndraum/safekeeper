import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings_view_model.dart';

class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
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
        title: const Text('Backup & Sync'),
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

          // Backup options section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Backup Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
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
                    // WiFi only toggle - placeholder for future implementation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('WiFi-only mode coming soon'),
                      ),
                    );
                  }
                : null,
          ),
          
          const Divider(),

          // Sync section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Sync',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Sync button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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

          const SizedBox(height: 16),

          // Info card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.blue[50],
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
