import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/permission_service.dart';

/// Screen for managing app permissions
class PermissionsSettingsScreen extends StatefulWidget {
  const PermissionsSettingsScreen({super.key});

  @override
  State<PermissionsSettingsScreen> createState() =>
      _PermissionsSettingsScreenState();
}

class _PermissionsSettingsScreenState extends State<PermissionsSettingsScreen> {
  final PermissionService _permissionService = PermissionService();
  final Map<Permission, PermissionStatus> _permissionStatuses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatuses();
  }

  Future<void> _loadPermissionStatuses() async {
    setState(() {
      _isLoading = true;
    });

    final allPermissions = [
      ..._permissionService.getRequiredPermissions(),
      ..._permissionService.getOptionalPermissions(),
    ];

    for (final permission in allPermissions) {
      final status = await _permissionService.checkPermissionStatus(permission);
      _permissionStatuses[permission] = status;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await _permissionService.requestPermission(permission);

    setState(() {
      _permissionStatuses[permission] = status;
    });

    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog(permission);
    } else if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Permission ${_permissionService.getPermissionDisplayName(permission)} accordée',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showPermissionDeniedDialog(Permission permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission refusée'),
        content: Text(
          'La permission ${_permissionService.getPermissionDisplayName(permission)} a été refusée de manière permanente. '
          'Vous devez l\'activer manuellement dans les paramètres de l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _permissionService.openSettings();
            },
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );
  }

  void _showPermissionInfoDialog(Permission permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_permissionService.getPermissionDisplayName(permission)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _permissionService.getPermissionDescription(permission),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'État actuel: ${_getPermissionStatusText(_permissionStatuses[permission])}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _getPermissionStatusColor(_permissionStatuses[permission]),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _getPermissionStatusText(PermissionStatus? status) {
    if (status == null) return 'Inconnu';
    if (status.isGranted) return 'Accordée';
    if (status.isDenied) return 'Refusée';
    if (status.isPermanentlyDenied) return 'Refusée définitivement';
    if (status.isRestricted) return 'Restreinte';
    if (status.isLimited) return 'Limitée';
    return 'Inconnu';
  }

  Color _getPermissionStatusColor(PermissionStatus? status) {
    if (status == null) return Colors.grey;
    if (status.isGranted) return Colors.green;
    if (status.isPermanentlyDenied) return Colors.red;
    return Colors.orange;
  }

  IconData _getPermissionStatusIcon(PermissionStatus? status) {
    if (status == null) return Icons.help_outline;
    if (status.isGranted) return Icons.check_circle;
    if (status.isPermanentlyDenied) return Icons.block;
    return Icons.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autorisations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPermissionStatuses,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPermissionStatuses,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Header
                  Text(
                    'Gérer les autorisations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contrôlez les autorisations accordées à SafeKeeper. '
                    'Certaines fonctionnalités peuvent ne pas fonctionner sans les autorisations nécessaires.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Required Permissions Section
                  _buildSectionHeader('Autorisations requises'),
                  const SizedBox(height: 8),
                  ..._permissionService
                      .getRequiredPermissions()
                      .map((permission) => _buildPermissionCard(permission)),

                  const SizedBox(height: 24),

                  // Optional Permissions Section
                  _buildSectionHeader('Autorisations optionnelles'),
                  const SizedBox(height: 8),
                  ..._permissionService
                      .getOptionalPermissions()
                      .map((permission) => _buildPermissionCard(permission)),

                  const SizedBox(height: 24),

                  // Info Card
                  Card(
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
                                'À propos des autorisations',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Les autorisations refusées définitivement doivent être activées manuellement dans les paramètres système\n'
                            '• Vous pouvez révoquer les autorisations à tout moment\n'
                            '• SafeKeeper respecte votre vie privée et n\'utilise les autorisations que pour les fonctionnalités décrites',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[900],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Open System Settings Button
                  OutlinedButton.icon(
                    onPressed: () => _permissionService.openSettings(),
                    icon: const Icon(Icons.settings),
                    label: const Text('Ouvrir les paramètres système'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPermissionCard(Permission permission) {
    final status = _permissionStatuses[permission];
    final isGranted = status?.isGranted ?? false;
    final isPermanentlyDenied = status?.isPermanentlyDenied ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isGranted
              ? Colors.green[300]!
              : isPermanentlyDenied
                  ? Colors.red[300]!
                  : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showPermissionInfoDialog(permission),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isGranted
                      ? Colors.green[50]
                      : isPermanentlyDenied
                          ? Colors.red[50]
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _permissionService.getPermissionIcon(permission),
                  color: isGranted
                      ? Colors.green[700]
                      : isPermanentlyDenied
                          ? Colors.red[700]
                          : Colors.grey[700],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Title and Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _permissionService.getPermissionDisplayName(permission),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getPermissionStatusIcon(status),
                          size: 14,
                          color: _getPermissionStatusColor(status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getPermissionStatusText(status),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getPermissionStatusColor(status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Button
              if (!isGranted)
                IconButton(
                  icon: Icon(
                    isPermanentlyDenied ? Icons.settings : Icons.check_circle_outline,
                    color: isPermanentlyDenied ? Colors.red[700] : Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    if (isPermanentlyDenied) {
                      _permissionService.openSettings();
                    } else {
                      _requestPermission(permission);
                    }
                  },
                  tooltip: isPermanentlyDenied ? 'Ouvrir les paramètres' : 'Demander',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
