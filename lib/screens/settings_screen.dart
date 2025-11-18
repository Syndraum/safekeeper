import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/settings_view_model.dart';
import 'settings/storage_settings_screen.dart';
import 'settings/security_settings_screen.dart';
import 'settings/permissions_settings_screen.dart';
import 'settings/about_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configure your SafeKeeper',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage backup, storage, and app settings',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Backup & Sync Settings - Coming Soon
          _buildSettingsTile(
            context: context,
            icon: Icons.cloud_sync,
            iconColor: Colors.grey,
            title: 'Backup & Sync',
            subtitle: 'Coming soon',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cloud backup feature coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          // Cloud Providers - Coming Soon
          _buildSettingsTile(
            context: context,
            icon: Icons.cloud,
            iconColor: Colors.grey,
            title: 'Cloud Providers',
            subtitle: 'Coming soon',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cloud providers feature coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          // Storage & Cache
          _buildSettingsTile(
            context: context,
            icon: Icons.storage,
            iconColor: Colors.orange,
            title: 'Storage & Cache',
            subtitle: 'Cache size: ${viewModel.cacheSize}',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StorageSettingsScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // Security
          _buildSettingsTile(
            context: context,
            icon: Icons.security,
            iconColor: Colors.green,
            title: 'Security',
            subtitle: 'Manage master password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SecuritySettingsScreen(),
                ),
              );
            },
          ),

          // Permissions
          _buildSettingsTile(
            context: context,
            icon: Icons.admin_panel_settings,
            iconColor: Colors.purple,
            title: 'Permissions',
            subtitle: 'Manage app permissions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PermissionsSettingsScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // About
          _buildSettingsTile(
            context: context,
            icon: Icons.info,
            iconColor: Colors.green,
            title: 'About',
            subtitle: 'App information and security details',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Quick info card
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
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Coming Soon',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStatusItem(
                      icon: Icons.cloud_upload,
                      text: 'Cloud backup to Google Drive & Dropbox',
                      color: Colors.blue,
                    ),
                    _buildStatusItem(
                      icon: Icons.sync,
                      text: 'Automatic synchronization',
                      color: Colors.blue,
                    ),
                    _buildStatusItem(
                      icon: Icons.security,
                      text: 'End-to-end encrypted backups',
                      color: Colors.blue,
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

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color == Colors.grey 
                    ? Colors.grey[700] 
                    : color == Colors.green 
                        ? Colors.green[900]
                        : color == Colors.orange
                            ? Colors.orange[900]
                            : color,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
