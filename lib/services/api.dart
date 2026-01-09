import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

  static Future<http.Response> post(String path, {Map<String, dynamic>? body, String? token}) {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
  }

  static Future<http.Response> get(String path, {String? token}) {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return http.get(uri, headers: headers);
  }

  static Future<http.Response> put(String path, {Map<String, dynamic>? body, String? token}) {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return http.put(uri, headers: headers, body: jsonEncode(body ?? {}));
  }

  static Future<http.Response> patch(String path, {Map<String, dynamic>? body, String? token}) {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return http.patch(uri, headers: headers, body: jsonEncode(body ?? {}));
  }

  static Future<http.Response> delete(String path, {String? token}) {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return http.delete(uri, headers: headers);
  }
}
