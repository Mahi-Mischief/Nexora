import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora_final/providers/auth_provider.dart';
import 'package:nexora_final/screens/auth/signup_screen.dart';
import 'package:nexora_final/screens/profile_info_screen.dart';
import 'package:nexora_final/screens/home_screen.dart';

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
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _userCtrl,
                decoration: const InputDecoration(labelText: 'Username or Email'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
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
                              // ignore: use_build_context_synchronously
                              Navigator.of(context).pushReplacementNamed(ProfileInfoScreen.routeName);
                            } else {
                              // ignore: use_build_context_synchronously
                              Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
                            }
                          } else {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid credentials')));
                          }
                        }
                      },
                      child: const Text('Login'),
                    ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed(SignupScreen.routeName),
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
