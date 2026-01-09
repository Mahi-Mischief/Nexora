import 'dart:convert';
import 'package:nexora_final/services/api.dart';
import 'package:nexora_final/models/user.dart';

class AuthService {
  static Future<Map<String, dynamic>?> signup({required String username, required String email, required String password}) async {
    final resp = await Api.post('/api/auth/signup', body: {'username': username, 'email': email, 'password': password});
    if (resp.statusCode == 200) {
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      return j;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> login({required String usernameOrEmail, required String password}) async {
    final resp = await Api.post('/api/auth/login', body: {'usernameOrEmail': usernameOrEmail, 'password': password});
    if (resp.statusCode == 200) {
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      return j;
    }
    return null;
  }

  static Future<NexoraUser?> me(String token) async {
    final resp = await Api.get('/api/auth/me', token: token);
    if (resp.statusCode == 200) {
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      return NexoraUser.fromJson(j);
    }
    return null;
  }

  static Future<void> updateProfile({required String token, required NexoraUser user}) async {
    final body = {
      'first_name': user.firstName,
      'last_name': user.lastName,
      'school': user.school,
      'age': user.age,
      'grade': user.grade,
      'address': user.address,
    };
    final id = user.id;
    if (id == null) return;
    await Api.put('/api/users/$id', body: body, token: token);
  }
}
