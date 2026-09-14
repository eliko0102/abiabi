import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuditHistoryService {
  AuditHistoryService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _keyFor(String userId) => 'location_audit_history_$userId';

  Future<List<Map<String, dynamic>>> load({required String userId}) async {
    try {
      final raw = await _storage.read(key: _keyFor(userId));
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
    required String userId,
    required Map<String, dynamic> analysis,
    required String address,
    String businessType = '',
    String flowType = 'old',
  }) async {
    final history = await load(userId: userId);
    final entry = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'address': address,
      'businessType': businessType,
      'flowType': flowType,
      'createdAt': DateTime.now().toIso8601String(),
      'analysis': analysis,
    };
    history.removeWhere((item) => item['address'] == address);
    history.insert(0, entry);
    if (history.length > 30) history.removeRange(30, history.length);
    await _storage.write(key: _keyFor(userId), value: jsonEncode(history));
  }

  Future<void> remove({required String userId, required String id}) async {
    final history = await load(userId: userId);
    history.removeWhere((item) => item['id']?.toString() == id);
    await _storage.write(key: _keyFor(userId), value: jsonEncode(history));
  }

  Future<void> clear({required String userId}) =>
      _storage.delete(key: _keyFor(userId));
}
