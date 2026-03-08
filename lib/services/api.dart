import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    } else {
      return 'http://localhost:3000';
    }
  }

  static Future<Map<String, String>> _headersWithToken(String? token) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      String effectiveToken = token;
      final firebaseUser = fb.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          final refreshed = await firebaseUser.getIdToken(true);
          if (refreshed != null && refreshed.isNotEmpty) {
            effectiveToken = refreshed;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('nexora_token', refreshed);
          }
        } catch (_) {
          // Fall back to the provided token when Firebase refresh fails.
        }
      }
      headers['Authorization'] = 'Bearer $effectiveToken';
    }
    return headers;
  }

  static Future<http.Response> post(String path, {Map<String, dynamic>? body, String? token}) {
    return _postInternal(path, body: body, token: token);
  }

  static Future<http.Response> _postInternal(String path, {Map<String, dynamic>? body, String? token}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headersWithToken(token);
    return http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
  }

  static Future<http.Response> get(String path, {String? token}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headersWithToken(token);
    return http.get(uri, headers: headers);
  }

  static Future<http.Response> put(String path, {Map<String, dynamic>? body, String? token}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headersWithToken(token);
    return http.put(uri, headers: headers, body: jsonEncode(body ?? {}));
  }

  static Future<http.Response> patch(String path, {Map<String, dynamic>? body, String? token}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headersWithToken(token);
    return http.patch(uri, headers: headers, body: jsonEncode(body ?? {}));
  }

  static Future<http.Response> delete(String path, {String? token}) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headersWithToken(token);
    return http.delete(uri, headers: headers);
  }
}
