import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_view_model.dart';
import 'change_password_screen.dart';

/// Screen for managing security settings including master password
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().initialize();
    });
  }

  Future<void> _navigateToChangePassword() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );

    // If password was changed successfully, show confirmation
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Master password updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
      ),
      body: ListView(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Icon(
                        Icons.security,
                        color: Colors.green[700],
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security Settings',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage your master password',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(),

          // Master Password Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Master Password',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Change password button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Icon(
                    Icons.lock_reset,
                    color: Colors.orange[700],
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Change Master Password',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: const Text(
                  'Update your master password',
                  style: TextStyle(fontSize: 13),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: viewModel.isBusy ? null : _navigateToChangePassword,
              ),
            ),
          ),

          const Divider(),

          // Security information
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
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'About Master Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      icon: Icons.lock,
                      text: 'Your master password protects all your encrypted documents',
                      color: Colors.blue,
                    ),
                    _buildInfoItem(
                      icon: Icons.key,
                      text: 'It is used to derive encryption keys for your files',
                      color: Colors.blue,
                    ),
                    _buildInfoItem(
                      icon: Icons.warning_amber,
                      text: 'If you forget it, your data cannot be recovered',
                      color: Colors.orange,
                    ),
                    _buildInfoItem(
                      icon: Icons.security,
                      text: 'Choose a strong, memorable password',
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Security best practices
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
                      children: [
                        Icon(
                          Icons.verified_user,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Security Best Practices',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      icon: Icons.check_circle_outline,
                      text: 'Use at least 8 characters',
                      color: Colors.green,
                    ),
                    _buildInfoItem(
                      icon: Icons.check_circle_outline,
                      text: 'Mix uppercase, lowercase, numbers and symbols',
                      color: Colors.green,
                    ),
                    _buildInfoItem(
                      icon: Icons.check_circle_outline,
                      text: 'Avoid common words or personal information',
                      color: Colors.green,
                    ),
                    _buildInfoItem(
                      icon: Icons.check_circle_outline,
                      text: 'Change your password periodically',
                      color: Colors.green,
                    ),
                    _buildInfoItem(
                      icon: Icons.check_circle_outline,
                      text: 'Never share your password with anyone',
                      color: Colors.green,
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

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    // Determine the appropriate color shades based on the base color
    Color iconColor;
    Color textColor;
    
    if (color == Colors.orange) {
      iconColor = Colors.orange[700]!;
      textColor = Colors.orange[900]!;
    } else if (color == Colors.green) {
      iconColor = Colors.green[700]!;
      textColor = Colors.green[900]!;
    } else {
      iconColor = Colors.blue[700]!;
      textColor = Colors.blue[900]!;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
