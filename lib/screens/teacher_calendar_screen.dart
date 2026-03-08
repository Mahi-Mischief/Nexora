import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_final/services/event_service.dart';
import 'package:nexora_final/services/teacher_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora_final/providers/auth_provider.dart';

class TeacherCalendarScreen extends ConsumerStatefulWidget {
  const TeacherCalendarScreen({super.key});

  @override
  ConsumerState<TeacherCalendarScreen> createState() => _TeacherCalendarScreenState();
}

class _TeacherCalendarScreenState extends ConsumerState<TeacherCalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;
  Map<DateTime, List<dynamic>> _eventsMap = {};
  List<dynamic> _allEvents = [];
  bool _loading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('nexora_token');
      final events = await EventService.fetchEvents(token: _token);
      
      _eventsMap = {};
      for (final e in events) {
        try {
          final d = DateTime.parse(e['date']);
          final key = DateTime(d.year, d.month, d.day);
          _eventsMap.putIfAbsent(key, () => []).add(e);
        } catch (e) {
          continue;
        }
      }
      
      setState(() {
        _allEvents = events;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    }
  }

  Future<void> _createEvent() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    DateTime selectedDate = _selected ?? _focused;
    TimeOfDay selectedTime = TimeOfDay.now();
    String eventType = 'general';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Event Title *',
                    hintText: 'e.g., FBLA State Competition',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'e.g., School Auditorium',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: eventType,
                  decoration: const InputDecoration(
                    labelText: 'Event Type *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General Event')),
                    DropdownMenuItem(value: 'volunteering', child: Text('Volunteering Opportunity')),
                  ],
                  onChanged: (val) => setDialogState(() => eventType = val ?? 'general'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(selectedDate.toLocal().toString().split(' ')[0]),
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
                  'event_type': eventType,
                };

                final success = await TeacherService.createEvent(_token!, event);
                if (!context.mounted) return;
                Navigator.pop(context, success);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully')),
        );
      }
    }
  }

  Future<void> _editEvent(dynamic event) async {
    final titleCtrl = TextEditingController(text: event['title']);
    final descCtrl = TextEditingController(text: event['description'] ?? '');
    final locationCtrl = TextEditingController(text: event['location'] ?? '');
    DateTime selectedDate = DateTime.parse(event['date']);
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    String eventType = event['event_type'] ?? 'general';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Event Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: eventType,
                  decoration: const InputDecoration(
                    labelText: 'Event Type *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General Event')),
                    DropdownMenuItem(value: 'volunteering', child: Text('Volunteering Opportunity')),
                  ],
                  onChanged: (val) => setDialogState(() => eventType = val ?? 'general'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(selectedDate.toLocal().toString().split(' ')[0]),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
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
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Event'),
                    content: const Text('Are you sure you want to delete this event?'),
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
                  await TeacherService.deleteEvent(_token!, event['id']);
                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
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

                final updatedEvent = {
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'date': eventDateTime.toIso8601String(),
                  'location': locationCtrl.text,
                  'event_type': eventType,
                };

                final success = await TeacherService.updateEvent(_token!, event['id'], updatedEvent);
                if (!context.mounted) return;
                Navigator.pop(context, success);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event updated')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isTeacher = auth.user?.role == 'teacher';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: isTeacher
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Create Event',
                  onPressed: _createEvent,
                ),
              ]
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focused,
                    selectedDayPredicate: (d) => isSameDay(_selected, d),
                    eventLoader: (day) => _eventsMap[DateTime(day.year, day.month, day.day)] ?? [],
                    onDaySelected: (s, f) => setState(() {
                      _selected = s;
                      _focused = f;
                    }),
                    calendarStyle: CalendarStyle(
                      markerDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: () {
                      final selectedKey = DateTime(
                        _selected?.year ?? _focused.year,
                        _selected?.month ?? _focused.month,
                        _selected?.day ?? _focused.day,
                      );
                      final dayEvents = _eventsMap[selectedKey] ?? [];

                      if (dayEvents.isEmpty) {
                        return const Center(child: Text('No events on this day'));
                      }

                      return ListView.builder(
                        itemCount: dayEvents.length,
                        itemBuilder: (context, index) {
                          final event = dayEvents[index];
                          final eventDate = DateTime.parse(event['date']);

                          return Card(
                            child: ListTile(
                              leading: Icon(Icons.event, color: Theme.of(context).primaryColor),
                              title: Text(
                                event['title'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (event['description'] != null && event['description'].toString().isNotEmpty)
                                    Text(event['description']),
                                  Text('Time: ${TimeOfDay.fromDateTime(eventDate).format(context)}'),
                                  if (event['location'] != null && event['location'].toString().isNotEmpty)
                                    Text('Location: ${event['location']}'),
                                ],
                              ),
                              trailing: isTeacher ? const Icon(Icons.edit, size: 20) : null,
                              onTap: isTeacher ? () => _editEvent(event) : null,
                            ),
                          );
                        },
                      );
                    }(),
                  ),
                ],
              ),
            ),
    );
  }
}
