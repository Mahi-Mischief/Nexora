import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Using Icon instead of SVG to avoid runtime SVG parsing issues.
import 'package:nexora_final/providers/auth_provider.dart';
import 'package:nexora_final/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_final/screens/auth/login_screen.dart';
import 'package:nexora_final/screens/home_screen.dart';
import 'package:nexora_final/services/firebase_flag.dart';

class SplashScreen extends ConsumerStatefulWidget {
  static const routeName = '/';
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // If Firebase is not configured (web), show login so user can see instructions.
      if (!FirebaseFlag.configured) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
        });
        return;
      }

      final token =
          await AuthService.getFreshFirebaseToken() ??
          prefs.getString('nexora_token');
      if (token != null) {
        await prefs.setString('nexora_token', token);
      }

      if (token == null) {
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
        });
        return;
      }

      final meFuture = AuthService.me(token);
      final result = await meFuture.timeout(const Duration(milliseconds: 1500));
      if (!mounted) return;
      if (result != null) {
        ref.read(authProvider.notifier).updateUser(result);
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
      } else {
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/Nexora_logo_with name.png',
              width: 132,
              height: 132,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
