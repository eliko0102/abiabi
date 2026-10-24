import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// One search client for the map search box and every address field.
///
/// The backend merges 2GIS, a local gazetteer and Nominatim, so the app only
/// needs one request. When the backend is unreachable (cold start, offline
/// emulator) the service still asks OpenStreetMap directly, which is why
/// address autocomplete no longer silently returns an empty list.
class PlaceSearchResult {
  const PlaceSearchResult({required this.items, required this.failed});

  final List<Map<String, dynamic>> items;

  /// True when every provider errored; an empty successful search is not a
  /// failure and must show "no results" instead of a connection error.
  final bool failed;
}

class PlaceSearchService {
  PlaceSearchService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _backendTimeout = Duration(seconds: 6);
  static const Duration _fallbackTimeout = Duration(seconds: 8);

  Future<PlaceSearchResult> search(
    String query, {
    String city = '',
    String language = 'az',
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 2) {
      return const PlaceSearchResult(items: [], failed: false);
    }

    final fromBackend = await _searchBackend(
      normalizedQuery,
      city: city,
      language: language,
    );
    if (fromBackend != null && fromBackend.isNotEmpty) {
      return PlaceSearchResult(items: fromBackend, failed: false);
    }

    final fromOsm = await _searchNominatim(
      normalizedQuery,
      city: city,
      language: language,
    );
    if (fromOsm == null) {
      // Backend answered but had nothing; only report a failure when OSM also
      // could not be reached.
      return PlaceSearchResult(items: const [], failed: fromBackend == null);
    }
    return PlaceSearchResult(items: fromOsm, failed: false);
  }

