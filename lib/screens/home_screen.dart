// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nexora_final/services/announcement_service.dart';
import 'package:nexora_final/services/instagram_service.dart';
import 'package:nexora_final/providers/auth_provider.dart';
import 'package:nexora_final/screens/calendar_screen.dart';
import 'package:nexora_final/screens/events_screen.dart';
import 'package:nexora_final/screens/resources_screen.dart';
import 'package:nexora_final/screens/chat_screen.dart';
import 'package:nexora_final/screens/ai_chat_screen.dart';
import 'package:nexora_final/widgets/app_drawer.dart';
import 'package:nexora_final/screens/help_screen.dart';
import 'package:nexora_final/screens/activities_screen.dart';

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
            Icon(Icons.school, size: 28, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 8),
            const Text('NEXORA'),
          ],
        ),
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
        actions: [IconButton(icon: const Icon(Icons.help_outline), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpScreen())))],
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

  /// Launch Instagram post or profile
  Future<void> _launchInstagram(String? url) async {
    if (url == null || url.isEmpty) {
      // Fallback to FBLA National Instagram profile
      url = 'https://www.instagram.com/fbla_national/';
    }

    try {
      // Try to open in Instagram app first
      final instagramUrl = Uri.parse(url.replaceFirst('https://www.instagram.com', 'instagram://user').replaceFirst('https://instagram.com', 'instagram://user'));
      if (await canLaunchUrl(instagramUrl)) {
        await launchUrl(instagramUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web browser
        final webUrl = Uri.parse(url);
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('Error launching Instagram: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
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
                children: [
                  const Text('Student Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Name: ${user?.firstName ?? user?.username ?? '—'}'),
                  const SizedBox(height: 4),
                  Text('School: ${user?.school ?? '—'}'),
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
                      onTap: () {},
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('FBLA Instagram', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('View All'),
                onPressed: () => _launchInstagram('https://www.instagram.com/fbla_national/'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<InstagramPost>>(
            future: InstagramService.fetchInstagramPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.camera_alt, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No Instagram posts available',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Show only the first 3 posts as preview
              final posts = snapshot.data!.take(3).toList();
              return Card(
                child: Column(
                  children: [
                    // Horizontal scrollable preview of post thumbnails
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(12),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return GestureDetector(
                            onTap: () => _launchInstagram(post.permalink),
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Thumbnail image
                                  Container(
                                    width: 120,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          post.mediaUrl.startsWith('assets/')
                                              ? Image.asset(
                                                  post.mediaUrl,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.white,
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.image_outlined,
                                                          size: 32,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Image.network(
                                                  post.mediaUrl,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Center(
                                                      child: CircularProgressIndicator(
                                                        value: loadingProgress.expectedTotalBytes != null
                                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                            : null,
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.grey[200],
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(
                                                            post.mediaType == 'VIDEO' ? Icons.play_circle_outline : Icons.image_outlined,
                                                            size: 32,
                                                            color: Colors.grey[600],
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            'FBLA',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Colors.grey[600],
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                          // Overlay gradient for better text readability
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              height: 30,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                  colors: [
                                                    Colors.black.withOpacity(0.3),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Caption preview (2 lines max)
                                  Expanded(
                                    child: Text(
                                      post.caption,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 10, height: 1.2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    // "View on Instagram" button
                    InkWell(
                      onTap: () => _launchInstagram('https://www.instagram.com/fbla_national/'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 20, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'View All Posts on Instagram',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.open_in_new, size: 16, color: Colors.blue[700]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
