import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nexora_final/services/firebase_flag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora_final/screens/splash_screen.dart';
import 'package:nexora_final/theme.dart';
import 'package:nexora_final/providers/auth_provider.dart';
import 'package:nexora_final/screens/auth/login_screen.dart';
import 'package:nexora_final/screens/auth/signup_screen.dart';
import 'package:nexora_final/screens/profile_info_screen.dart';
import 'package:nexora_final/screens/home_screen.dart';

void main() {
  // Initialize and run inside the same zone to avoid "Zone mismatch" errors.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      // Firebase web configuration from Firebase Console
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyCkaov-F4g9x_Mg9THqiSYnUeqUlhpixA4',
          appId: '1:174980226928:web:8936c90c1056fb2fc579b5',
          messagingSenderId: '174980226928',
          projectId: 'nexora-8c5e6',
          authDomain: 'nexora-8c5e6.firebaseapp.com',
          storageBucket: 'nexora-8c5e6.firebasestorage.app',
        ),
      );
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
  }, (error, stack) {
    // Ensure uncaught errors are printed to the console for easier debugging
    // during development.
    // ignore: avoid_print
    debugPrint('Uncaught zone error: $error');
    // ignore: avoid_print
    debugPrint('$stack');
  });
}

class NexoraApp extends ConsumerWidget {
  const NexoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authProvider);
    return MaterialApp(
      title: 'NEXORA',
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
