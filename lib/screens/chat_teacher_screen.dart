import 'package:flutter/material.dart';

// Simple teacher view to approve/reject requests sent by students.
class ChatTeacherScreen extends StatefulWidget {
  const ChatTeacherScreen({super.key});

  @override
  State<ChatTeacherScreen> createState() => _ChatTeacherScreenState();
}

class _ChatTeacherScreenState extends State<ChatTeacherScreen> {
  final List<Map<String, String>> _requests = [
    {'id': 'r1', 'student': 'student01', 'text': 'Request to join competition', 'status': 'pending'},
  ];

  void _decide(String id, String decision) {
    setState(() {
      final idx = _requests.indexWhere((e) => e['id'] == id);
      if (idx >= 0) _requests[idx]['status'] = decision;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Requests')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _requests.length,
        itemBuilder: (context, i) {
          final r = _requests[i];
          return Card(
            child: ListTile(
              title: Text(r['text'] ?? ''),
              subtitle: Text('From: ${r['student']} — Status: ${r['status']}'),
              trailing: r['status'] == 'pending'
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _decide(r['id']!, 'approved')),
                      IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _decide(r['id']!, 'rejected')),
                    ])
                  : null,
            ),
          );
        },
      ),
    );
  }
}
