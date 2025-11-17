import '../core/base_view_model.dart';
import '../services/auth_service.dart';

class AuthViewModel extends BaseViewModel {
  final AuthService _authService;

  bool _isPasswordSet = false;
  bool _isAuthenticated = false;

  AuthViewModel({required AuthService authService})
      : _authService = authService;

  // Getters
  bool get isPasswordSet => _isPasswordSet;
  bool get isAuthenticated => _isAuthenticated;

  /// Initialize and check if password is set
  Future<void> initialize() async {
    await runBusyFuture(
      () async {
        _isPasswordSet = await _authService.isPasswordSet();
      },
      errorMessage: 'Failed to check password status',
    );
  }

  /// Set up a new password
  Future<bool> setupPassword(String password) async {
    if (password.isEmpty) {
      setError('Password cannot be empty');
      return false;
    }

    if (password.length < 6) {
      setError('Password must be at least 6 characters long');
      return false;
    }

    final result = await runBusyFutureWithSuccess(
      () async {
        await _authService.setPassword(password);
        _isPasswordSet = true;
        _isAuthenticated = true;
      },
      successMessage: 'Password set successfully',
      errorMessage: 'Failed to set password',
    );

    return result != null;
  }

  /// Verify password and authenticate
  Future<bool> verifyPassword(String password) async {
    if (password.isEmpty) {
      setError('Please enter your password');
      return false;
    }

    final result = await runBusyFuture(
      () async {
        final isValid = await _authService.verifyPassword(password);
        if (isValid) {
          _isAuthenticated = true;
          setSuccess('Authentication successful');
          return true;
        } else {
          setError('Incorrect password');
          return false;
        }
      },
      errorMessage: 'Failed to verify password',
    );

    return result ?? false;
  }

  /// Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      setError('Both passwords are required');
      return false;
    }

    if (newPassword.length < 6) {
      setError('New password must be at least 6 characters long');
      return false;
    }

    // First verify current password
    final isCurrentValid = await _authService.verifyPassword(currentPassword);
    if (!isCurrentValid) {
      setError('Current password is incorrect');
      return false;
    }

    // Set new password
    final result = await runBusyFutureWithSuccess(
      () async {
        await _authService.setPassword(newPassword);
      },
      successMessage: 'Password changed successfully',
      errorMessage: 'Failed to change password',
    );

    return result != null;
  }

  /// Logout user
  void logout() {
    _authService.logout();
    _isAuthenticated = false;
    setIdle();
  }

  /// Check if user is authenticated
  bool checkAuthentication() {
    return _authService.isAuthenticated;
  }
}
