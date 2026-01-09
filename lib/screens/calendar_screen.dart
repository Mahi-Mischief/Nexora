import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_final/services/event_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;
  Map<DateTime, List<dynamic>> _eventsMap = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: FutureBuilder<List<dynamic>>(
        future: () async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('nexora_token');
          return EventService.fetchEvents(token: token);
        }(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final events = snapshot.data ?? [];
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

          return Padding(
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
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: (_eventsMap[DateTime(_selected?.year ?? _focused.year, _selected?.month ?? _focused.month, _selected?.day ?? _focused.day)] ?? [])
                        .map((e) => ListTile(title: Text(e['title'] ?? ''), subtitle: Text(e['description'] ?? '')))
                        .toList(),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
