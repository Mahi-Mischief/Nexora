import 'dart:convert';
import 'package:nexora_final/services/api.dart';

class EventService {
  static Future<List<dynamic>> fetchEvents({String? token}) async {
    final resp = await Api.get('/api/events', token: token);
    if (resp.statusCode == 200) {
      final j = jsonDecode(resp.body) as List<dynamic>;
      return j;
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
}
