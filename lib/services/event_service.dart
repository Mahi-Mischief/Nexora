import 'dart:convert';
import 'package:nexora_final/services/api.dart';

class EventService {
  static Future<List<dynamic>> fetchEvents({String? token, String? eventType}) async {
    final resp = await Api.get('/api/events', token: token);
    if (resp.statusCode == 200) {
      final j = jsonDecode(resp.body) as List<dynamic>;
      if (eventType == null || eventType.trim().isEmpty) {
        return j;
      }
      final target = eventType.trim().toLowerCase();
      return j.where((raw) {
        if (raw is! Map<String, dynamic>) return false;
        final value = raw['event_type']?.toString().toLowerCase();
        return value == target;
      }).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>?> fetchEvent(String id, {String? token}) async {
    final resp = await Api.get('/api/events/$id', token: token);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<bool> signupForEvent(int eventId, {required String token}) async {
    final resp = await Api.post('/api/events/$eventId/signup', token: token, body: const {});
    return resp.statusCode == 201 || resp.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> fetchMySignupStatus(int eventId, {required String token}) async {
    final resp = await Api.get('/api/events/$eventId/my-signup', token: token);
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded == null) return null;
      return decoded as Map<String, dynamic>;
    }
    return null;
  }
}
