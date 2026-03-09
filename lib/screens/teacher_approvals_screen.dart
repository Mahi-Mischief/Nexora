import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_final/services/teacher_service.dart';

class TeacherApprovalsScreen extends StatefulWidget {
  const TeacherApprovalsScreen({super.key});

  @override
  State<TeacherApprovalsScreen> createState() => _TeacherApprovalsScreenState();
}

class _TeacherApprovalsScreenState extends State<TeacherApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _pendingTeams = [];
  List<dynamic> _pendingMembers = [];
  List<dynamic> _pendingHours = [];
  List<dynamic> _pendingSignups = [];
  bool _loading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadApprovals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApprovals() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('nexora_token');
      if (_token != null) {
        final teams = await TeacherService.getTeams(_token!);

        // Filter pending teams
        final pendingTeams = teams
            .where((t) => t['approval_status'] == 'pending')
            .toList();

        // Get pending members for all teams
        List<dynamic> allPendingMembers = [];
        for (var team in teams) {
          final members = await TeacherService.getTeamMembers(
            _token!,
            team['id'],
          );
          final pendingMembers = members
              .where((m) => m['approval_status'] == 'pending')
              .toList();
          for (var member in pendingMembers) {
            member['team_name'] = team['name'];
            member['team_id'] = team['id'];
          }
          allPendingMembers.addAll(pendingMembers);
        }

        final pendingHours = await TeacherService.getPendingActivityApprovals(
          _token!,
        );
        final pendingSignups = await TeacherService.getPendingSignupApprovals(
          _token!,
        );

        setState(() {
          _pendingTeams = pendingTeams;
          _pendingMembers = allPendingMembers;
          _pendingHours = pendingHours;
          _pendingSignups = pendingSignups;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading approvals: $e')));
      }
    }
  }

  Future<void> _approveHour(dynamic item) async {
    try {
      final ok = await TeacherService.approveStudentActivity(
        _token!,
        item['student_id'] as int,
        item['id'] as int,
      );
      if (ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Volunteering hours approved')),
        );
        _loadApprovals();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _rejectHour(dynamic item) async {
    try {
      final ok = await TeacherService.rejectStudentActivity(
        _token!,
        item['student_id'] as int,
        item['id'] as int,
      );
      if (ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Volunteering hours rejected')),
        );
        _loadApprovals();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _approveSignup(dynamic item) async {
    try {
      final ok = await TeacherService.approveEventSignup(
        _token!,
        item['event_id'] as int,
        item['id'] as int,
      );
      if (ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Signup approved')));
        _loadApprovals();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _rejectSignup(dynamic item) async {
    try {
      final ok = await TeacherService.rejectEventSignup(
        _token!,
        item['event_id'] as int,
        item['id'] as int,
      );
      if (ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Signup rejected')));
        _loadApprovals();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _approveTeam(dynamic team) async {
    try {
      final success = await TeacherService.approveTeam(_token!, team['id']);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Team "${team['name']}" approved!')),
        );
        _loadApprovals();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _rejectTeam(dynamic team) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Team'),
        content: Text('Are you sure you want to reject "${team['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await TeacherService.rejectTeam(_token!, team['id']);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Team "${team['name']}" rejected')),
          );
          _loadApprovals();
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _approveMember(dynamic member) async {
    try {
      final success = await TeacherService.approveMember(
        _token!,
        member['team_id'],
        member['id'],
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${member['first_name'] ?? member['username']} approved!',
            ),
          ),
        );
        _loadApprovals();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _rejectMember(dynamic member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Member'),
        content: Text(
          'Reject ${member['first_name'] ?? member['username']} from joining ${member['team_name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await TeacherService.rejectMember(
          _token!,
          member['team_id'],
          member['id'],
        );
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Member rejected')));
          _loadApprovals();
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPending =
        _pendingTeams.length +
        _pendingMembers.length +
        _pendingHours.length +
        _pendingSignups.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Approvals'),
            if (totalPending > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalPending',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Teams'),
                  if (_pendingTeams.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_pendingTeams.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Members'),
                  if (_pendingMembers.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_pendingMembers.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Hours'),
                  if (_pendingHours.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_pendingHours.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Signups'),
                  if (_pendingSignups.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_pendingSignups.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadApprovals,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTeamsTab(),
                  _buildMembersTab(),
                  _buildHoursTab(),
                  _buildSignupsTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildTeamsTab() {
    if (_pendingTeams.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No pending team approvals', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _pendingTeams.length,
      itemBuilder: (context, index) {
        final team = _pendingTeams[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.group, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        team['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Event: ${team['event_type']} - ${team['event_name']}'),
                Text('Created by: ${team['created_by_username']}'),
                Text('School: ${team['school']}'),
                Text('Target members: ${team['member_count']}'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () => _rejectTeam(team),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => _approveTeam(team),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMembersTab() {
    if (_pendingMembers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No pending member approvals', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _pendingMembers.length,
      itemBuilder: (context, index) {
        final member = _pendingMembers[index];
        final fullName =
            '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}'.trim();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundImage: AssetImage('assets/user_icon.jpg'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName.isEmpty ? member['username'] : fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(member['email'] ?? ''),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.group, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Wants to join: ${member['team_name']}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                if (member['grade'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Grade: ${member['grade']}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () => _rejectMember(member),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => _approveMember(member),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHoursTab() {
    if (_pendingHours.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No pending volunteering hours',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _pendingHours.length,
      itemBuilder: (context, index) {
        final item = _pendingHours[index];
        final name = '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'
            .trim();
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(item['title']?.toString() ?? 'Activity'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Student: ${name.isEmpty ? item['username'] : name}'),
                Text(
                  'Type: ${item['activity_type']} • Hours: ${item['hours']}',
                ),
                Text('Date: ${item['date']}'),
              ],
            ),
            trailing: Wrap(
              spacing: 6,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _rejectHour(item),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _approveHour(item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignupsTab() {
    if (_pendingSignups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No pending event signups', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _pendingSignups.length,
      itemBuilder: (context, index) {
        final item = _pendingSignups[index];
        final name = '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'
            .trim();
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(item['event_title']?.toString() ?? 'Event Signup'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Student: ${name.isEmpty ? item['username'] : name}'),
                Text('Type: ${item['event_type'] ?? 'general'}'),
                Text('Date: ${item['event_date']}'),
              ],
            ),
            trailing: Wrap(
              spacing: 6,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _rejectSignup(item),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _approveSignup(item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
