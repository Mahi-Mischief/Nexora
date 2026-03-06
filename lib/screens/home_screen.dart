// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import 'package:nexora_final/services/announcement_service.dart';
import 'package:nexora_final/services/instagram_service.dart';
import 'package:nexora_final/services/event_service.dart';
import 'package:nexora_final/providers/auth_provider.dart';
import 'package:nexora_final/screens/calendar_screen.dart';
import 'package:nexora_final/screens/events_screen.dart';
import 'package:nexora_final/screens/activities_screen.dart';
import 'package:nexora_final/screens/news_screen.dart';
import 'package:nexora_final/screens/resources_screen.dart';
import 'package:nexora_final/screens/chat_screen.dart';
import 'package:nexora_final/screens/ai_chat_screen.dart';

import 'package:nexora_final/screens/nex_screen.dart';
import 'package:nexora_final/widgets/app_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  // final List<Widget> _pages = const [
  //   _HomeContent(),
  //   NexScreen(),
  //   EventsScreen(),
  //   ActivitiesScreen(),
  //   ResourcesScreen(),
  // ];


  final List<Widget> _pages = const [
    _HomeContent(),
    AIChatScreen(),
    EventsScreen(),
    ActivitiesScreen(),
    ResourcesScreen(),
    NexScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/logo.svg',
              width: 28,
              height: 28,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.secondary,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            const Text('NEXORA'),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () {})
        ],
      ),
      drawer: const AppDrawer(),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'Nex'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism), label: 'Activities'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Resources'),
        ],
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isTeacher = user?.role?.toLowerCase() == 'teacher';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Announcements',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (isTeacher)
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () => _showCreateAnnouncementDialog(context),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAnnouncementsList(),
          const SizedBox(height: 24),

          const Text(
            'FBLA Social Feed',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInstagramFeed(),
          const SizedBox(height: 24),

          const Text(
            'Profile Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.person,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${user?.firstName ?? "Student"} ${user?.lastName ?? ""}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    )
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.school,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(user?.school ?? 'No school set')
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.email,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(user?.email ?? 'No email')
                  ]),
                  if (user?.grade != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.class_,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Grade: ${user?.grade}')
                    ])
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Calendar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          const _CalendarWidget(),
        ],
      ),
    );
  }
}

class _CalendarWidget extends StatefulWidget {
  const _CalendarWidget();

  @override
  State<_CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<_CalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: () async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('nexora_token');
        return EventService.fetchEvents(token: token);
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data ?? [];
        Map<DateTime, List<dynamic>> eventsMap = {};

        for (final e in events) {
          try {
            final d = DateTime.parse(e['date']);
            final key = DateTime(d.year, d.month, d.day);
            eventsMap.putIfAbsent(key, () => []).add(e);
          } catch (_) {}
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) =>
                  _selectedDay != null && isSameDay(_selectedDay!, d),
              eventLoader: (day) =>
                  eventsMap[DateTime(day.year, day.month, day.day)] ?? [],
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
            ),
          ),
        );
      },
    );
  }
}

extension _HomeContentExtensions on _HomeContent {
  Widget _buildAnnouncementsList() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text("Announcements will appear here."),
      ),
    );
  }

  Widget _buildInstagramFeed() {
    return const SizedBox(
      height: 120,
      child: Center(child: Text("Instagram feed placeholder")),
    );
  }

  void _showCreateAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title")),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Content"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Create")),
        ],
      ),
    );
  }
}