import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_final/services/teacher_service.dart';

class TeacherTeamsScreen extends StatefulWidget {
  const TeacherTeamsScreen({super.key});

  @override
  State<TeacherTeamsScreen> createState() => _TeacherTeamsScreenState();
}

class _TeacherTeamsScreenState extends State<TeacherTeamsScreen> {
  List<dynamic> _teams = [];
  bool _loading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('nexora_token');
      if (_token != null) {
        final teams = await TeacherService.getTeams(_token!);
        setState(() {
          _teams = teams;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading teams: $e')),
        );
      }
    }
  }

  Future<void> _approveTeam(int teamId) async {
    try {
      final success = await TeacherService.approveTeam(_token!, teamId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team approved!')),
        );
        _loadTeams();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _rejectTeam(int teamId) async {
    try {
      final success = await TeacherService.rejectTeam(_token!, teamId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team rejected')),
        );
        _loadTeams();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _viewMembers(dynamic team) async {
    try {
      final members = await TeacherService.getTeamMembers(_token!, team['id']);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team Members - ${team['name']}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final isPending = member['approval_status'] == 'pending';

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(member['first_name']?[0] ?? member['username'][0]),
                            ),
                            title: Text(
                              '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}'.trim().isEmpty
                                  ? member['username']
                                  : '${member['first_name']} ${member['last_name']}',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(member['email'] ?? ''),
                                Text(
                                  'Status: ${member['approval_status']}',
                                  style: TextStyle(
                                    color: isPending ? Colors.orange : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: isPending
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check, color: Colors.green),
                                        onPressed: () async {
                                          await TeacherService.approveMember(_token!, team['id'], member['id']);
                                          Navigator.pop(context);
                                          _viewMembers(team);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Member approved')),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () async {
                                          await TeacherService.rejectMember(_token!, team['id'], member['id']);
                                          Navigator.pop(context);
                                          _viewMembers(team);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Member rejected')),
                                          );
                                        },
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading members: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teams'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTeams,
              child: _teams.isEmpty
                  ? const Center(child: Text('No teams yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _teams.length,
                      itemBuilder: (context, index) {
                        final team = _teams[index];
                        final isPending = team['approval_status'] == 'pending';
                        final isApproved = team['approval_status'] == 'approved';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: Icon(
                              Icons.group,
                              color: isApproved ? Colors.green : (isPending ? Colors.orange : Colors.red),
                            ),
                            title: Text(
                              team['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${team['event_type']} - ${team['event_name']}'),
                                Text('Created by: ${team['created_by_username']}'),
                                Text(
                                  'Status: ${team['approval_status']}',
                                  style: TextStyle(
                                    color: isApproved ? Colors.green : (isPending ? Colors.orange : Colors.red),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('Members: ${team['actual_member_count']}/${team['member_count']}'),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    if (isPending) ...[
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.check),
                                        label: const Text('Approve Team'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                        onPressed: () => _approveTeam(team['id']),
                                      ),
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.close),
                                        label: const Text('Reject'),
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                        onPressed: () => _rejectTeam(team['id']),
                                      ),
                                    ],
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.people),
                                      label: const Text('View Members'),
                                      onPressed: () => _viewMembers(team),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
