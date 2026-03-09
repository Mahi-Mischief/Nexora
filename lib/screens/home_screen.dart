// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:nexora_final/screens/terms_screen.dart';
import 'package:nexora_final/screens/help_screen.dart';
import 'package:nexora_final/screens/teacher_events_screen.dart';
import 'package:nexora_final/screens/teacher_approvals_screen.dart';
import 'package:nexora_final/screens/teacher_students_screen.dart';
import 'package:nexora_final/screens/teacher_calendar_screen.dart';

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
  bool _termsAccepted = false;
  bool _termsPreferenceLoaded = false;
  String? _termsPreferenceKey;

  // final List<Widget> _pages = const [
  //   _HomeContent(),
  //   NexScreen(),
  //   EventsScreen(),
  //   ActivitiesScreen(),
  //   ResourcesScreen(),
  // ];

  List<Widget> _studentPages() => const [
    _HomeContent(),
    AIChatScreen(),
    EventsScreen(),
    ActivitiesScreen(),
    ResourcesScreen(),
  ];

  List<Widget> _teacherPages() => const [
    _HomeContent(),
    AIChatScreen(),
    TeacherEventsScreen(),
    TeacherApprovalsScreen(),
    TeacherStudentsScreen(),
    ResourcesScreen(),
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _setTermsAccepted(bool value) async {
    final key = _termsPreferenceKey;
    if (key != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    }

    if (!mounted) return;
    setState(() {
      _termsAccepted = value;
    });
  }

  Future<void> _loadTermsAcceptedForUser(int? userId) async {
    final nextKey = userId == null ? null : 'nexora_terms_accepted_user_$userId';
    if (_termsPreferenceLoaded && _termsPreferenceKey == nextKey) {
      return;
    }

    bool accepted = false;
    if (nextKey != null) {
      final prefs = await SharedPreferences.getInstance();
      accepted = prefs.getBool(nextKey) ?? false;
    }

    if (!mounted) return;
    setState(() {
      _termsPreferenceKey = nextKey;
      _termsPreferenceLoaded = true;
      _termsAccepted = accepted;
    });
  }

  void _ensureTermsLoadedForUser(int? userId) {
    final nextKey = userId == null ? null : 'nexora_terms_accepted_user_$userId';
    if (_termsPreferenceLoaded && _termsPreferenceKey == nextKey) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTermsAcceptedForUser(userId);
    });
  }

  Future<void> _openTermsPage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TermsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    _ensureTermsLoadedForUser(auth.user?.id);

    final isTeacher = auth.user?.role?.toLowerCase() == 'teacher';
    final pages = isTeacher ? _teacherPages() : _studentPages();
    if (_index >= pages.length) {
      _index = 0;
    }

    final showTermsBanner = _termsPreferenceLoaded && !_termsAccepted;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/Nexora_logo_no_name.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text('Nexora'),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HelpScreen())),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: pages[_index],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTermsBanner)
            Container(
              width: double.infinity,
              color: const Color(0xFFF8F8F8),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Please review and accept Terms and Conditions to continue using all features.',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _openTermsPage,
                        child: const Text(
                          'Terms and Conditions',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    value: _termsAccepted,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    checkColor: Colors.white,
                    activeColor: Colors.black,
                    title: const Text(
                      'I agree to the Terms and Conditions',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    side: const BorderSide(color: Colors.black, width: 1.1),
                    onChanged: (v) => _setTermsAccepted(v ?? false),
                  ),
                ],
              ),
            ),
          BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: isTeacher
                ? const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.smart_toy),
                      label: 'Nex AI',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.event_note),
                      label: 'Event Management',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.verified),
                      label: 'Approvals',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.school),
                      label: 'Students',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.folder),
                      label: 'Resources',
                    ),
                  ]
                : const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.smart_toy),
                      label: 'Nex',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.event),
                      label: 'Events',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.volunteer_activism),
                      label: 'Activities',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.folder),
                      label: 'Resources',
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent();

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent> {
  bool _loadingAnnouncements = false;
  String? _announcementsError;
  List<dynamic> _announcements = const [];
  String _loadedSchool = '';
  String? _pendingSchoolRefresh;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _loadingAnnouncements = true;
      _announcementsError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('nexora_token');
      final items = await AnnouncementService.fetchAnnouncements(token: token);
      if (!mounted) return;
      setState(() {
        _announcements = items;
        _loadingAnnouncements = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _announcementsError = e.toString().replaceFirst('Exception: ', '');
        _loadingAnnouncements = false;
      });
    }

    _runPendingSchoolRefresh();
  }

  void _runPendingSchoolRefresh() {
    final pending = _pendingSchoolRefresh;
    if (pending == null || pending == _loadedSchool || _loadingAnnouncements) {
      return;
    }

    _pendingSchoolRefresh = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncAnnouncementsForSchool(pending);
    });
  }

  void _syncAnnouncementsForSchool(String? schoolValue) {
    final school = (schoolValue ?? '').trim();

    if (school.isEmpty) {
      _loadedSchool = '';
      _pendingSchoolRefresh = null;
      return;
    }

    if (_loadedSchool == school && _pendingSchoolRefresh == null) {
      return;
    }

    if (_loadingAnnouncements) {
      _pendingSchoolRefresh = school;
      return;
    }

    _loadedSchool = school;
    _pendingSchoolRefresh = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadAnnouncements();
    });
  }

  Future<void> _createOrEditAnnouncement({
    Map<String, dynamic>? existing,
  }) async {
    final titleController = TextEditingController(
      text: existing?['title']?.toString() ?? '',
    );
    final contentController = TextEditingController(
      text: existing?['content']?.toString() ?? '',
    );
    final isEditing = existing != null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Announcement' : 'Create Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Content'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isEditing ? 'Save' : 'Create'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final title = titleController.text.trim();
    final content = contentController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('nexora_token');
      if (isEditing) {
        final id = existing['id'] as int;
        await AnnouncementService.updateAnnouncement(
          id: id,
          title: title,
          content: content,
          token: token,
        );
      } else {
        await AnnouncementService.createAnnouncement(
          title: title,
          content: content,
          token: token,
        );
      }
      if (!mounted) return;
      await _loadAnnouncements();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _deleteAnnouncement(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text(
          'Are you sure you want to delete this announcement?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('nexora_token');
      final id = item['id'] as int;
      await AnnouncementService.deleteAnnouncement(id: id, token: token);
      if (!mounted) return;
      await _loadAnnouncements();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _buildAnnouncementsList({
    required bool hasSchool,
    required bool isTeacher,
  }) {
    if (!hasSchool) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Add more profile information to access announcements'),
        ),
      );
    }

    if (_loadingAnnouncements) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_announcementsError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_announcementsError!),
        ),
      );
    }

    if (_announcements.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No announcements yet for your school.'),
        ),
      );
    }

    return Column(
      children: _announcements.map((raw) {
        final item = raw as Map<String, dynamic>;
        final title = item['title']?.toString() ?? 'Announcement';
        final content = item['content']?.toString() ?? '';
        final createdAt = item['created_at']?.toString() ?? '';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isTeacher) ...[
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () =>
                            _createOrEditAnnouncement(existing: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _deleteAnnouncement(item),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(content),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    createdAt,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInstagramFeed() {
    final posts = [
      {
        'handle': 'fbla_national',
        'caption':
            'National Officer Interest Webinar: FBLA Collegiate members can learn about serving as a National Officer on April 1 at 6PM ET. Register through the Linktree in bio.',
        'url': 'https://www.instagram.com/p/DVmFJtwE1GH/',
      },
      {
        'handle': 'fbla_national',
        'caption':
            'State Leadership Conference Reel Competition is live. Vlog your SLC and submit the form in bio for a chance to be featured on FBLA National.',
        'url': 'https://www.instagram.com/p/DVhT7H2EgtU/?img_index=1',
      },
      {
        'handle': 'fbla_national',
        'caption':
            'FBLA celebrates the ACTE Outstanding Student Business Award recipients for representing the organization with excellence. #MakeYourMark',
        'url': 'https://www.instagram.com/p/DVhGMtYkhnH/?img_index=1',
      },
    ];

    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final post = posts[index];
          final url = post['url']!;

          return SizedBox(
            width: 320,
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openInstagramPost(url),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/fbla_logo.png',
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              post['handle']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Text(
                          post['caption']!,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tap card to open on Instagram',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openInstagramPost(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Instagram post.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isTeacher = user?.role?.toLowerCase() == 'teacher';
    final hasSchool = (user?.school?.trim().isNotEmpty ?? false);

    _syncAnnouncementsForSchool(user?.school);

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
              if (isTeacher && hasSchool)
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () => _createOrEditAnnouncement(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAnnouncementsList(hasSchool: hasSchool, isTeacher: isTeacher),
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
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${user?.firstName ?? 'Student'} ${user?.lastName ?? ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.school,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(user?.school ?? 'No school set'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.email,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(user?.email ?? 'No email'),
                    ],
                  ),
                  if (user?.grade != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.class_,
                          color: Theme.of(context).colorScheme.primary,
                        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Calendar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (isTeacher)
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TeacherCalendarScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Manage Events'),
                ),
            ],
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
  DateTime _selectedDay = DateTime.now();

  DateTime _dayKey(DateTime day) => DateTime(day.year, day.month, day.day);

  String _labelForSelectedDay() {
    final today = _dayKey(DateTime.now());
    final selected = _dayKey(_selectedDay);
    if (isSameDay(today, selected)) return "Today's Events";
    return 'Events for ${selected.month}/${selected.day}/${selected.year}';
  }

  void _showEventDetails(Map<String, dynamic> event) {
    final title = event['title']?.toString().trim();
    final description = event['description']?.toString().trim();
    final brief = (description == null || description.isEmpty)
        ? 'No description available for this event.'
        : description;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text((title == null || title.isEmpty) ? 'Event Details' : title),
        content: Text(brief),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

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

        final selectedEvents = eventsMap[_dayKey(_selectedDay)] ?? const [];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                  eventLoader: (day) => eventsMap[_dayKey(day)] ?? [],
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  _labelForSelectedDay(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (selectedEvents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No events scheduled for this date.'),
                  )
                else
                  ListView.separated(
                    itemCount: selectedEvents.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final event =
                          selectedEvents[index] as Map<String, dynamic>;
                      final title =
                          event['title']?.toString() ?? 'Untitled event';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(title),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showEventDetails(event),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
