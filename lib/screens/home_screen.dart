// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:nexora_final/services/announcement_service.dart';
import 'package:nexora_final/services/instagram_service.dart';
import 'package:nexora_final/providers/auth_provider.dart';
import 'package:nexora_final/screens/calendar_screen.dart';
import 'package:nexora_final/screens/events_screen.dart';
import 'package:nexora_final/screens/activities_screen.dart';
import 'package:nexora_final/screens/news_screen.dart';
import 'package:nexora_final/screens/resources_screen.dart';
import 'package:nexora_final/screens/chat_screen.dart';
import 'package:nexora_final/screens/ai_chat_screen.dart';
import 'package:nexora_final/widgets/app_drawer.dart';

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
    CalendarScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism), label: 'Activities'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Resources'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatScreen())),
        child: const Icon(Icons.chat_bubble_outline),
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

          // Quick Links Section
          const Text('Quick Links', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildQuickLinkCard(context, 'Calendar', Icons.calendar_month, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalendarScreen()))),
              _buildQuickLinkCard(context, 'Events', Icons.event, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventsScreen()))),
              _buildQuickLinkCard(context, 'Volunteering', Icons.volunteer_activism, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActivitiesScreen()))),
              _buildQuickLinkCard(context, 'Resources', Icons.folder, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResourcesScreen()))),
              _buildQuickLinkCard(context, 'Messages', Icons.chat, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatScreen()))),
              _buildQuickLinkCard(context, 'AI Assistant', Icons.smart_toy, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AIChatScreen()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinkCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

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
