// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_final/services/announcement_service.dart';
import 'package:nexora_final/providers/auth_provider.dart';
import 'package:nexora_final/screens/calendar_screen.dart';
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
    NewsScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'News'),
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

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Student Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Name: —'),
                  SizedBox(height: 4),
                  Text('School: —'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('FBLA Information'),
              subtitle: const Text('Chapter, Officers, How to get involved'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('FBLA Events'),
              subtitle: const Text('Upcoming competitions and meetings'),
              trailing: const Icon(Icons.event),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<dynamic>>(
            future: () async {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('nexora_token');
              return AnnouncementService.fetchAnnouncements(token: token);
            }(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final items = snapshot.data ?? [];
              return Column(
                children: items.map((item) {
                  final title = item['title'] ?? 'Announcement';
                  final content = item['content'] ?? '';
                  return Card(
                    child: ListTile(
                      title: Text(title),
                      subtitle: Text(content),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewsScreen())),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('FBLA Social'),
              subtitle: const Text('Instagram / X chapter feed'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResourcesScreen())),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalendarScreen())), child: const Text('Open Calendar'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatScreen())), child: const Text('Messages'))),
            ],
          ),
          const SizedBox(height: 20),
          const Text('AI Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AIChatScreen())), child: const Text('Ask NEXORA'))
        ],
      ),
    );
  }
}
