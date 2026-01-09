import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nexora_final/providers/auth_provider.dart';
import 'package:nexora_final/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_final/screens/auth/login_screen.dart';
import 'package:nexora_final/screens/home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  static const routeName = '/';
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Keep splash short: 1500ms timeout for backend check
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('nexora_token');
      if (token == null) {
        // no token -> go to login quickly
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
        });
        return;
      }

      final meFuture = AuthService.me(token);
      final result = await meFuture.timeout(const Duration(milliseconds: 1500));
      if (!mounted) return;
      if (result != null) {
        // update provider state (non-blocking)
        ref.read(authProvider.notifier).updateUser(result);
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
      } else {
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      }
    } catch (_) {
      // timeout or error -> go to login and load in background
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.primary,
        child: Center(
          child: ScaleTransition(
            scale: _anim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/logo.svg',
                  width: 160,
                  height: 160,
                  colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondary, BlendMode.srcIn),
                  placeholderBuilder: (context) => Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.school, size: 72, color: Theme.of(context).colorScheme.secondary),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('NEXORA', style: TextStyle(letterSpacing: 4, fontSize: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
