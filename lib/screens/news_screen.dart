import 'package:flutter/material.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('News')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: List.generate(
          6,
          (i) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Announcement ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('This is a sample announcement for demo purposes.'),
                  const SizedBox(height: 6),
                  Text('${DateTime.now().subtract(Duration(hours: i * 3))}'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
