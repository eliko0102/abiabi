import 'package:flutter/foundation.dart';
import '../services/mongo_auth_service.dart';

/// Global Auth State Manager
/// Manages authentication state across the app
class AuthProvider extends ChangeNotifier {
  final MongoAuthService _authService = MongoAuthService();

  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser;
  String? _error;
  bool _isLoading = false;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get error => _error;
  bool get isLoading => _isLoading;
  String? get token => _authService.token;

  // Signup
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    String? businessType,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signUp(
        name: name,
        email: email,
        password: password,
        businessType: businessType,
        phone: phone,
      );

      _currentUser = user;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('AuthException: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.login(
        email: email,
        password: password,
      );

      _currentUser = user;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('AuthException: ', '');
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _isAuthenticated = false;
      _currentUser = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get auth headers for API calls
  Map<String, String> getAuthHeaders() {
    return _authService.getAuthHeaders();
  }
}
