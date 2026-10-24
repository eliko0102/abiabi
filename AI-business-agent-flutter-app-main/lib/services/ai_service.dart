import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Assistant reply plus the deterministic follow-up chips the backend builds
/// for the current 2GIS analysis.
class AiChatReply {
  const AiChatReply({
    required this.message,
    this.followUps = const [],
    this.analysisUsed = false,
    this.analysisAddress,
    this.failed = false,
  });

  final String message;
  final List<String> followUps;
  final bool analysisUsed;
  final String? analysisAddress;
  final bool failed;
}

class AiService {
  late String _authToken;

  AiService({String? authToken}) {
    _authToken = authToken ?? '';
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Sends the prompt together with the attached 2GIS analysis and the recent
  /// conversation, so follow-up questions stay grounded in the same report.
  Future<AiChatReply> chat({
    required String prompt,
    Map<String, dynamic>? locationContext,
    String language = 'az',
    List<Map<String, String>> conversation = const [],
  }) async {
    final normalizedPrompt = prompt.trim();
    if (normalizedPrompt.isEmpty) {
      return AiChatReply(
        message: _message(language, 'emptyPrompt'),
        failed: true,
      );
    }

    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (_authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_authToken';
      }
      final response = await http
          .post(
            Uri.parse('${ApiConfig.backendUrl}/api/chat'),
            headers: headers,
            body: jsonEncode({
              'prompt': normalizedPrompt,
              'language': language,
              'conversation': conversation,
              if (locationContext != null) 'analysis_context': locationContext,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final message =
              decoded['message']?.toString() ??
              decoded['response']?.toString() ??
              '';
          final rawFollowUps = decoded['follow_ups'];
          return AiChatReply(
            message: message.isEmpty ? 'No response received.' : message,
            followUps: rawFollowUps is List
                ? rawFollowUps
                      .map((item) => item.toString())
                      .where((item) => item.trim().isNotEmpty)
                      .toList()
                : const [],
            analysisUsed: decoded['analysis_used'] == true,
            analysisAddress: decoded['analysis_address']?.toString(),
          );
        }
        return AiChatReply(message: decoded.toString());
      } else if (response.statusCode == 401) {
        return AiChatReply(
          message: _message(language, 'sessionExpired'),
          failed: true,
        );
      }
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final message = decoded['message']?.toString();
          final error = decoded['error']?.toString();
          if (message != null && message.isNotEmpty) {
            return AiChatReply(
              message: error == null || error.isEmpty
                  ? message
                  : '$message: $error',
              failed: true,
            );
          }
        }
      } catch (_) {
        // Fall through to the status code when the server did not return JSON.
      }
      return AiChatReply(
        message:
            '${_message(language, 'serverError')} (${response.statusCode})',
        failed: true,
      );
    } catch (e) {
      return AiChatReply(
        message: '${_message(language, 'connectionError')}: $e',
        failed: true,
      );
    }
  }

  Future<String> generateResponse(
    String prompt, {
    Map<String, dynamic>? locationContext,
    String language = 'az',
  }) async {
    final reply = await chat(
      prompt: prompt,
      locationContext: locationContext,
      language: language,
    );
    return reply.message;
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
