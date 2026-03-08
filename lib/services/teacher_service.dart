import 'dart:convert';
import 'package:nexora_final/services/api.dart';

class TeacherService {
  // ===== TEAM MANAGEMENT =====
  
  static Future<List<dynamic>> getTeams(String token) async {
    final resp = await Api.get('/api/teacher/teams', token: token);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as List<dynamic>;
    }
    throw Exception('Failed to fetch teams: ${resp.statusCode}');
  }

  static Future<List<dynamic>> getTeamMembers(String token, int teamId) async {
    final resp = await Api.get('/api/teacher/teams/$teamId/members', token: token);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as List<dynamic>;
    }
    throw Exception('Failed to fetch team members: ${resp.statusCode}');
  }

  static Future<bool> approveTeam(String token, int teamId) async {
    final resp = await Api.put('/api/teacher/teams/$teamId/approve', token: token);
    return resp.statusCode == 200;
  }

  static Future<bool> rejectTeam(String token, int teamId) async {
    final resp = await Api.put('/api/teacher/teams/$teamId/reject', token: token);
    return resp.statusCode == 200;
  }

  static Future<bool> approveMember(String token, int teamId, int memberId) async {
    final resp = await Api.put('/api/teacher/teams/$teamId/members/$memberId/approve', token: token);
    return resp.statusCode == 200;
  }

  static Future<bool> rejectMember(String token, int teamId, int memberId) async {
    final resp = await Api.put('/api/teacher/teams/$teamId/members/$memberId/reject', token: token);
    return resp.statusCode == 200;
  }

  // ===== STUDENT MANAGEMENT =====

  static Future<List<dynamic>> getStudents(String token) async {
    final resp = await Api.get('/api/teacher/students', token: token);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as List<dynamic>;
    }
    throw Exception('Failed to fetch students: ${resp.statusCode}');
  }

  static Future<List<dynamic>> getStudentActivities(String token, int studentId) async {
    final resp = await Api.get('/api/teacher/students/$studentId/activities', token: token);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as List<dynamic>;
    }
    throw Exception('Failed to fetch student activities: ${resp.statusCode}');
  }

  static Future<bool> addStudentActivity(String token, int studentId, Map<String, dynamic> activity) async {
    final resp = await Api.post('/api/teacher/students/$studentId/activities', token: token, body: activity);
    return resp.statusCode == 201;
  }

  static Future<String> getStudentPdfUrl(int studentId) {
    return Future.value('${Api.baseUrl}/api/teacher/students/$studentId/pdf');
  }

  // ===== EVENT MANAGEMENT =====

  static Future<bool> createEvent(String token, Map<String, dynamic> event) async {
    final resp = await Api.post('/api/events', token: token, body: event);
    return resp.statusCode == 201;
  }

  static Future<bool> updateEvent(String token, int eventId, Map<String, dynamic> event) async {
    final resp = await Api.put('/api/events/$eventId', token: token, body: event);
    return resp.statusCode == 200;
  }

  static Future<bool> deleteEvent(String token, int eventId) async {
    final resp = await Api.delete('/api/events/$eventId', token: token);
    return resp.statusCode == 200;
  }
}
