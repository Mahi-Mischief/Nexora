import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora_final/models/user.dart';
import 'package:nexora_final/providers/auth_provider.dart';
import 'package:nexora_final/screens/home_screen.dart';

class ProfileInfoScreen extends ConsumerStatefulWidget {
  static const routeName = '/profile-info';
  const ProfileInfoScreen({super.key});

  @override
  ConsumerState<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends ConsumerState<ProfileInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _school = TextEditingController();
  final _age = TextEditingController();
  final _grade = TextEditingController();
  final _address = TextEditingController();

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _school.dispose();
    _age.dispose();
    _grade.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authProvider).user;
    if (auth != null) {
      _first.text = auth.firstName ?? '';
      _last.text = auth.lastName ?? '';
      _school.text = auth.school ?? '';
      _age.text = auth.age?.toString() ?? '';
      _grade.text = auth.grade ?? '';
      _address.text = auth.address ?? '';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile Information')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _first, decoration: const InputDecoration(labelText: 'First Name')),
              const SizedBox(height: 8),
              TextFormField(controller: _last, decoration: const InputDecoration(labelText: 'Last Name')),
              const SizedBox(height: 8),
              TextFormField(controller: _school, decoration: const InputDecoration(labelText: 'School')),
              const SizedBox(height: 8),
              TextFormField(controller: _age, decoration: const InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextFormField(controller: _grade, decoration: const InputDecoration(labelText: 'Grade')),
              const SizedBox(height: 8),
              TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final current = ref.read(authProvider).user;
                  if (current != null) {
                    final updated = NexoraUser(
                      id: current.id,
                      username: current.username,
                      email: current.email,
                      firstName: _first.text.isEmpty ? null : _first.text,
                      lastName: _last.text.isEmpty ? null : _last.text,
                      school: _school.text.isEmpty ? null : _school.text,
                      age: int.tryParse(_age.text),
                      grade: _grade.text.isEmpty ? null : _grade.text,
                      address: _address.text.isEmpty ? null : _address.text,
                      role: current.role,
                    );
                    await ref.read(authProvider.notifier).updateUser(updated);
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
                  }
                },
                child: const Text('Save & Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
