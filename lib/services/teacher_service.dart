import 'dart:convert';
import 'package:nexora_final/services/api.dart';
import 'package:nexora_final/models/team_task.dart';

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
    if (resp.statusCode == 201) return true;
    throw Exception('Failed to create event: ${resp.statusCode} ${resp.body}');
  }

  static Future<bool> updateEvent(String token, int eventId, Map<String, dynamic> event) async {
    final resp = await Api.put('/api/events/$eventId', token: token, body: event);
    if (resp.statusCode == 200) return true;
    throw Exception('Failed to update event: ${resp.statusCode} ${resp.body}');
  }

  static Future<bool> deleteEvent(String token, int eventId) async {
    final resp = await Api.delete('/api/events/$eventId', token: token);
    if (resp.statusCode == 200) return true;
    throw Exception('Failed to delete event: ${resp.statusCode} ${resp.body}');
  }

  static Future<List<dynamic>> getPendingActivityApprovals(String token) async {
    final resp = await Api.get('/api/teacher/approvals/activities', token: token);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as List<dynamic>;
    }
    if (resp.statusCode == 404) {
      // Backward compatibility: older backend builds may not expose this route.
      return <dynamic>[];
    }
    throw Exception('Failed to fetch activity approvals: ${resp.statusCode}');
  }

  static Future<bool> approveStudentActivity(String token, int studentId, int activityId) async {
    final resp = await Api.put(
      '/api/teacher/students/$studentId/activities/$activityId/approve',
      token: token,
    );
    return resp.statusCode == 200;
  }

  static Future<bool> rejectStudentActivity(String token, int studentId, int activityId) async {
    final resp = await Api.put(
      '/api/teacher/students/$studentId/activities/$activityId/reject',
      token: token,
    );
    return resp.statusCode == 200;
  }

  static Future<List<dynamic>> getPendingSignupApprovals(String token) async {
    final resp = await Api.get('/api/teacher/approvals/signups', token: token);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as List<dynamic>;
    }
    if (resp.statusCode == 404) {
      // Backward compatibility: older backend builds may not expose this route.
      return <dynamic>[];
    }
    throw Exception('Failed to fetch signup approvals: ${resp.statusCode}');
  }

  static Future<bool> approveEventSignup(String token, int eventId, int signupId) async {
    final resp = await Api.put(
      '/api/teacher/events/$eventId/signups/$signupId/approve',
      token: token,
    );
    return resp.statusCode == 200;
  }

  static Future<bool> rejectEventSignup(String token, int eventId, int signupId) async {
    final resp = await Api.put(
      '/api/teacher/events/$eventId/signups/$signupId/reject',
      token: token,
    );
    return resp.statusCode == 200;
  }

  static Future<List<TeamTask>> getTeamTasks(String token, int teamId) async {
    final resp = await Api.get('/api/teams/$teamId/tasks', token: token);
    if (resp.statusCode == 200) {
      final parsed = jsonDecode(resp.body) as List<dynamic>;
      return parsed
          .map((item) => TeamTask.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch team tasks: ${resp.statusCode}');
  }
}
