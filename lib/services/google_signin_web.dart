import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

/// Web implementation: perform Firebase popup sign-in and return idToken.
Future<Map<String, String>?> getGoogleAuthTokens() async {
  try {
    final provider = fb.GoogleAuthProvider();
    final userCredential = await fb.FirebaseAuth.instance.signInWithPopup(provider);
    final idToken = await userCredential.user?.getIdToken();
    if (idToken == null) return null;
    return {
      'idToken': idToken,
    };
  } catch (e) {
    debugPrint('Google sign-in error: $e');
    if (e.toString().contains('api-key-not-valid')) {
      debugPrint('ERROR: Firebase API key is not valid for web. Check Firebase Console.');
    }
    return null;
  }
}
