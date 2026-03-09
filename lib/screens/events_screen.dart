import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_final/services/team_service.dart';
import 'package:nexora_final/models/team.dart';
import 'package:nexora_final/models/team_task.dart';
import 'package:nexora_final/screens/team_questionnaire_screen.dart';
import 'dart:convert';
import 'package:nexora_final/models/user.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nexora_final/providers/auth_provider.dart';
import 'package:nexora_final/services/event_service.dart';
import 'package:nexora_final/services/teacher_service.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Teams'),
            Tab(text: 'Volunteering'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTeamsTab(), _buildVolunteeringTab()],
      ),
    );
  }

  Widget _buildTeamsTab() {
    final isTeacher =
        ref.watch(authProvider).user?.role?.toLowerCase() == 'teacher';

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadTeamData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('Error loading teams'));
        }

        final data = snapshot.data!;
        final teams = data['teams'] as List<Team>? ?? [];
        final userTeamId = data['userTeamId'] as int?;
        final userTeam = data['userTeam'] as Team?;

        // If user is in a team, show team detail view
        if (!isTeacher && userTeam != null && userTeamId != null) {
          return _buildTeamDetailView(userTeam);
        }

        // Otherwise show team list for joining
        return Column(
          children: [
            if (!isTeacher)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create a Team'),
                  onPressed: () async {
                    final school = data['school'] as String? ?? 'Unknown';
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => TeamQuestionnaireScreen(school: school),
                      ),
                    );
                    if (result == true && mounted) {
                      setState(() {});
                    }
                  },
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Teacher view: browse teams and tasks (read-only).',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ),
              ),
            Expanded(
              child: teams.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No teams yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to create a team for your school!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: teams.length,
                      itemBuilder: (context, index) {
                        final team = teams[index];
                        final isUserInTeam = userTeamId == team.id;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(
                              Icons.group,
                              color: isUserInTeam ? Colors.green : Colors.grey,
                            ),
                            title: Text(
                              team.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${team.eventType.capitalize()} - ${team.eventName}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    Text(
                                      '${team.memberCount} members',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Icon(
                                      Icons.person,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    Text(
                                      'Led by ${team.createdByUsername}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: isTeacher
                                ? const Chip(label: Text('View Only'))
                                : isUserInTeam
                                ? const Chip(label: Text('Joined'))
                                : ElevatedButton(
                                    onPressed: () => _joinTeam(team.id!),
                                    child: const Text('Join'),
                                  ),
                            onTap: () {
                              if (isTeacher) {
                                _showTeamTasksReadOnly(team);
                                return;
                              }
                              if (isUserInTeam) return;
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(team.name),
                                  content: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Event: ${team.eventType} - ${team.eventName}',
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Members: ${team.memberCount}'),
                                      const SizedBox(height: 8),
                                      Text('Leader: ${team.createdByUsername}'),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _joinTeam(team.id!);
                                      },
                                      child: const Text('Join Team'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTeamDetailView(Team team) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${team.eventType.capitalize()} - ${team.eventName}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        Text('${team.memberCount} members'),
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        Text('Led by ${team.createdByUsername}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // FBLA Documents Link
            const Text(
              'Resources',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.description, color: Colors.blue),
                title: const Text('FBLA Official Documents & Rubrics'),
                subtitle: const Text('View scoring rubrics and guidelines'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () async {
                  final url =
                      'https://www.fbla.org/participants/competitive-events/';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            // To-Do List Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Event To-Do List',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddTaskDialog(team.id!),
                  tooltip: 'Add task',
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<TeamTask>>(
              future: () async {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('nexora_token');
                return TeamService.fetchTeamTasks(team.id!, token: token);
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = snapshot.data ?? [];

                if (tasks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.checklist,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No tasks yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Checkbox(
                          value: task.isCompleted,
                          onChanged: (value) {
                            if (team.id != null) {
                              _toggleTask(team.id!, task.id, value ?? false);
                            }
                          },
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted ? Colors.grey[600] : null,
                          ),
                        ),
                        subtitle: Text(
                          'By ${task.createdBy}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: team.id != null
                              ? () => _deleteTask(team.id!, task.id)
                              : null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadTeamData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('nexora_token');
    final userJson = prefs.getString('nexora_user');

    if (token == null || userJson == null) {
      return {};
    }

    final user = NexoraUser.fromJson(jsonDecode(userJson));
    final school = user.school ?? 'Unknown';
    final teams = await TeamService.fetchTeamsBySchool(school, token: token);
    final userTeam = await TeamService.getUserTeam(token: token);

    return {
      'teams': teams,
      'userTeamId': userTeam?.id,
      'userTeam': userTeam,
      'school': school,
    };
  }

  Future<void> _joinTeam(int teamId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('nexora_token');

    if (token == null) return;

    final success = await TeamService.joinTeam(teamId, token: token);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully joined team!')),
      );
      setState(() {});
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to join team. You may already be in a team.'),
        ),
      );
    }
  }

  Future<void> _showTeamTasksReadOnly(Team team) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('nexora_token');
    if (token == null || !mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FutureBuilder<List<TeamTask>>(
        future: TeamService.fetchTeamTasks(team.id!, token: token),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final tasks = snapshot.data ?? <TeamTask>[];
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${team.name} - Team Tasks',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: tasks.isEmpty
                        ? const Center(child: Text('No tasks added yet'))
                        : ListView.builder(
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              return ListTile(
                                leading: Icon(
                                  task.isCompleted
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: task.isCompleted
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                title: Text(task.title),
                                subtitle: Text('By ${task.createdBy}'),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddTaskDialog(int teamId) async {
    final controller = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter task description',
            border: OutlineInputBorder(),
          ),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _createTask(teamId, controller.text);
                if (!context.mounted) return;
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTask(int teamId, String title) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('nexora_token');

    if (token == null) return;

    final success = await TeamService.createTask(teamId, title, token: token);
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task added!')));
      setState(() {});
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add task')));
    }
  }

  Future<void> _toggleTask(int teamId, int taskId, bool isCompleted) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('nexora_token');

    if (token == null) return;

    final success = await TeamService.updateTask(
      teamId,
      taskId,
      isCompleted,
      token: token,
    );
    if (success && mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteTask(int teamId, int taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('nexora_token');

    if (token == null) return;

    final success = await TeamService.deleteTask(teamId, taskId, token: token);
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task deleted')));
      setState(() {});
    }
  }

  Widget _buildVolunteeringTab() {
    final user = ref.watch(authProvider).user;
    final isTeacher = user?.role?.toLowerCase() == 'teacher';

    return FutureBuilder<List<dynamic>>(
      future: _loadVolunteeringEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data ?? <dynamic>[];

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Opportunities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isTeacher)
                      ElevatedButton.icon(
                        onPressed: () => _showCreateEventDialog(context, user),
                        icon: const Icon(Icons.add),
                        label: const Text('Create'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (events.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.volunteer_activism,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No volunteering events yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isTeacher
                                ? 'Create one to get started!'
                                : 'Check back later for opportunities',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index] as Map<String, dynamic>;
                      final date = DateTime.tryParse(
                        event['date']?.toString() ?? '',
                      );
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      event['title']?.toString() ??
                                          'Untitled Event',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (isTeacher &&
                                      event['created_by'] == user?.id)
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () => _deleteEventDialog(
                                        context,
                                        event['id'] as int,
                                      ),
                                    ),
                                ],
                              ),
                              if ((event['description'] ?? '')
                                  .toString()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  event['description'].toString(),
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    date == null
                                        ? 'Date not set'
                                        : '${date.toLocal().toString().split(' ')[0]} ${TimeOfDay.fromDateTime(date).format(context)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      (event['location'] ?? 'TBD').toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (!isTeacher) ...[
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _signupForEvent(event['id'] as int),
                                    icon: const Icon(Icons.how_to_reg),
                                    label: const Text('Sign Up'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<dynamic>> _loadVolunteeringEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('nexora_token');
    return EventService.fetchEvents(token: token, eventType: 'volunteering');
  }

  void _showCreateEventDialog(BuildContext context, NexoraUser? user) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    double hours = 1.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Volunteering Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
                    hintText: 'e.g., Community Cleanup',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What will volunteers do?',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'Where will this happen?',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hours: ${hours.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Slider(
                        value: hours,
                        min: 0.5,
                        max: 8,
                        divisions: 15,
                        onChanged: (value) => setState(() => hours = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter an event title'),
                    ),
                  );
                  return;
                }

                final navigator = Navigator.of(context);
                final scaffold = ScaffoldMessenger.of(context);
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('nexora_token');
                if (mounted) {
                  navigator.pop();
                }

                if (token == null) return;
                final event = {
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'details': descriptionController.text.trim(),
                  'location': locationController.text.trim(),
                  'date': DateTime.now()
                      .add(const Duration(days: 1))
                      .toIso8601String(),
                  'event_type': 'volunteering',
                };

                final success = await TeacherService.createEvent(token, event);
                if (success) {
                  setState(() {});
                }

                scaffold.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Event created successfully!'
                          : 'Failed to create event',
                    ),
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEvent(int eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('nexora_token');
    if (token == null) return;

    final success = await TeacherService.deleteEvent(token, eventId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Event deleted' : 'Failed to delete event'),
      ),
    );
    if (success) {
      setState(() {});
    }
  }

  Future<void> _signupForEvent(int eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('nexora_token');
    if (token == null) return;

    final success = await EventService.signupForEvent(eventId, token: token);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Signup request submitted for teacher approval'
              : 'Could not submit signup request',
        ),
      ),
    );
  }

  void _deleteEventDialog(BuildContext context, int eventId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteEvent(eventId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
