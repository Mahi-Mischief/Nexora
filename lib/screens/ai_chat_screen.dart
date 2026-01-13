import 'package:flutter/material.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _ctrl = TextEditingController();
  final List<Map<String, String>> _messages = [];

  void _ask() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _messages.add({'from': 'user', 'text': q});
      _messages.add({'from': 'bot', 'text': _mockResponse(q)});
      _ctrl.clear();
    });
  }

  String _mockResponse(String q) {
    final lq = q.toLowerCase();
    if (lq.contains('events')) return 'FBLA events include chapter meetings, competitions, and conferences. Check the calendar for dates.';
    if (lq.contains('how') && lq.contains('join')) return 'Contact your chapter officer or sponsor and attend the next meeting to join.';
    return 'Here is some information about FBLA: visit the Resources section for guides, or ask a more specific question.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nex')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m['from'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: isUser ? Colors.blueGrey : Colors.blueAccent, borderRadius: BorderRadius.circular(8)),
                    child: Text(m['text'] ?? ''),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'Ask about FBLA...'))),
                IconButton(onPressed: _ask, icon: const Icon(Icons.send)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
