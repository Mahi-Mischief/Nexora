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
    // Load any cached user first so UI isn't blocked by network checks
    if (s != null) {
      try {
        final j = jsonDecode(s) as Map<String, dynamic>;
        state = state.copyWith(user: NexoraUser.fromJson(j));
      } catch (_) {}
    }

    // If token exists, validate it in background (fire-and-forget) but don't block init
    if (token != null) {
      AuthService.me(token).then((profile) async {
        if (profile != null) {
          state = state.copyWith(user: profile);
          final prefs2 = await SharedPreferences.getInstance();
          await prefs2.setString('nexora_user', jsonEncode(profile.toJson()));
        }
      }).catchError((_) {});
    }
  }

  Future<bool> signup(String username, String email, String password, String role) async {
    final res = await AuthService.signup(username: username, email: email, password: password, role: role);
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
    // Fire-and-forget remote update so UI flow (splash/login) isn't blocked by network
    final token = prefs.getString('nexora_token');
    if (token != null) {
      AuthService.updateProfile(token: token, user: user).catchError((_) {});
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
