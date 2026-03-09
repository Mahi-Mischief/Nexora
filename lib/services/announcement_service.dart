import 'dart:convert';
import 'package:nexora_final/services/api.dart';

class AnnouncementService {
  static String _extractError(String body, int statusCode) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic> && parsed['error'] is String) {
        return parsed['error'] as String;
      }
    } catch (_) {}
    return 'Request failed ($statusCode)';
  }

  static Future<List<dynamic>> fetchAnnouncements({String? token}) async {
    final resp = await Api.get('/api/announcements', token: token);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as List<dynamic>;
    }
    throw Exception(_extractError(resp.body, resp.statusCode));
  }

  static Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String content,
    String? token,
  }) async {
    final resp = await Api.post('/api/announcements', body: {
      'title': title,
      'content': content,
    }, token: token);
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(resp.body, resp.statusCode));
  }

  static Future<Map<String, dynamic>> updateAnnouncement({
    required int id,
    required String title,
    required String content,
    String? token,
  }) async {
    final resp = await Api.put('/api/announcements/$id', body: {
      'title': title,
      'content': content,
    }, token: token);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(resp.body, resp.statusCode));
  }

  static Future<void> deleteAnnouncement({required int id, String? token}) async {
    final resp = await Api.delete('/api/announcements/$id', token: token);
    if (resp.statusCode == 200) return;
    throw Exception(_extractError(resp.body, resp.statusCode));
  }
}
