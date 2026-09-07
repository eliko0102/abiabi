import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuditHistoryService {
  AuditHistoryService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'location_audit_history';
  final FlutterSecureStorage _storage;

  Future<List<Map<String, dynamic>>> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> add({
    required Map<String, dynamic> analysis,
    required String address,
    String businessType = '',
  }) async {
    final history = await load();
    final entry = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'address': address,
      'businessType': businessType,
      'createdAt': DateTime.now().toIso8601String(),
      'analysis': analysis,
    };
    history.removeWhere((item) => item['address'] == address);
    history.insert(0, entry);
    if (history.length > 30) history.removeRange(30, history.length);
    await _storage.write(key: _key, value: jsonEncode(history));
  }
}