  /// Returns `null` when the request failed, `[]` when it succeeded empty.
  Future<List<Map<String, dynamic>>?> _searchBackend(
    String query, {
    required String city,
    required String language,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.backendUrl}/api/suggest').replace(
        queryParameters: {
          'q': query,
          if (city.trim().isNotEmpty) 'city': city.trim(),
          'lang': language,
          'limit': '12',
        },
      );
      final response = await _client.get(uri).timeout(_backendTimeout);
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      final raw = decoded is Map ? decoded['suggestions'] : decoded;
      if (raw is! List) return null;
      return raw
          .whereType<Map>()
          .map((item) => normalize(Map<String, dynamic>.from(item)))
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Direct OpenStreetMap fallback. It uses the same result shape as the
  /// backend so the UI does not need two rendering paths.
  /// Returns `null` when OpenStreetMap could not be reached.
  Future<List<Map<String, dynamic>>?> _searchNominatim(
    String query, {
    required String city,
    required String language,
  }) async {
    final scopedCity = city.trim();
    final scopedQuery =
        scopedCity.isNotEmpty &&
            !query.toLowerCase().contains(scopedCity.toLowerCase())
        ? '$scopedCity, $query'
        : query;
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': scopedQuery,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '7',
        'accept-language': switch (language) {
          'en' => 'en,ru,az',
          'ru' => 'ru,az,en',
          'kk' => 'kk,ru,en',
          _ => 'az,ru,en',
        },
      });
      final response = await _client
          .get(
            uri,
            headers: const {
              'User-Agent': 'AI-Business-Agent/1.0 (address search)',
              'Accept': 'application/json',
            },
          )
          .timeout(_fallbackTimeout);
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map((item) => _fromNominatim(Map<String, dynamic>.from(item)))
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _fromNominatim(Map<String, dynamic> item) {
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lon = double.tryParse(item['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;
    final address = item['address'] is Map
        ? Map<String, dynamic>.from(item['address'] as Map)
        : const <String, dynamic>{};
    final name = (item['name'] ?? item['display_name'] ?? '')
        .toString()
        .split(',')
        .first;
    final subtitleParts = <String>{
      if (address['road'] != null) address['road'].toString(),
      if (address['suburb'] != null) address['suburb'].toString(),
      if (address['city'] != null) address['city'].toString(),
      if (address['town'] != null) address['town'].toString(),
      if (address['state'] != null) address['state'].toString(),
      if (address['country'] != null) address['country'].toString(),
    }.where((part) => part.isNotEmpty && part != name).toList();
    final addresstype = (item['addresstype'] ?? item['type'] ?? '')
        .toString()
        .toLowerCase();
    final type = switch (addresstype) {
      'country' => 'country',
      'city' ||
      'town' ||
      'village' ||
      'municipality' ||
      'state' ||
      'region' ||
      'county' ||
      'district' => 'city',
      'house_number' ||
      'house' ||
      'road' ||
      'street' ||
      'residential' ||
      'neighbourhood' ||
      'postcode' ||
      'building' ||
      'pedestrian' => 'address',
      _ => 'poi',
    };
    final bbox = item['boundingbox'];
    Map<String, double>? bounds;
    if (bbox is List && bbox.length == 4) {
      final values = bbox
          .map((value) => double.tryParse(value.toString()))
          .toList();
      if (values.every((value) => value != null)) {
        bounds = {
          'min_lat': values[0]!,
          'max_lat': values[1]!,
          'min_lon': values[2]!,
          'max_lon': values[3]!,
        };
      }
    }
    return normalize({
      'id':
          'osm:${item['osm_type'] ?? 'node'}:${item['osm_id'] ?? '$lat,$lon'}',
      'name': name,
      'subtitle': subtitleParts.take(3).join(', '),
      'type': type,
      'lat': lat,
      'lon': lon,
      'bbox': bounds,
      'city': (address['city'] ?? address['town'] ?? address['village'] ?? '')
          .toString(),
      'zoom': type == 'country'
          ? 4.6
          : type == 'city'
          ? 11.0
          : type == 'address'
          ? 16.0
          : 17.0,
      'source': 'nominatim',
    });
  }

  /// Coerces any provider payload into the single client-side shape.
  static Map<String, dynamic>? normalize(Map<String, dynamic> item) {
    final point = item['point'] is Map
        ? Map<String, dynamic>.from(item['point'] as Map)
        : const <String, dynamic>{};
    final lat = _toDouble(item['lat'] ?? point['lat']);
    final lon = _toDouble(item['lon'] ?? point['lon']);
    if (lat == null || lon == null) return null;
    final name =
        (item['name'] ?? item['full_name'] ?? item['address_name'] ?? '')
            .toString()
            .trim();
    if (name.isEmpty) return null;
    final type = switch (item['type']?.toString()) {
      'country' || 'city' || 'address' || 'poi' => item['type'].toString(),
      _ => 'poi',
    };
    Map<String, double>? bounds;
    final rawBbox = item['bbox'];
    if (rawBbox is Map) {
      final minLat = _toDouble(rawBbox['min_lat']);
      final maxLat = _toDouble(rawBbox['max_lat']);
      final minLon = _toDouble(rawBbox['min_lon']);
      final maxLon = _toDouble(rawBbox['max_lon']);
      if (minLat != null &&
          maxLat != null &&
          minLon != null &&
          maxLon != null) {
        bounds = {
          'min_lat': minLat,
          'max_lat': maxLat,
          'min_lon': minLon,
          'max_lon': maxLon,
        };
      }
    }
    return {
      'id': item['id']?.toString() ?? '$name:$lat,$lon',
      'name': name,
      'subtitle': (item['subtitle'] ?? item['city'] ?? '').toString(),
      'type': type,
      'lat': lat,
      'lon': lon,
      'point': {'lat': lat, 'lon': lon},
      'bbox': bounds,
      'city': (item['city'] ?? '').toString(),
      'country_code': item['country_code']?.toString(),
      'zoom':
          _toDouble(item['zoom']) ??
          (type == 'country'
              ? 4.6
              : type == 'city'
              ? 11.0
              : 16.0),
      'source': item['source']?.toString() ?? 'backend',
    };
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
