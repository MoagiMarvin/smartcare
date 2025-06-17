import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatService {
  static const String _apiKey = 'YOUR_OPENAI_API_KEY_HERE'; // Replace with your actual API key
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  static Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful healthcare assistant for the SmartCare app. Provide helpful, accurate, and supportive health information. Always remind users to consult healthcare professionals for serious concerns. Keep responses concise and friendly.'
            },
            {
              'role': 'user',
              'content': message,
            }
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        return 'Sorry, I\'m having trouble connecting right now. Please try again later.';
      }
    } catch (e) {
      return 'Sorry, I encountered an error. Please check your internet connection and try again.';
    }
  }
}
