import 'dart:convert';
import 'package:nexora_final/services/api.dart';

class MessageService {
  static Future<List<dynamic>> fetchMessages({String? token}) async {
    final resp = await Api.get('/api/messages', token: token);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as List<dynamic>;
    }
    return [];
  }

  static Future<Map<String, dynamic>?> sendMessage({required int toUserId, required String content, String? token, String? type}) async {
    final resp = await Api.post('/api/messages', body: {'to_user_id': toUserId, 'content': content, 'type': type ?? 'message'}, token: token);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    return null;
  }
}
