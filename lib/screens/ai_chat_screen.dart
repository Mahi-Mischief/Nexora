import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _ctrl = TextEditingController();
  final List<Map<String, String>> _messages = [];
  // Update this to your backend URL that proxies to Gemini/Vertex AI.
  // When running on Android emulator, use 10.0.2.2 to reach the host machine.
  static const _backendUrl = 'http://10.0.2.2:3000/ai/generate';

  void _ask() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _messages.add({'from': 'user', 'text': q});
      _messages.add({'from': 'bot', 'text': '...'}); // placeholder while loading
      _ctrl.clear();
    });

    final responseText = await _generateResponse(q);

    setState(() {
      // Replace last bot message (the placeholder) with real response
      for (var i = _messages.length - 1; i >= 0; --i) {
        if (_messages[i]['from'] == 'bot') {
          _messages[i] = {'from': 'bot', 'text': responseText};
          break;
        }
      }
    });
  }

  String _mockResponse(String q) {
    final lq = q.toLowerCase();
    if (lq.contains('events')) return 'FBLA events include chapter meetings, competitions, and conferences. Check the calendar for dates.';
    if (lq.contains('how') && lq.contains('join')) return 'Contact your chapter officer or sponsor and attend the next meeting to join.';
    return 'Here is some information about FBLA: visit the Resources section for guides, or ask a more specific question.';
  }

  Future<String> _generateResponse(String prompt) async {
    try {
      final res = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        // Expect backend to return JSON like: { text: '...' }
        return (body['text'] as String?) ?? 'No response from AI';
      }

      return 'AI error: ${res.statusCode}';
    } catch (e) {
      return 'Failed to reach AI service: $e';
    }
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
