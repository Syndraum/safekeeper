import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/cloud_providers/google_drive_provider.dart';
import '../services/cloud_providers/dropbox_provider.dart';
import '../services/cloud_backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService();
  final _googleDriveProvider = GoogleDriveProvider();
  final _dropboxProvider = DropboxProvider();
  final _backupService = CloudBackupService();

  bool _backupEnabled = false;
  bool _autoBackupEnabled = true;
  bool _wifiOnlyEnabled = true;
  bool _googleDriveEnabled = false;
  bool _dropboxEnabled = false;
  bool _googleDriveAuthenticated = false;
  bool _dropboxAuthenticated = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _backupEnabled = _settingsService.isBackupEnabled();
      _autoBackupEnabled = _settingsService.isAutoBackupEnabled();
      _wifiOnlyEnabled = _settingsService.isWifiOnlyEnabled();
      _googleDriveEnabled = _settingsService.isGoogleDriveEnabled();
      _dropboxEnabled = _settingsService.isDropboxEnabled();
      _googleDriveAuthenticated = _settingsService.isGoogleDriveAuthenticated();
      _dropboxAuthenticated = _settingsService.isDropboxAuthenticated();
    });
  }

  Future<void> _toggleBackup(bool value) async {
    await _settingsService.setBackupEnabled(value);
    setState(() {
      _backupEnabled = value;
    });
  }

  Future<void> _toggleAutoBackup(bool value) async {
    await _settingsService.setAutoBackupEnabled(value);
    setState(() {
      _autoBackupEnabled = value;
    });
  }

  Future<void> _toggleWifiOnly(bool value) async {
    await _settingsService.setWifiOnlyEnabled(value);
    setState(() {
      _wifiOnlyEnabled = value;
    });
  }

  Future<void> _toggleGoogleDrive(bool value) async {
    if (value && !_googleDriveAuthenticated) {
      // Need to authenticate first
      await _authenticateGoogleDrive();
    } else {
      await _settingsService.setGoogleDriveEnabled(value);
      setState(() {
        _googleDriveEnabled = value;
      });
    }
  }

  Future<void> _toggleDropbox(bool value) async {
    if (value && !_dropboxAuthenticated) {
      // Need to authenticate first
      await _authenticateDropbox();
    } else {
      await _settingsService.setDropboxEnabled(value);
      setState(() {
        _dropboxEnabled = value;
      });
    }
  }

  Future<void> _authenticateGoogleDrive() async {
    try {
      final success = await _googleDriveProvider.authenticate();
      if (success) {
        await _settingsService.setGoogleDriveEnabled(true);
        setState(() {
          _googleDriveAuthenticated = true;
          _googleDriveEnabled = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Drive connected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to connect to Google Drive'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _authenticateDropbox() async {
    try {
      final success = await _dropboxProvider.authenticate();
      if (success) {
        await _settingsService.setDropboxEnabled(true);
        setState(() {
          _dropboxAuthenticated = true;
          _dropboxEnabled = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dropbox connected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to connect to Dropbox'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnectGoogleDrive() async {
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
      await _googleDriveProvider.signOut();
      setState(() {
        _googleDriveAuthenticated = false;
        _googleDriveEnabled = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Drive disconnected'),
          ),
        );
      }
    }
  }

  Future<void> _disconnectDropbox() async {
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
      await _dropboxProvider.signOut();
      setState(() {
        _dropboxAuthenticated = false;
        _dropboxEnabled = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dropbox disconnected'),
          ),
        );
      }
    }
  }

  Future<void> _syncAllDocuments() async {
    if (!_backupEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable cloud backup first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_googleDriveEnabled && !_dropboxEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable at least one cloud provider'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      await _backupService.syncAllDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            value: _backupEnabled,
            onChanged: _toggleBackup,
          ),
          const Divider(),

          // Backup options
          ListTile(
            title: const Text('Backup Options'),
            subtitle: const Text('Configure backup behavior'),
            enabled: _backupEnabled,
          ),
          SwitchListTile(
            title: const Text('Auto Backup'),
            subtitle: const Text('Automatically backup after upload'),
            value: _autoBackupEnabled,
            onChanged: _backupEnabled ? _toggleAutoBackup : null,
          ),
          SwitchListTile(
            title: const Text('WiFi Only'),
            subtitle: const Text('Only backup when connected to WiFi'),
            value: _wifiOnlyEnabled,
            onChanged: _backupEnabled ? _toggleWifiOnly : null,
          ),
          const Divider(),

          // Cloud providers
          ListTile(
            title: const Text('Cloud Providers'),
            subtitle: const Text('Select where to backup your files'),
            enabled: _backupEnabled,
          ),

          // Google Drive
          ListTile(
            leading: const Icon(Icons.cloud, color: Colors.blue),
            title: const Text('Google Drive'),
            subtitle: Text(
              _googleDriveAuthenticated ? 'Connected' : 'Not connected',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_googleDriveAuthenticated)
                  Switch(
                    value: _googleDriveEnabled,
                    onChanged: _backupEnabled ? _toggleGoogleDrive : null,
                  )
                else
                  ElevatedButton(
                    onPressed: _backupEnabled ? _authenticateGoogleDrive : null,
                    child: const Text('Connect'),
                  ),
                if (_googleDriveAuthenticated)
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
              _dropboxAuthenticated ? 'Connected' : 'Not connected',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_dropboxAuthenticated)
                  Switch(
                    value: _dropboxEnabled,
                    onChanged: _backupEnabled ? _toggleDropbox : null,
                  )
                else
                  ElevatedButton(
                    onPressed: _backupEnabled ? _authenticateDropbox : null,
                    child: const Text('Connect'),
                  ),
                if (_dropboxAuthenticated)
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
              onPressed: _backupEnabled && !_isSyncing
                  ? _syncAllDocuments
                  : null,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(_isSyncing ? 'Syncing...' : 'Sync All Documents'),
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
