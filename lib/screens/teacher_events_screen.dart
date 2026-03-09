import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_final/services/teacher_service.dart';
import 'package:nexora_final/services/event_service.dart';
import 'package:nexora_final/screens/teacher_calendar_screen.dart';

class TeacherEventsScreen extends StatefulWidget {
  const TeacherEventsScreen({super.key});

  @override
  State<TeacherEventsScreen> createState() => _TeacherEventsScreenState();
}

class _TeacherEventsScreenState extends State<TeacherEventsScreen> {
  String? _token;
  List<dynamic> _teams = [];
  List<dynamic> _volunteeringEvents = [];
  bool _loadingTeams = true;
  bool _loadingEvents = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('nexora_token');
    _loadTeams();
    _loadVolunteeringEvents();
  }

  Future<void> _loadTeams() async {
    setState(() => _loadingTeams = true);
    try {
      final teams = await TeacherService.getTeams(_token!);
      setState(() {
        _teams = teams;
        _loadingTeams = false;
      });
    } catch (e) {
      setState(() => _loadingTeams = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading teams: $e')));
      }
    }
  }

  Future<void> _loadVolunteeringEvents() async {
    setState(() => _loadingEvents = true);
    try {
      final events = await EventService.fetchEvents(
        token: _token,
        eventType: 'volunteering',
      );
      setState(() {
        _volunteeringEvents = events;
        _loadingEvents = false;
      });
    } catch (e) {
      setState(() => _loadingEvents = false);
    }
  }

  Future<void> _createVolunteeringOpportunity() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Volunteering Opportunity'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g., Community Food Bank',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Details about the opportunity',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'e.g., Local Food Bank',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(
                    selectedDate.toLocal().toString().split(' ')[0],
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Time'),
                  subtitle: Text(selectedTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setDialogState(() => selectedTime = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title is required')),
                  );
                  return;
                }

                final eventDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                final event = {
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'date': eventDateTime.toIso8601String(),
                  'location': locationCtrl.text,
                  'event_type': 'volunteering',
                };
                try {
                  final success = await TeacherService.createEvent(
                    _token!,
                    event,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context, success);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadVolunteeringEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Volunteering opportunity created!')),
        );
      }
    }
  }

  Future<void> _deleteVolunteeringEvent(int eventId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Opportunity'),
        content: const Text(
          'Are you sure you want to delete this volunteering opportunity?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await TeacherService.deleteEvent(_token!, eventId);
        _loadVolunteeringEvents();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Opportunity deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _showTeamTasks(dynamic team) async {
    try {
      final tasks = await TeacherService.getTeamTasks(
        _token!,
        team['id'] as int,
      );
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${team['name']} To-Do List',
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
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load team tasks: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Management')),
      backgroundColor: const Color(0xFF0E1A2B),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teams Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Event Teams',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadTeams,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _loadingTeams
                ? const Center(child: CircularProgressIndicator())
                : _teams.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey),
                          SizedBox(width: 12),
                          Expanded(child: Text('No teams registered yet')),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: _teams.map((team) {
                      final isApproved = team['approval_status'] == 'approved';
                      final isPending = team['approval_status'] == 'pending';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            Icons.group,
                            color: isApproved
                                ? Colors.green[400]
                                : isPending
                                ? Colors.orange[400]
                                : Colors.red[400],
                            size: 32,
                          ),
                          title: Text(
                            team['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Event: ${team['event_type']} - ${team['event_name']}',
                              ),
                              Text('School: ${team['school']}'),
                              Text('Members: ${team['member_count']}'),
                              Text(
                                'Status: ${team['approval_status']}',
                                style: TextStyle(
                                  color: isApproved
                                      ? Colors.green
                                      : isPending
                                      ? Colors.orange
                                      : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextButton.icon(
                                onPressed: () => _showTeamTasks(team),
                                icon: const Icon(Icons.checklist, size: 16),
                                label: const Text('View Team To-Do List'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 32),
            const Divider(thickness: 2),
            const SizedBox(height: 24),

            // Volunteering Opportunities Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Volunteering Opportunities',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadVolunteeringEvents,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Calendar'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TeacherCalendarScreen(),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Create'),
                      onPressed: _createVolunteeringOpportunity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _loadingEvents
                ? const Center(child: CircularProgressIndicator())
                : _volunteeringEvents.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No volunteering opportunities posted yet',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: _volunteeringEvents.map((event) {
                      final date = DateTime.parse(event['date']);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            Icons.volunteer_activism,
                            color: Colors.green[400],
                            size: 32,
                          ),
                          title: Text(
                            event['title'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (event['description'] != null &&
                                  event['description'].isNotEmpty)
                                Text(
                                  event['description'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${date.toLocal().toString().split(' ')[0]} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (event['location'] != null &&
                                  event['location'].isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        event['location'],
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _deleteVolunteeringEvent(event['id']),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
