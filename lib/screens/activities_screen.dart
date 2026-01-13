import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  List<VolunteeringEvent> _events = [];
  double _totalHours = 0;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final activitiesJson = prefs.getString('volunteer_activities');
    
    if (activitiesJson != null) {
      final List<dynamic> decoded = jsonDecode(activitiesJson);
      setState(() {
        _events = decoded.map((e) => VolunteeringEvent.fromJson(e as Map<String, dynamic>)).toList();
        _totalHours = _events.fold(0, (sum, e) => sum + e.hours);
      });
    }
  }

  Future<void> _addEvent() async {
    final titleCtrl = TextEditingController();
    final hoursCtrl = TextEditingController();
    final dateCtrl = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Volunteering Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Event Name',
                hintText: 'e.g., Community Cleanup',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hoursCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Hours',
                hintText: 'e.g., 3.5',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateCtrl,
              decoration: const InputDecoration(
                labelText: 'Date',
                hintText: 'e.g., 2026-01-12',
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  dateCtrl.text = picked.toIso8601String().split('T')[0];
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty || hoursCtrl.text.isEmpty || dateCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final event = VolunteeringEvent(
                id: DateTime.now().millisecondsSinceEpoch,
                title: titleCtrl.text,
                hours: double.parse(hoursCtrl.text),
                date: DateTime.parse(dateCtrl.text),
              );

              final prefs = await SharedPreferences.getInstance();
              final events = [..._events, event];
              final encoded = jsonEncode(events.map((e) => e.toJson()).toList());
              await prefs.setString('volunteer_activities', encoded);

              setState(() {
                _events = events;
                _totalHours = _events.fold(0, (sum, e) => sum + e.hours);
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event logged successfully!')),
              );
            },
            child: const Text('Log Event'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = _events.where((e) => e.id != id).toList();
    final encoded = jsonEncode(updated.map((e) => e.toJson()).toList());
    await prefs.setString('volunteer_activities', encoded);

    setState(() {
      _events = updated;
      _totalHours = _events.fold(0, (sum, e) => sum + e.hours);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Volunteering Activities')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Volunteering Summary',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              _totalHours.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            const Text('Total Hours'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${_events.length}',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            const Text('Events'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activities',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Log Event'),
                  onPressed: _addEvent,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _events.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.volunteer_activism, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No volunteering events logged yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          const Text('Start logging your volunteering hours!'),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[_events.length - 1 - index]; // Reverse order
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            Icons.volunteer_activism,
                            color: Colors.blue[700],
                          ),
                          title: Text(event.title),
                          subtitle: Text(
                            '${event.date.toLocal().toString().split(' ')[0]} • ${event.hours} hours',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteEvent(event.id),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class VolunteeringEvent {
  final int id;
  final String title;
  final double hours;
  final DateTime date;

  VolunteeringEvent({
    required this.id,
    required this.title,
    required this.hours,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'hours': hours,
    'date': date.toIso8601String(),
  };

  factory VolunteeringEvent.fromJson(Map<String, dynamic> json) => VolunteeringEvent(
    id: json['id'],
    title: json['title'],
    hours: (json['hours'] as num).toDouble(),
    date: DateTime.parse(json['date']),
  );
}
