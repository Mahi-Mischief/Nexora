import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  static const String _configuredBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String _normalizeConfiguredBaseUrl(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) return raw;

    final uri = Uri.tryParse(raw);
    if (uri == null) return raw;

    final host = uri.host.toLowerCase();
    final isLocalHost = host == 'localhost' || host == '127.0.0.1';
    if (isLocalHost && uri.hasPort && uri.port == 300) {
      debugPrint(
        'API_BASE_URL used port 300; auto-correcting to port 3000 for backend sync.',
      );
      return uri.replace(port: 3000).toString();
    }

    return raw;
  }

  static String get baseUrl {
    final configured = _normalizeConfiguredBaseUrl(_configuredBaseUrl);
    if (configured.isNotEmpty) {
      return configured;
    }

    if (kIsWeb) {
      // When running in a hosted web environment, default to same-origin.
      final host = Uri.base.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://localhost:3000';
      }
      return Uri.base.origin;
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    } else {
      return 'http://localhost:3000';
    }
  }

  static String get normalizedBaseUrl {
    final raw = baseUrl.trim();
    if (raw.isEmpty) {
      throw Exception('API base URL is empty. Set --dart-define=API_BASE_URL=http://<host>:3000');
    }
    final noTrailing = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    final parsed = Uri.tryParse(noTrailing);
    if (parsed == null || parsed.scheme.isEmpty || parsed.host.isEmpty) {
      throw Exception('Invalid API base URL "$raw". Expected format: http://<host>:3000');
    }
    return noTrailing;
  }

  static Uri buildUri(String path) {
    final cleanedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBaseUrl$cleanedPath');
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
    final uri = buildUri(path);
    final headers = await _headersWithToken(token);
    return http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
  }

  static Future<http.Response> get(String path, {String? token}) async {
    final uri = buildUri(path);
    final headers = await _headersWithToken(token);
    return http.get(uri, headers: headers);
  }

  static Future<http.Response> put(String path, {Map<String, dynamic>? body, String? token}) async {
    final uri = buildUri(path);
    final headers = await _headersWithToken(token);
    return http.put(uri, headers: headers, body: jsonEncode(body ?? {}));
  }

  static Future<http.Response> patch(String path, {Map<String, dynamic>? body, String? token}) async {
    final uri = buildUri(path);
    final headers = await _headersWithToken(token);
    return http.patch(uri, headers: headers, body: jsonEncode(body ?? {}));
  }

  static Future<http.Response> delete(String path, {String? token}) async {
    final uri = buildUri(path);
    final headers = await _headersWithToken(token);
    return http.delete(uri, headers: headers);
  }
}
