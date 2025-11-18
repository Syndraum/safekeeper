import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _version = '1.0.0';
  static const String _buildNumber = '1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        children: [
          // App logo and name
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Icon(
                    Icons.security,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SafeKeeper',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version $_version (Build $_buildNumber)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // App description
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
                          'About SafeKeeper',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'SafeKeeper is a secure document storage application that encrypts your files and safely backs them up to cloud storage. Your privacy and security are our top priorities.',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Security features
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
                          'Security Features',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      icon: Icons.lock,
                      title: 'End-to-End Encryption',
                      description: 'All files are encrypted on your device before upload',
                    ),
                    _buildFeatureItem(
                      icon: Icons.key,
                      title: 'Local Key Storage',
                      description: 'Your encryption key never leaves your device',
                    ),
                    _buildFeatureItem(
                      icon: Icons.cloud_off,
                      title: 'Zero-Knowledge Architecture',
                      description: 'Cloud providers cannot access your data',
                    ),
                    _buildFeatureItem(
                      icon: Icons.delete_sweep,
                      title: 'Auto Cache Clearing',
                      description: 'Temporary files are cleared when you lock the app',
                    ),
                    _buildFeatureItem(
                      icon: Icons.emergency,
                      title: 'Panic Mode',
                      description: 'Quick lock feature for emergency situations',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Privacy
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
                        Icon(Icons.privacy_tip, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Privacy Commitment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• We do not collect any personal information\n'
                      '• We cannot access your encrypted files\n'
                      '• We do not track your usage\n'
                      '• Your data belongs to you',
                      style: TextStyle(fontSize: 14, height: 1.8),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Open source
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.code, color: Colors.purple),
                title: const Text('Open Source'),
                subtitle: const Text('View source code and contribute'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Open GitHub repository
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('GitHub repository link coming soon'),
                    ),
                  );
                },
              ),
            ),
          ),

          // Licenses
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.article, color: Colors.orange),
                title: const Text('Open Source Licenses'),
                subtitle: const Text('View third-party licenses'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'SafeKeeper',
                    applicationVersion: '$_version (Build $_buildNumber)',
                    applicationIcon: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Icon(
                        Icons.security,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Copyright
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '© ${DateTime.now().year} SafeKeeper\nAll rights reserved',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.green[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
