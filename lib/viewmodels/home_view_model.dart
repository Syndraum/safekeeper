import '../core/base_view_model.dart';
import '../services/auth_service.dart';
import '../services/cache_service.dart';

class HomeViewModel extends BaseViewModel {
  final AuthService _authService;
  final CacheService _cacheService = CacheService();

  HomeViewModel({required AuthService authService})
      : _authService = authService;

  /// Logout user and clear cache for security
  Future<void> logout() async {
    // Clear all cached decrypted files before logout
    await _cacheService.clearAllCache();
    _authService.logout();
    notifyListeners();
  }

  /// Activate panic lock mode
  Future<void> activatePanicLock() async {
    // Clear all cached decrypted files for security
    await _cacheService.clearAllCache();
    _authService.activatePanicLock();
    notifyListeners();
  }

  /// Unlock from panic mode with password
  Future<bool> unlockFromPanic(String password) async {
    final success = await _authService.unlockFromPanic(password);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _authService.isAuthenticated;

  /// Check if app is in panic lock mode
  bool get isPanicLocked => _authService.isPanicLocked;
}
