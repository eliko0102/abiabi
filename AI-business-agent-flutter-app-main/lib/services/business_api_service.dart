import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Location analysis client. 2GIS keys stay on the Node backend; the mobile
/// app only receives the normalized analysis payload.
class BusinessApiService {
  BusinessApiService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<Map<String, dynamic>> analyzeLocation({
    required String city,
    required String businessType,
    String address = '',
    String mapProvider = '2gis',
  }) async {
    return _post('/api/location-analysis', {
      'city': city,
      'businessType': businessType,
      'address': address,
      'mapProvider': mapProvider,
    });
  }

  Future<Map<String, dynamic>> analyze2GisLocation({
    required String city,
    required String businessType,
    String address = '',
    String mapProvider = '2gis',
  }) {
    return analyzeLocation(
      city: city,
      businessType: businessType,
      address: address,
      mapProvider: mapProvider,
    );
  }

  Future<Map<String, dynamic>> calculateRoi({
    required double rent,
    required double averageTicket,
    double margin = .35,
  }) async {
    return _post('/api/roi', {
      'rent': rent,
      'averageTicket': averageTicket,
      'margin': margin,
    });
  }

  Future<Map<String, dynamic>> generateNegotiationText({
    required String address,
    required List<String> risks,
  }) async {
    return _post('/api/negotiate', {'address': address, 'risks': risks});
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.backendUrl}$path'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = response.body;
      try {
        final error = jsonDecode(response.body);
        if (error is Map<String, dynamic>) {
          message =
              (error['error'] ?? error['message'] ?? error['detail'] ?? message)
                  .toString();
        }
      } catch (_) {
        // Keep the raw response when the server does not return JSON.
      }
      throw Exception('API ${response.statusCode}: $message');
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
  }
}
