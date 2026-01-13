import 'package:flutter/material.dart';

class NexScreen extends StatefulWidget {
  const NexScreen({super.key});

  @override
  State<NexScreen> createState() => _NexScreenState();
}

class _NexScreenState extends State<NexScreen> {
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
    if (lq.contains('competition')) return 'FBLA offers various competitive events. Visit the Events tab to see upcoming competitions and sign up!';
    if (lq.contains('volunteer')) return 'Check the Activities tab to log your volunteering hours and see available opportunities.';
    return 'Here is some information about FBLA: visit the Resources section for guides, or ask a more specific question.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nex')),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.smart_toy, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'Hi! I\'m Nex, your FBLA assistant',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask me anything about FBLA!',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final isUser = m['from'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                          child: Text(
                            m['text'] ?? '',
                            style: TextStyle(
                              color: isUser ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Ask Nex...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _ask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _ask,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
