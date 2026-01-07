import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focused,
              selectedDayPredicate: (d) => isSameDay(_selected, d),
              onDaySelected: (s, f) => setState(() {
                _selected = s;
                _focused = f;
              }),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(title: Text('FBLA Chapter Meeting'), subtitle: Text('Monthly meeting — details')),
                  ListTile(title: Text('Competition Registration Deadline'), subtitle: Text('Submit materials')),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
