import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_final/services/gemini_service.dart';

class GeminiChatScreen extends StatefulWidget {
  static const routeName = '/gemini-chat';
  const GeminiChatScreen({super.key});

  @override
  State<GeminiChatScreen> createState() => _GeminiChatScreenState();
}

class _GeminiChatScreenState extends State<GeminiChatScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('gemini_api_key');
    });
  }

  Future<void> _setApiKey() async {
    final controller = TextEditingController(text: _apiKey ?? '');
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gemini API Key'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Paste API key here')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );

    if (res != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gemini_api_key', res);
      setState(() => _apiKey = res);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'from': 'user', 'text': text});
      _controller.clear();
      _loading = true;
    });

    try {
      if (_apiKey == null || _apiKey!.isEmpty) {
        await _setApiKey();
        if (_apiKey == null || _apiKey!.isEmpty) throw Exception('API key not set');
      }

      final service = GeminiService(apiKey: _apiKey!);
      final reply = await service.sendMessage(text);
      setState(() {
        _messages.add({'from': 'bot', 'text': reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({'from': 'bot', 'text': 'Error: ${e.toString()}'});
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Chat'),
        actions: [IconButton(icon: const Icon(Icons.vpn_key), onPressed: _setApiKey)],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final isUser = m['from'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Theme.of(context).colorScheme.primary : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(m['text'] ?? '', style: TextStyle(color: isUser ? Colors.white : Colors.black87)),
                  ),
                );
              },
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Send a message'))),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _loading ? null : _send, child: const Text('Send')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
