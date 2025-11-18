import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_view_model.dart';

/// Screen for changing the master password
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final viewModel = context.read<AuthViewModel>();
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;

    final success = await viewModel.changePassword(currentPassword, newPassword);

    if (mounted) {
      if (success || viewModel.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.successMessage ?? 'Password changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Return to previous screen
        Navigator.of(context).pop(true);
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
    final viewModel = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Master Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Security icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_reset,
                    size: 60,
                    color: Colors.orange[700],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Description
              Text(
                'Enter your current password and choose a new one',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Current password field
              TextFormField(
                controller: _currentPasswordController,
                obscureText: !_isCurrentPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  hintText: 'Enter your current password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isCurrentPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // New password field
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_isNewPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Minimum 6 characters',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  if (value == _currentPasswordController.text) {
                    return 'New password must be different from current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm password field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  hintText: 'Re-enter your new password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Security tips
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Security Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildSecurityTip('Use at least 8 characters'),
                    _buildSecurityTip('Mix letters, numbers and symbols'),
                    _buildSecurityTip('Make it different from your current password'),
                    _buildSecurityTip('Remember it well - it cannot be recovered'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Change password button
              ElevatedButton(
                onPressed: viewModel.isBusy ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: viewModel.isBusy
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
                        'Change Password',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),

              // Cancel button
              TextButton(
                onPressed: viewModel.isBusy
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.blue[900]),
            ),
          ),
        ],
      ),
    );
  }
}
