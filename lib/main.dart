import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:nexora_final/services/firebase_flag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora_final/screens/splash_screen.dart';
import 'package:nexora_final/theme.dart';
import 'package:nexora_final/providers/auth_provider.dart';
import 'package:nexora_final/screens/auth/login_screen.dart';
import 'package:nexora_final/screens/auth/signup_screen.dart';
import 'package:nexora_final/screens/profile_info_screen.dart';
import 'package:nexora_final/screens/home_screen.dart';

const String _firebaseWebApiKey = String.fromEnvironment(
  'FIREBASE_WEB_API_KEY',
  // Preferred web API key (can be overridden per environment).
  defaultValue: 'AIzaSyDXzeTrbu2UcFEvc2G86Xrp9zdlSo6zrls',
);

const String _firebaseWebApiKeyFallback = String.fromEnvironment(
  'FIREBASE_WEB_API_KEY_FALLBACK',
  // Fallback project key for local/dev runs when the primary key is rotated.
  defaultValue: 'AIzaSyDY7nQaRk9ETAxMVgaWyw8MO4BDfkqVIc0',
);

const bool _useFirebaseAuthEmulator = bool.fromEnvironment(
  'USE_FIREBASE_AUTH_EMULATOR',
  defaultValue: false,
);

const String _firebaseAuthEmulatorHost = String.fromEnvironment(
  'FIREBASE_AUTH_EMULATOR_HOST',
  defaultValue: '127.0.0.1',
);

const int _firebaseAuthEmulatorPort = int.fromEnvironment(
  'FIREBASE_AUTH_EMULATOR_PORT',
  defaultValue: 9099,
);

Future<bool> _initializeFirebase() async {
  if (kIsWeb) {
    final keys = <String>{
      _firebaseWebApiKey.trim(),
      _firebaseWebApiKeyFallback.trim(),
    }.where((k) => k.isNotEmpty).toList();

    Object? lastError;
    for (final key in keys) {
      try {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: key,
            appId: '1:565966227734:web:1a9b804b583e475c0d6837',
            messagingSenderId: '565966227734',
            projectId: 'nexora-ee541',
            authDomain: 'nexora-ee541.firebaseapp.com',
            storageBucket: 'nexora-ee541.firebasestorage.app',
          ),
        );

        if (_useFirebaseAuthEmulator) {
          await fb.FirebaseAuth.instance.useAuthEmulator(
            _firebaseAuthEmulatorHost,
            _firebaseAuthEmulatorPort,
          );
        }
        return true;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('No Firebase web API key available');
  }

  await Firebase.initializeApp();
  if (_useFirebaseAuthEmulator) {
    await fb.FirebaseAuth.instance.useAuthEmulator(
      _firebaseAuthEmulatorHost,
      _firebaseAuthEmulatorPort,
    );
  }
  return true;
}

void main() {
  // Initialize and run inside the same zone to avoid "Zone mismatch" errors.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      try {
        await _initializeFirebase();
        FirebaseFlag.setConfigured(true);
      } catch (e) {
        // Firebase not configured for web — mark flag and continue so app doesn't crash.
        // The splash screen will show instructions.
        // ignore: avoid_print
        debugPrint('Firebase initialization failed: $e');
        FirebaseFlag.setConfigured(false);
      }

      FlutterError.onError = (details) {
        FlutterError.dumpErrorToConsole(details);
      };

      runApp(const ProviderScope(child: NexoraApp()));
    },
    (error, stack) {
      // Ensure uncaught errors are printed to the console for easier debugging
      // during development.
      // ignore: avoid_print
      debugPrint('Uncaught zone error: $error');
      // ignore: avoid_print
      debugPrint('$stack');
    },
  );
}

class NexoraApp extends ConsumerWidget {
  const NexoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authProvider);
    return MaterialApp(
      title: 'Nexora',
      theme: nexoraTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        SignupScreen.routeName: (_) => const SignupScreen(),
        ProfileInfoScreen.routeName: (_) => const ProfileInfoScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
      },
      // If already authenticated, send to home after splash logic.
    );
  }
}
