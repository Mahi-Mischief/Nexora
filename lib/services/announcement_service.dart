import 'dart:convert';
import 'package:nexora_final/services/api.dart';

class AnnouncementService {
  static Future<List<dynamic>> fetchAnnouncements({String? token}) async {
    final resp = await Api.get('/api/announcements', token: token);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as List<dynamic>;
    }
    return [];
  }
}
