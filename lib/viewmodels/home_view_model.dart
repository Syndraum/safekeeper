import '../core/base_view_model.dart';
import '../services/auth_service.dart';

class HomeViewModel extends BaseViewModel {
  final AuthService _authService;

  HomeViewModel({required AuthService authService})
      : _authService = authService;

  /// Logout user
  void logout() {
    _authService.logout();
    notifyListeners();
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _authService.isAuthenticated;
}
