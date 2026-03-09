import 'dart:convert';
import 'package:nexora_final/services/api.dart';
import 'package:nexora_final/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:nexora_final/services/google_signin.dart'
    show getGoogleAuthTokens;
import 'package:nexora_final/services/firebase_flag.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String? lastAuthError;

  static void _setLastError(String? message) {
    lastAuthError = message;
  }

  static bool _ensureFirebaseReady(String action) {
    if (FirebaseFlag.configured) return true;
    _setLastError(
      'Firebase is not configured for this run. Restart with a valid FIREBASE_WEB_API_KEY.',
    );
    debugPrint('Firebase $action skipped: FirebaseFlag.configured=false');
    return false;
  }

  static String _friendlyAuthError(fb.FirebaseAuthException e, String action) {
    switch (e.code) {
      case 'invalid-api-key':
        return '$action failed: invalid Firebase API key. Set FIREBASE_WEB_API_KEY and restart.';
      case 'network-request-failed':
        return '$action failed: network error. Check internet/Google Play Services and try again.';
      case 'invalid-credential':
        return '$action failed: invalid credentials. Use your email address and correct password.';
      case 'invalid-email':
        return '$action failed: email format is invalid.';
      case 'user-not-found':
      case 'wrong-password':
        return '$action failed: incorrect email or password.';
      case 'email-already-in-use':
        return '$action failed: that email is already registered.';
      case 'weak-password':
        return '$action failed: password is too weak.';
      case 'too-many-requests':
        return '$action temporarily blocked: too many attempts. Try again later.';
      default:
        return '$action failed (${e.code}): ${e.message ?? 'Unknown error'}';
    }
  }

  static Future<String?> getFreshFirebaseToken() async {
    if (!FirebaseFlag.configured) return null;
    try {
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final token = await user.getIdToken(true);
      if (token == null || token.isEmpty) return null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nexora_token', token);
      return token;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      _setLastError('Token refresh failed: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _syncFirebaseUser({
    String? username,
    String? role,
  }) async {
    try {
      _setLastError(null);
      final token = await getFreshFirebaseToken();
      if (token == null) return null;
      final body = <String, dynamic>{};
      if (username != null && username.trim().isNotEmpty) {
        body['username'] = username.trim();
      }
      if (role != null && role.trim().isNotEmpty) body['role'] = role.trim();

      final resp = await Api.post('/api/auth/sync', body: body, token: token);
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        return {'token': token, 'user': j['user']};
      }
      debugPrint('Sync failed: ${resp.statusCode} ${resp.body}');
      _setLastError('Account sync failed (${resp.statusCode})');
      return null;
    } catch (e) {
      debugPrint('Sync error: $e');
      _setLastError('Account sync error: $e (base: ${Api.baseUrl})');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> signup({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    if (!_ensureFirebaseReady('Signup')) return null;
    try {
      _setLastError(null);
      await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _syncFirebaseUser(username: username, role: role);
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('Firebase signup error: ${e.code} ${e.message}');
      _setLastError(_friendlyAuthError(e, 'Signup'));
      return null;
    } catch (e) {
      debugPrint('Signup error: $e');
      _setLastError('Signup error: $e (base: ${Api.baseUrl})');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    if (!_ensureFirebaseReady('Login')) return null;
    try {
      _setLastError(null);
      final email = usernameOrEmail.trim();
      if (!email.contains('@')) {
        _setLastError('Login failed: enter your email address (not username).');
        return null;
      }
      await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _syncFirebaseUser();
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('Firebase login error: ${e.code} ${e.message}');
      _setLastError(_friendlyAuthError(e, 'Login'));
      return null;
    } catch (e) {
      debugPrint('Login error: $e');
      _setLastError('Login error: $e (base: ${Api.baseUrl})');
      return null;
    }
  }

  static Future<NexoraUser?> me(String token) async {
    try {
      final effectiveToken = await getFreshFirebaseToken() ?? token;
      final resp = await Api.get('/api/auth/me', token: effectiveToken);
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        return NexoraUser.fromJson(j);
      }
      return null;
    } catch (e) {
      debugPrint('Me error: $e');
      _setLastError('Could not load profile: $e');
      return null;
    }
  }

  static Future<void> updateProfile({
    required String token,
    required NexoraUser user,
  }) async {
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
      final effectiveToken = await getFreshFirebaseToken() ?? token;
      final resp = await Api.put(
        '/api/users/$id',
        body: body,
        token: effectiveToken,
      );
      debugPrint('Update profile response: ${resp.statusCode}');
      if (resp.statusCode != 200) {
        throw Exception(
          'Failed to update profile: ${resp.statusCode} ${resp.body}',
        );
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    }
  }

  // Sign in with Google via Firebase and return the Firebase ID token (JWT)
  static Future<String?> signInWithGoogle() async {
    if (!_ensureFirebaseReady('Google sign-in')) return null;
    try {
      if (kIsWeb) {
        final tokens = await getGoogleAuthTokens();
        if (tokens == null) return null;
        return getFreshFirebaseToken();
      } else {
        final tokens = await getGoogleAuthTokens();
        if (tokens == null) return null;
        final credential = fb.GoogleAuthProvider.credential(
          accessToken: tokens['accessToken'],
          idToken: tokens['idToken'],
        );
        await fb.FirebaseAuth.instance.signInWithCredential(credential);
        return getFreshFirebaseToken();
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      _setLastError(
        'Google sign-in error: $e. Verify internet and Firebase OAuth setup.',
      );
      return null;
    }
  }

  static Future<Map<String, dynamic>?> loginWithGoogle() async {
    final idToken = await signInWithGoogle();
    if (idToken == null) return null;
    return _syncFirebaseUser();
  }

  static Future<void> logoutFirebase() async {
    await fb.FirebaseAuth.instance.signOut();
  }
}
