import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_final/models/user.dart';
import 'package:nexora_final/services/auth_service.dart';

// Note: AuthNotifier now uses `AuthService` to call backend APIs and persists the JWT.

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
    final token = prefs.getString('nexora_token');
    if (token != null) {
      // attempt to load profile from backend
      try {
        final profile = await AuthService.me(token);
        if (profile != null) {
          state = state.copyWith(user: profile);
        }
      } catch (_) {
        // ignore, user will need to log in
      }
    } else if (s != null) {
      try {
        final j = jsonDecode(s) as Map<String, dynamic>;
        state = state.copyWith(user: NexoraUser.fromJson(j));
      } catch (_) {}
    }
  }

  Future<bool> signup(String username, String email, String password) async {
    final res = await AuthService.signup(username: username, email: email, password: password);
    if (res != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nexora_token', res['token']);
      await prefs.setString('nexora_user', jsonEncode(res['user']));
      state = state.copyWith(user: NexoraUser.fromJson(res['user']));
      return true;
    }
    return false;
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    final res = await AuthService.login(usernameOrEmail: usernameOrEmail, password: password);
    if (res != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nexora_token', res['token']);
      await prefs.setString('nexora_user', jsonEncode(res['user']));
      state = state.copyWith(user: NexoraUser.fromJson(res['user']));
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    state = AuthState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('nexora_user');
    await prefs.remove('nexora_token');
  }

  Future<void> updateUser(NexoraUser user) async {
    state = state.copyWith(user: user);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nexora_user', jsonEncode(user.toJson()));
    final token = prefs.getString('nexora_token');
    if (token != null) {
      // attempt to persist changes to backend
      try {
        await AuthService.updateProfile(token: token, user: user);
      } catch (_) {}
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
