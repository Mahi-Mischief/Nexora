import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey;
  final String endpoint;

  GeminiService({required this.apiKey, this.endpoint = 'https://api.your-gemini-endpoint.example/v1/generate'});

  /// Sends a prompt to the Gemini-style endpoint and returns the text response.
  /// The shape of responses from different Gemini endpoints varies, so this
  /// implementation tries a few common keys.
  Future<String> sendMessage(String prompt) async {
    final uri = Uri.parse(endpoint);
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({'prompt': prompt}),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Gemini API error: ${resp.statusCode} ${resp.body}');
    }

    final body = resp.body;
    final data = jsonDecode(body);

    if (data is Map) {
      if (data['output'] != null) return data['output'].toString();
      if (data['response'] != null) return data['response'].toString();
      if (data['candidates'] != null && data['candidates'] is List) {
        final first = data['candidates'][0];
        if (first is Map && first['content'] != null) return first['content'].toString();
        return first.toString();
      }
      return data.toString();
    }

    return body;
  }
}
