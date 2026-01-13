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

  final List<Widget> _pages = const [
    _HomeContent(),
    NexScreen(),
    EventsScreen(),
    ActivitiesScreen(),
    ResourcesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/logo.svg', width: 28, height: 28, colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondary, BlendMode.srcIn)),
            const SizedBox(width: 8),
            const Text('NEXORA'),
          ],
        ),
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
        actions: [IconButton(icon: const Icon(Icons.help_outline), onPressed: () {})],
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
          BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism), label: 'Activities'),
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
          // News Feed Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Announcements', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (isTeacher)
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () => _showCreateAnnouncementDialog(context),
                  tooltip: 'Create Announcement',
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAnnouncementsList(),
          const SizedBox(height: 24),

          // Instagram Integration Section
          const Text('FBLA Social Feed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildInstagramFeed(),
          const SizedBox(height: 24),

          // Student Information Section
          const Text('Profile Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('${user?.firstName ?? "Student"} ${user?.lastName ?? ""}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.school, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(user?.school ?? 'No school set'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(user?.email ?? 'No email'),
                    ],
                  ),
                  if (user?.grade != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.class_, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Grade: ${user?.grade}'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Calendar Section
          const Text('Calendar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildCalendar(),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return _CalendarWidget();
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
          } catch (e) {
            continue;
          }
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (d) => _selectedDay != null && isSameDay(_selectedDay!, d),
                  eventLoader: (day) => eventsMap[DateTime(day.year, day.month, day.day)] ?? [],
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    
                    final dayEvents = eventsMap[DateTime(selectedDay.year, selectedDay.month, selectedDay.day)];
                    if (dayEvents != null && dayEvents.isNotEmpty) {
                      _showEventDetails(context, selectedDay, dayEvents);
                    }
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                if (eventsMap.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Upcoming Events', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...eventsMap.entries.take(3).map((entry) {
                    final date = entry.key;
                    final dayEvents = entry.value;
                    return Column(
                      children: dayEvents.map((e) => ListTile(
                        dense: true,
                        leading: Icon(Icons.event, size: 20, color: Theme.of(context).colorScheme.primary),
                        title: Text(e['title'] ?? '', style: const TextStyle(fontSize: 14)),
                        subtitle: Text('${date.month}/${date.day}/${date.year}', style: const TextStyle(fontSize: 12)),
                        onTap: () => _showEventDetails(context, date, [e]),
                      )).toList(),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEventDetails(BuildContext context, DateTime date, List<dynamic> events) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${date.month}/${date.day}/${date.year}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: events.map((event) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event, color: Theme.of(context).colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event['title'] ?? 'Event',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (event['description'] != null && event['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          event['description'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                      if (event['location'] != null && event['location'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event['location'],
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Extension methods moved back to _HomeContent
extension _HomeContentExtensions on _HomeContent {
  Widget _buildAnnouncementsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadAnnouncements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final announcements = snapshot.data ?? [];

        if (announcements.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.notifications_none, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('No announcements yet', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          children: announcements.map((announcement) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.campaign, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            announcement['title'] ?? 'Announcement',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(announcement['content'] ?? ''),
                    const SizedBox(height: 8),
                    Text(
                      announcement['date'] ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildInstagramFeed() {
    return FutureBuilder<List<InstagramPost>>(
      future: InstagramService.fetchInstagramPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return const SizedBox();
        }

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () async {
                    final url = Uri.parse(post.permalink ?? 'https://www.instagram.com/fbla_national/');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    width: 160,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            post.mediaUrl,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 120,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            post.caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final announcementsJson = prefs.getString('announcements');
    
    if (announcementsJson == null) {
      // Create demo announcements
      final demoAnnouncements = [
        {
          'id': 1,
          'title': 'Welcome to FBLA!',
          'content': 'We\'re excited to have you join us for this year\'s FBLA activities. Check the calendar for upcoming events and competitions.',
          'date': 'January 10, 2026',
          'author': 'FBLA Advisor'
        },
        {
          'id': 2,
          'title': 'Regional Competition Registration Open',
          'content': 'Registration for the Regional Leadership Conference is now open! Sign up in the Events tab before January 20th.',
          'date': 'January 8, 2026',
          'author': 'Competition Coordinator'
        },
        {
          'id': 3,
          'title': 'Weekly Meeting - This Thursday',
          'content': 'Don\'t forget our weekly chapter meeting this Thursday at 3:30 PM in Room 204. We\'ll be discussing fundraising ideas!',
          'date': 'January 12, 2026',
          'author': 'Chapter President'
        },
      ];
      await prefs.setString('announcements', jsonEncode(demoAnnouncements));
      return demoAnnouncements;
    }

    try {
      final decoded = jsonDecode(announcementsJson) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  void _showCreateAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Announcement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter announcement title',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Enter announcement content',
                ),
                maxLines: 4,
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
              if (titleController.text.isEmpty || contentController.text.isEmpty) {
                return;
              }

              final prefs = await SharedPreferences.getInstance();
              final announcementsJson = prefs.getString('announcements');
              List<Map<String, dynamic>> announcements = [];
              
              if (announcementsJson != null) {
                try {
                  final decoded = jsonDecode(announcementsJson) as List;
                  announcements = decoded.cast<Map<String, dynamic>>();
                } catch (_) {}
              }

              announcements.insert(0, {
                'id': DateTime.now().millisecondsSinceEpoch,
                'title': titleController.text,
                'content': contentController.text,
                'date': '${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}',
                'author': 'Teacher'
              });

              await prefs.setString('announcements', jsonEncode(announcements));
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Announcement created!')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
