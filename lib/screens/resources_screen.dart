import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  Future<void> _openLink(String url) async {
    final u = Uri.parse(url);
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _linkCard({
    required String title,
    required String url,
    IconData icon = Icons.open_in_new,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(url),
        trailing: Icon(icon),
        onTap: () => _openLink(url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resources')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _sectionTitle('FBLA Resources'),
          _linkCard(
            title: 'Calendar at a Glance',
            url:
                'https://www.fbla.org/media/2025/08/2025-2026-FBLA-Schedule-at-a-Glance.pdf',
            icon: Icons.picture_as_pdf,
          ),
          _linkCard(
            title: 'FBLA High School Handbook',
            url:
                'https://connect.fbla.org/login.php?action=getfromstorage&systemFolder=files&id=6847',
            icon: Icons.menu_book,
          ),
          _linkCard(
            title: 'FBLA Website',
            url: 'https://www.fbla.org/',
            icon: Icons.language,
          ),
          _linkCard(
            title: 'About FBLA',
            url: 'https://www.fbla.org/about/',
            icon: Icons.info_outline,
          ),
          _sectionTitle('App Resources'),
          _linkCard(
            title: 'App Demo and User Guide',
            url:
                'https://docs.google.com/document/d/1OgXuqGZlsja6yN0yE2g90vQoN_oYdoGqmy4jIuhEmlc/edit?usp=sharing',
            icon: Icons.slideshow,
          ),
          _linkCard(
            title: 'Technical Documentation',
            url:
                'https://docs.google.com/document/d/1lH7lKRe2PaiT48mCIyN62C2KRvtNa34pRSuGHbbxOx0/edit?usp=sharing',
            icon: Icons.description,
          ),
        ],
      ),
    );
  }
}
