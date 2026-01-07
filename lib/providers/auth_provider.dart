import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_final/models/user.dart';

class AuthState {
  final NexoraUser? user;
  final bool isLoading;

  AuthState({this.user, this.isLoading = false});

  AuthState copyWith({NexoraUser? user, bool? isLoading}) => AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('nexora_user');
    if (s != null) {
      try {
        final j = jsonDecode(s) as Map<String, dynamic>;
        state = state.copyWith(user: NexoraUser.fromJson(j));
      } catch (_) {}
    }
  }

  Future<void> signup(String username, String email, String password) async {
    // For demo, ignore password complexity; store minimal user
    final user = NexoraUser(username: username, email: email);
    state = state.copyWith(user: user);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nexora_user', jsonEncode(user.toJson()));
  }

  Future<void> login(String usernameOrEmail, String password) async {
    // For demo, accept any credentials if they match stored user
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('nexora_user');
    if (s != null) {
      final j = jsonDecode(s) as Map<String, dynamic>;
      final u = NexoraUser.fromJson(j);
      if (u.username == usernameOrEmail || u.email == usernameOrEmail) {
        state = state.copyWith(user: u);
      }
    }
  }

  Future<void> logout() async {
    state = AuthState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('nexora_user');
  }

  Future<void> updateUser(NexoraUser user) async {
    state = state.copyWith(user: user);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nexora_user', jsonEncode(user.toJson()));
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
