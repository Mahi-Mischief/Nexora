import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nexora_final/services/api.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [];


  void _ask() async {
    final q = _ctrl.text.trim();

    if (q.isEmpty) return;

    setState(() {
      _messages.add({'from': 'user', 'text': q});
      _messages.add({'from': 'bot', 'text': 'Thinking...'});
    });

    _ctrl.clear();
  _scrollToBottom();

    final responseText = await _generateResponse(q);

    setState(() {
      for (var i = _messages.length - 1; i >= 0; --i) {
        if (_messages[i]['from'] == 'bot') {
          _messages[i] = {'from': 'bot', 'text': responseText};
          break;
        }
      }
    });

    _scrollToBottom();
  }

  Future<String> _generateResponse(String prompt) async {
    try {
      final response = await Api.post('/ai/generate', body: {"prompt": prompt});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["text"] ?? "No response from AI.";
      }

      final body = jsonDecode(response.body);
      return body["error"] ?? "AI Error ${response.statusCode}";
    } catch (e) {
      return "Network error: $e\nBase URL: ${Api.baseUrl}\nIf this is wrong, launch with --dart-define=API_BASE_URL=http://<your-backend-host>:3000";
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
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
        child: SelectableText(
          message['text'] ?? '',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nex AI")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _chatBubble(_messages[index]);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color.fromARGB(255, 29, 24, 62),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: "Ask AI...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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