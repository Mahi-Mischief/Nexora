import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora_final/providers/auth_provider.dart';
import 'package:nexora_final/screens/profile_info_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  static const routeName = '/signup';
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String _selectedRole = 'student';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1A2B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign Up',
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _userCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Create password'),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmCtrl,
                decoration: const InputDecoration(labelText: 'Confirm password'),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v != _passCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              Text(
                'Account Type',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRole = 'student'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedRole == 'student' ? Color(0xFFE3B857) : Colors.white30,
                            width: _selectedRole == 'student' ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Student',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedRole == 'student' ? Color(0xFFE3B857) : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRole = 'teacher'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedRole == 'teacher' ? Color(0xFFE3B857) : Colors.white30,
                            width: _selectedRole == 'teacher' ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Teacher',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedRole == 'teacher' ? Color(0xFFE3B857) : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _loading = true);
                          try {
                            final ok = await ref.read(authProvider.notifier).signup(
                              _userCtrl.text,
                              _emailCtrl.text,
                              _passCtrl.text,
                              _selectedRole,
                            );
                            if (!mounted) return;
                            setState(() => _loading = false);
                            if (ok) {
                              Navigator.of(context).pushReplacementNamed(ProfileInfoScreen.routeName);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not create account. User may already exist.')),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            setState(() => _loading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Continue'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
