import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
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
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing24,
              vertical: AppTheme.spacing8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configure your SafeKeeper',
                  style: AppTheme.heading3,
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'Manage backup, storage, and app settings',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.neutral600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacing16),

          // Backup & Sync Settings - Coming Soon
          _buildSettingsTile(
            context: context,
            icon: Icons.cloud_sync_rounded,
            iconColor: AppTheme.neutral400,
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
            icon: Icons.cloud_rounded,
            iconColor: AppTheme.neutral400,
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
            icon: Icons.storage_rounded,
            iconColor: AppTheme.warning,
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

          const SizedBox(height: AppTheme.spacing8),

          // Security
          _buildSettingsTile(
            context: context,
            icon: Icons.security_rounded,
            iconColor: AppTheme.success,
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
            icon: Icons.admin_panel_settings_rounded,
            iconColor: AppTheme.secondary,
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

          const SizedBox(height: AppTheme.spacing8),

          // About
          _buildSettingsTile(
            context: context,
            icon: Icons.info_rounded,
            iconColor: AppTheme.primary,
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

          const SizedBox(height: AppTheme.spacing24),

          // Quick info card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: AppTheme.borderRadiusMedium,
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(
                        'Coming Soon',
                        style: AppTheme.heading6.copyWith(
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  _buildStatusItem(
                    icon: Icons.cloud_upload_rounded,
                    text: 'Cloud backup to Google Drive & Dropbox',
                    color: AppTheme.primary,
                  ),
                  _buildStatusItem(
                    icon: Icons.sync_rounded,
                    text: 'Automatic synchronization',
                    color: AppTheme.primary,
                  ),
                  _buildStatusItem(
                    icon: Icons.security_rounded,
                    text: 'End-to-end encrypted backups',
                    color: AppTheme.primary,
                  ),
                ],
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
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing4,
      ),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppTheme.borderRadiusMedium,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: AppTheme.iconContainerDecoration(iconColor),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.heading6,
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        subtitle,
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

  Widget _buildStatusItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.neutral700,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
