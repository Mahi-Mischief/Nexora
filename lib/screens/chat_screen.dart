import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_final/services/message_service.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> _messages = [];
  final _ctrl = TextEditingController();

  void _send({String type = 'message'}) async {
    if (_ctrl.text.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('nexora_token');
    // demo: send to admin user id 1 if available
    final toUserId = 1;
    final content = _ctrl.text.trim();
    final res = await MessageService.sendMessage(toUserId: toUserId, content: content, token: token, type: type);
    setState(() {
      if (res != null) {
        _messages.add({'from': 'me', 'text': res['content'] ?? content, 'type': res['type'] ?? type, 'status': res['status'] ?? 'sent'});
      } else {
        _messages.add({'from': 'me', 'text': content, 'type': type, 'status': 'failed'});
      }
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return Align(
                  alignment: m['from'] == 'me' ? Alignment.centerRight : Alignment.centerLeft,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['text'] ?? ''),
                          if (m['type'] == 'request') Text('Status: ${m['status']}', style: const TextStyle(fontSize: 12, color: Colors.yellow)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'Message'))),
                IconButton(onPressed: () => _send(), icon: const Icon(Icons.send)),
                IconButton(onPressed: () => _send(type: 'request'), icon: const Icon(Icons.pending_actions)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
