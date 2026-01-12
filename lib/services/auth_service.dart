import 'dart:convert';
import 'package:nexora_final/services/api.dart';
import 'package:nexora_final/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:nexora_final/services/google_signin.dart' show getGoogleAuthTokens;

class AuthService {
  static Future<Map<String, dynamic>?> signup({required String username, required String email, required String password, required String role}) async {
    try {
      final resp = await Api.post('/api/auth/signup', body: {'username': username, 'email': email, 'password': password, 'role': role});
      debugPrint('Signup response status: ${resp.statusCode}');
      debugPrint('Signup response body: ${resp.body}');
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        return j;
      } else if (resp.statusCode == 409) {
        // User already exists
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        throw Exception(j['error'] ?? 'User already exists');
      } else {
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        throw Exception(j['error'] ?? 'Signup failed with status ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Signup error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> login({required String usernameOrEmail, required String password}) async {
    try {
      final resp = await Api.post('/api/auth/login', body: {'usernameOrEmail': usernameOrEmail, 'password': password});
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        return j;
      } else {
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        throw Exception(j['error'] ?? 'Login failed');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  static Future<NexoraUser?> me(String token) async {
    try {
      final resp = await Api.get('/api/auth/me', token: token);
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        return NexoraUser.fromJson(j);
      }
      return null;
    } catch (e) {
      debugPrint('Me error: $e');
      return null;
    }
  }

  static Future<void> updateProfile({required String token, required NexoraUser user}) async {
    try {
      final body = {
        'first_name': user.firstName,
        'last_name': user.lastName,
        'school': user.school,
        'age': user.age,
        'grade': user.grade,
        'address': user.address,
      };
      final id = user.id;
      if (id == null) return;
      final resp = await Api.put('/api/users/$id', body: body, token: token);
      debugPrint('Update profile response: ${resp.statusCode}');
      if (resp.statusCode != 200) {
        throw Exception('Failed to update profile: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    }
  }

  // Sign in with Google via Firebase and return the Firebase ID token (JWT)
  static Future<String?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final tokens = await getGoogleAuthTokens();
        if (tokens == null) return null;
        final idToken = tokens['idToken'];
        return idToken;
      } else {
        final tokens = await getGoogleAuthTokens();
        if (tokens == null) return null;
        final credential = fb.GoogleAuthProvider.credential(
          accessToken: tokens['accessToken'],
          idToken: tokens['idToken'],
        );
        final userCredential = await fb.FirebaseAuth.instance.signInWithCredential(credential);
        final idToken = await userCredential.user?.getIdToken();
        return idToken;
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return null;
    }
  }
}
