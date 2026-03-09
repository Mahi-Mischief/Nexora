import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

const String _googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '565966227734-sru26o1lfoi795ms6iu6fu52o0op0kfq.apps.googleusercontent.com',
);

/// Returns a map with keys `accessToken` and `idToken`, or null if cancelled.
Future<Map<String, String>?> getGoogleAuthTokens() async {
  final signIn = _googleServerClientId.trim().isNotEmpty
      ? GoogleSignIn(serverClientId: _googleServerClientId.trim())
      : GoogleSignIn();

  try {
    final googleUser = await signIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception(
        'Google sign-in did not return an ID token. Add Android SHA-1/SHA-256 in Firebase and verify GOOGLE_SERVER_CLIENT_ID.',
      );
    }

    return {
      'accessToken': googleAuth.accessToken ?? '',
      'idToken': idToken,
    };
  } on PlatformException catch (e) {
    if (e.code == '10') {
      throw Exception(
        'Google sign-in misconfigured (DEVELOPER_ERROR). Add app SHA-1/SHA-256 to Firebase for package com.example.nexora_final.',
      );
    }
    rethrow;
  }
}
