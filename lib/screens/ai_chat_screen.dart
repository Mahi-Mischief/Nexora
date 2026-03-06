import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _ctrl = TextEditingController();

  final List<Map<String, String>> _messages = [];

  // 🔑 Replace with your NEW Gemini API key
  static const String apiKey = "AIzaSyCDcboZEo2ggVhdZbojzSp948f6Jc0XmrU";

//   static const String geminiUrl =
//       "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey";
      static const String geminiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey";


  void _ask() async {
    final q = _ctrl.text.trim();

    if (q.isEmpty) return;

    setState(() {
      _messages.add({'from': 'user', 'text': q});
      _messages.add({'from': 'bot', 'text': 'Thinking...'});
    });

    _ctrl.clear();

    await Future.delayed(const Duration(seconds: 2));

    final responseText = await _generateResponse(q);

    setState(() {
      for (var i = _messages.length - 1; i >= 0; --i) {
        if (_messages[i]['from'] == 'bot') {
          _messages[i] = {'from': 'bot', 'text': responseText};
          break;
        }
      }
    });
  }

  Future<String> _generateResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(geminiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data["candidates"][0]["content"]["parts"][0]["text"];
      }

      // Handle quota exceeded
      if (response.statusCode == 429) {
        await Future.delayed(const Duration(seconds: 10));
        return "Quota limit reached. Please wait a moment and try again.";
      }

      return "AI Error ${response.statusCode}";
    } catch (e) {
      return "Error: $e";
    }
  }

  Widget _chatBubble(Map<String, String> message) {
    final isUser = message['from'] == 'user';

    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueGrey : Colors.blueAccent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          message['text'] ?? '',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nex AI")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _chatBubble(_messages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: "Ask Gemini...",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _ask,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}