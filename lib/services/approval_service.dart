import 'dart:convert';
import 'package:nexora_final/services/api.dart';

class ApprovalService {
  static Future<List<dynamic>> fetchApprovals({String? token}) async {
    final resp = await Api.get('/api/approvals', token: token);
    if (resp.statusCode == 200) return jsonDecode(resp.body) as List<dynamic>;
    return [];
  }

  static Future<Map<String, dynamic>?> createApproval({required int messageId, String? token}) async {
    final resp = await Api.post('/api/approvals', body: {'message_id': messageId}, token: token);
    if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
    return null;
  }

  static Future<Map<String, dynamic>?> decideApproval({required int id, required String status, String? token}) async {
    final resp = await Api.patch('/api/approvals/$id', body: {'status': status}, token: token);
    if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
    return null;
  }
}
