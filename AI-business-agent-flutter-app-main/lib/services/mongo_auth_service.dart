import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// MongoDB-based Authentication Service
/// Uses Node.js backend with JWT tokens
class MongoAuthService {
  MongoAuthService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  String? _token;

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  // Sign up new user
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
    String? businessType,
    String? phone,
    DateTime? dateOfBirth,
  }) async {
    if (ApiConfig.backendUrl.isEmpty) {
      throw const AuthException(
        'Backend URL təyin edilməyib. API_CONFIG-u yeniləyin.',
      );
    }

    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.backendUrl}/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'businessType': businessType ?? '',
          'phone': phone ?? '',
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        return data['user'];
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw AuthException(error['message'] ?? 'Qeydiyyat uğursuz oldu');
      } else {
        throw AuthException('Qeydiyyat xətası: ${response.statusCode}');
      }
    } on AuthException {
      rethrow;
    } on http.ClientException catch (e) {
      throw AuthException('Backendə qoşulmaq mümkün olmadı: $e');
    } catch (e) {
      throw AuthException('Qeydiyyat xətası: $e');
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (ApiConfig.backendUrl.isEmpty) {
      throw const AuthException(
        'Backend URL təyin edilməyib. API_CONFIG-u yeniləyin.',
      );
    }

    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.backendUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        return data['user'];
      } else if (response.statusCode == 401) {
        throw const AuthException('Email və ya şifrə səhvdir');
      } else {
        throw AuthException('Giriş xətası: ${response.statusCode}');
      }
    } on AuthException {
      rethrow;
    } on http.ClientException catch (e) {
      throw AuthException('Backendə qoşulmaq mümkün olmadı: $e');
    } catch (e) {
      throw AuthException('Giriş xətası: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    _token = null;
  }

  // Get authorization header
  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }
}
