import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora_final/screens/splash_screen.dart';
import 'package:nexora_final/theme.dart';
import 'package:nexora_final/providers/auth_provider.dart';
import 'package:nexora_final/screens/auth/login_screen.dart';
import 'package:nexora_final/screens/auth/signup_screen.dart';
import 'package:nexora_final/screens/profile_info_screen.dart';
import 'package:nexora_final/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };

  runZonedGuarded(() {
    runApp(const ProviderScope(child: NexoraApp()));
  }, (error, stack) {
    // Ensure uncaught errors are printed to the console for easier debugging
    // during development.
    // ignore: avoid_print
    print('Uncaught zone error: $error');
    // ignore: avoid_print
    print(stack);
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