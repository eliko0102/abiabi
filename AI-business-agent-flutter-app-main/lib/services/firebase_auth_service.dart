import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class FirebaseAuthException implements Exception {
  const FirebaseAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Firebase Identity Toolkit REST client. It lets the app use Firebase Auth
/// without putting an admin/service-account secret in the APK.
class FirebaseAuthService {
  FirebaseAuthService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<void> signIn(String email, String password) => _authenticate('signInWithPassword', email, password);
  Future<void> register(String email, String password) => _authenticate('signUp', email, password);

  Future<void> _authenticate(String method, String email, String password) async {
    if (ApiConfig.firebaseWebApiKey.isEmpty) {
      throw const FirebaseAuthException('Firebase Web API key təyin edilməyib. FIREBASE_WEB_API_KEY əlavə edin.');
    }
    final response = await _client.post(
      Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:$method?key=${ApiConfig.firebaseWebApiKey}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    try {
      final code = (jsonDecode(response.body)['error']['message'] ?? 'AUTH_ERROR').toString();
      throw FirebaseAuthException(_friendlyMessage(code));
    } catch (error) {
      if (error is FirebaseAuthException) rethrow;
      throw const FirebaseAuthException('Firebase autentifikasiya xətası baş verdi.');
    }
  }

  String _friendlyMessage(String code) {
    switch (code) {
      case 'EMAIL_NOT_FOUND':
      case 'INVALID_PASSWORD':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'E-poçt və ya şifrə yanlışdır.';
      case 'EMAIL_EXISTS':
        return 'Bu e-poçt artıq qeydiyyatdan keçib.';
      case 'CONFIGURATION_NOT_FOUND':
        return 'Firebase Auth konfiqurasiyası tapılmadı. Firebase Console-da Email/Password girişini aktiv edin və Web API key istifadə edin.';
      case 'OPERATION_NOT_ALLOWED':
        return 'Firebase Console-da Email/Password giriş metodu aktiv deyil.';
      case 'WEAK_PASSWORD : Password should be at least 6 characters':
        return 'Şifrə ən azı 6 simvol olmalıdır.';
      default:
        return 'Firebase xətası: $code';
    }
  }
}
