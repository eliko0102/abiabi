import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Business API Service for new Node.js + MongoDB backend
/// All endpoints require JWT authentication
class BusinessApiServiceV2 {
  BusinessApiServiceV2({
    http.Client? client,
    required String authToken,
  })  : _client = client ?? http.Client(),
        _authToken = authToken;

  final http.Client _client;
  final String _authToken;

  /// Analyze business location viability
  Future<Map<String, dynamic>> analyzeLocation({
    required String city,
    required String businessType,
    String address = '',
  }) async {
    return _post('/location-analysis', {
      'city': city,
      'businessType': businessType,
      'address': address,
    });
  }

  /// Calculate Return on Investment
  Future<Map<String, dynamic>> calculateRoi({
    required double rent,
    required double averageTicket,
    double margin = 0.35,
  }) async {
    return _post('/roi', {
      'rent': rent,
      'averageTicket': averageTicket,
      'margin': margin,
    });
  }

  /// Get AI-generated negotiation text
  Future<Map<String, dynamic>> generateNegotiationText({
    required String address,
    required List<String> risks,
  }) async {
    return _post('/negotiate', {
      'address': address,
      'risks': risks,
    });
  }

  /// Send chat prompt to AI
  Future<String> chat({required String prompt}) async {
    final response = await _post('/chat', {'prompt': prompt});
    return response['message'] ?? response['response'] ?? '';
  }

  /// Internal POST helper with auth
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    if (_authToken.isEmpty) {
      throw Exception('Authentication required. Please login first.');
    }

    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.backendUrl}/api$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401) {
          throw Exception('Session expired. Please login again.');
        }
        throw Exception('API Error ${response.statusCode}: ${response.body}');
      }

      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic>
          ? decoded
          : {'data': decoded, 'success': true};
    } catch (e) {
      throw Exception('API request failed: $e');
    }
  }
}
