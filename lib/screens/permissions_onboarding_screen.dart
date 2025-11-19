import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permission_service.dart';

/// Screen for requesting permissions with explanations on first app launch
class PermissionsOnboardingScreen extends StatefulWidget {
  const PermissionsOnboardingScreen({super.key});

  @override
  State<PermissionsOnboardingScreen> createState() =>
      _PermissionsOnboardingScreenState();
}

class _PermissionsOnboardingScreenState
    extends State<PermissionsOnboardingScreen> {
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = false;
  final Map<Permission, PermissionStatus> _permissionStatuses = {};

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    final permissions = _permissionService.getRequiredPermissions();
    for (final permission in permissions) {
      final status = await _permissionService.checkPermissionStatus(permission);
      setState(() {
        _permissionStatuses[permission] = status;
      });
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    setState(() {
      _isLoading = true;
    });

    final status = await _permissionService.requestPermission(permission);

    setState(() {
      _permissionStatuses[permission] = status;
      _isLoading = false;
    });

    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog(permission);
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() {
      _isLoading = true;
    });

    final statuses = await _permissionService.requestRequiredPermissions();

    setState(() {
      _permissionStatuses.addAll(statuses);
      _isLoading = false;
    });

    // Check if any permission is permanently denied
    final permanentlyDenied = statuses.entries
        .where((entry) => entry.value.isPermanentlyDenied)
        .map((entry) => entry.key)
        .toList();

    if (permanentlyDenied.isNotEmpty) {
      _showMultiplePermissionsDeniedDialog(permanentlyDenied);
    } else {
      _completeOnboarding();
    }
  }

  void _showPermissionDeniedDialog(Permission permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: Text(
          'The ${_permissionService.getPermissionDisplayName(permission)} permission has been permanently denied. '
          'You must enable it manually in the app settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _permissionService.openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showMultiplePermissionsDeniedDialog(List<Permission> permissions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Denied'),
        content: Text(
          'Some permissions have been permanently denied. '
          'You can enable them manually in the app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _completeOnboarding();
            },
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _permissionService.openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    await _permissionService.setPermissionsOnboardingCompleted(true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  Future<void> _skipOnboarding() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Permissions?'),
        content: const Text(
          'Some app features will not be available without these permissions. '
          'You can enable them later in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = _permissionService.getRequiredPermissions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Required Permissions'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header icon
                    Icon(
                      Icons.security,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Protect Your Data Securely',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      'SafeKeeper needs certain permissions to function properly. '
                      'We respect your privacy and only use these permissions for the features described below.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Permission cards
                    ...permissions.map((permission) {
                      final status = _permissionStatuses[permission];
                      return _buildPermissionCard(
                        permission: permission,
                        status: status,
                      );
                    }),

                    const SizedBox(height: 16),

                    // Info box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can change these permissions at any time in your device settings.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _requestAllPermissions,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Allow All Permissions',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading ? null : _skipOnboarding,
                    child: const Text('Skip for Now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required Permission permission,
    PermissionStatus? status,
  }) {
    final isGranted = status?.isGranted ?? false;
    final isDenied = status?.isDenied ?? false;
    final isPermanentlyDenied = status?.isPermanentlyDenied ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isGranted
                        ? Colors.green[50]
                        : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _permissionService.getPermissionIcon(permission),
                    color: isGranted
                        ? Colors.green[700]
                        : Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
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
                      if (isGranted)
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Granted',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        )
                      else if (isPermanentlyDenied)
                        Row(
                          children: [
                            Icon(
                              Icons.block,
                              size: 16,
                              color: Colors.red[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Denied',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (!isGranted && !_isLoading)
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => _requestPermission(permission),
                    color: Theme.of(context).primaryColor,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _permissionService.getPermissionDescription(permission),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            if (isPermanentlyDenied) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _permissionService.openSettings(),
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('Open Settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[300]!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
