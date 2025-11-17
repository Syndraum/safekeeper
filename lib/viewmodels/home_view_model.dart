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

  /// Check if user is authenticated
  bool get isAuthenticated => _authService.isAuthenticated;
}
