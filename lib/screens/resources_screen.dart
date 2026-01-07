import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  Future<void> _openLink(String url) async {
    final u = Uri.parse(url);
    if (await canLaunchUrl(u)) await launchUrl(u);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resources')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              title: const Text('FBLA Handbook (PDF)'),
              trailing: const Icon(Icons.picture_as_pdf),
              onTap: () => _openLink('https://www.fbla-pbl.org/'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Competition Guidelines'),
              onTap: () => _openLink('https://www.fbla-pbl.org/competitions/'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Chapter Documents'),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
