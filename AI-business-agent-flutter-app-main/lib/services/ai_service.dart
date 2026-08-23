import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AiService {
  late String _authToken;

  AiService({String? authToken}) {
    _authToken = authToken ?? '';
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  Future<String> generateResponse(
    String prompt, {
    Map<String, dynamic>? locationContext,
    String language = 'az',
  }) async {
    final normalizedPrompt = prompt.trim();
    if (normalizedPrompt.isEmpty) {
      return _message(language, 'emptyPrompt');
    }

    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (_authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_authToken';
      }
      final response = await http.post(
        Uri.parse('${ApiConfig.backendUrl}/api/chat'),
        headers: headers,
        body: jsonEncode({
          'prompt': normalizedPrompt,
          'language': language,
          if (locationContext != null) 'location_context': locationContext,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded['message']?.toString() ??
              decoded['response']?.toString() ??
              'No response received.';
        }
        return decoded.toString();
      } else if (response.statusCode == 401) {
        return _message(language, 'sessionExpired');
      }
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final message = decoded['message']?.toString();
          final error = decoded['error']?.toString();
          if (message != null && message.isNotEmpty) {
            return error == null || error.isEmpty
                ? message
                : '$message: $error';
          }
        }
      } catch (_) {
        // Fall through to the status code when the server did not return JSON.
      }
      return '${_message(language, 'serverError')} (${response.statusCode})';
    } catch (e) {
      return '${_message(language, 'connectionError')}: $e';
    }
  }

  String _message(String language, String key) {
    const messages = {
      'az': {
        'emptyPrompt': 'AI assistentə sualınızı yazın.',
        'sessionExpired': 'Sessiya bitib. Yenidən daxil olun.',
        'serverError': 'AI server xətası',
        'connectionError': 'AI serverə qoşulmaq mümkün olmadı',
      },
      'en': {
        'emptyPrompt': 'Please enter a request for the AI assistant.',
        'sessionExpired': 'Session expired. Please log in again.',
        'serverError': 'AI server error',
        'connectionError': 'Could not connect to the AI server',
      },
      'ru': {
        'emptyPrompt': 'Введите запрос для AI-ассистента.',
        'sessionExpired': 'Сессия завершена. Войдите снова.',
        'serverError': 'Ошибка AI-сервера',
        'connectionError': 'Не удалось подключиться к AI-серверу',
      },
      'kk': {
        'emptyPrompt': 'AI көмекшіге сұрағыңызды жазыңыз.',
        'sessionExpired': 'Сессия аяқталды. Қайта кіріңіз.',
        'serverError': 'AI сервер қатесі',
        'connectionError': 'AI серверіне қосылу мүмкін болмады',
      },
    };
    return messages[language]?[key] ?? messages['az']![key]!;
  }
}
