import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_final/services/announcement_service.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('News')),
      body: FutureBuilder<List<dynamic>>(
        future: () async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('nexora_token');
          return AnnouncementService.fetchAnnouncements(token: token);
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(12),
            children: items.map((item) {
              final title = item['title'] ?? 'Announcement';
              final content = item['content'] ?? '';
              final ts = item['created_at'] ?? item['createdAt'] ?? '';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(content),
                      const SizedBox(height: 6),
                      Align(alignment: Alignment.bottomRight, child: Text(ts.toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
