// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

import 'package:nexora_final/providers/auth_provider.dart';
import 'package:nexora_final/services/auth_service.dart';
import 'package:nexora_final/services/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_final/models/user.dart';
import 'package:nexora_final/screens/auth/signup_screen.dart';
import 'package:nexora_final/screens/home_screen.dart';
import 'package:nexora_final/screens/profile_info_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Text(
                'N',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE3B857),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'NEXORA',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'WELCOME!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 30),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                    ),
                    obscureText: true,
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  _loading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _loading = true);
                              final ok = await ref.read(authProvider.notifier).login(_userCtrl.text, _passCtrl.text);
                              if (!mounted) return;
                              setState(() => _loading = false);
                              if (ok) {
                                final auth = ref.read(authProvider);
                                if (auth.user != null && auth.user!.firstName == null) {
                                  //Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
                                  Navigator.of(context).pushReplacementNamed(ProfileInfoScreen.routeName);
                                } else {
                                  Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid credentials')));
                              }
                            }
                          },
                          child: const Text('Log In'),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white24)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('OR', style: TextStyle(color: Colors.white54)),
                ),
                Expanded(child: Divider(color: Colors.white24)),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: Icon(Icons.account_circle),
              label: const Text('Continue with Google'),
              onPressed: () async {
                setState(() => _loading = true);
                final idToken = await AuthService.signInWithGoogle();
                if (idToken == null) {
                  setState(() => _loading = false);
                  return;
                }
                final resp = await Api.post('/api/auth/google', body: {'idToken': idToken});
                if (resp.statusCode == 200) {
                  final j = jsonDecode(resp.body) as Map<String, dynamic>;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('nexora_token', j['token']);
                  await prefs.setString('nexora_user', jsonEncode(j['user']));
                  final user = NexoraUser.fromJson(j['user']);
                  await ref.read(authProvider.notifier).updateUser(user);
                  if (!mounted) return;
                  if (user.firstName == null) {
                    Navigator.of(context).pushReplacementNamed(ProfileInfoScreen.routeName);
                  } else {
                    Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google sign-in failed')));
                }
                setState(() => _loading = false);
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(color: Colors.white70),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(SignupScreen.routeName),
                  child: Text(
                    'Sign up',
                    style: TextStyle(
                      color: Color(0xFFE3B857),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
