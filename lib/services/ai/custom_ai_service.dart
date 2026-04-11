import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../data/models/ai_model.dart';
import '../../data/models/chat_message.dart';
import 'ai_service.dart';

/// OpenAI-compatible AI service for custom endpoints (e.g. LM Studio, LocalAI).
class CustomAIService implements AIService {
  CustomAIService(this._baseUrl, this._apiKey);

  final String _baseUrl;
  final String _apiKey;

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {if (_apiKey.isNotEmpty) 'Authorization': 'Bearer $_apiKey', 'Content-Type': 'application/json'},
    ),
  );

  @override
  AIProvider get provider => AIProvider.custom;

  @override
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) async* {
    final messages = _buildMessages(history, prompt, systemPrompt);
    final body = {'model': model.modelId, 'messages': messages, 'stream': true};

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: body,
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data as ResponseBody;
      final buffer = StringBuffer();

      await for (final chunk in stream.stream) {
        buffer.write(utf8.decode(chunk));
        final raw = buffer.toString();
        buffer.clear();

        for (final line in raw.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.startsWith('data: ')) {
            final data = trimmed.substring(6);
            if (data == '[DONE]') return;
            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final delta = json['choices']?[0]?['delta']?['content'];
              if (delta is String && delta.isNotEmpty) {
                yield delta;
              }
            } catch (_) {
              // skip malformed lines
            }
          }
        }
      }
    } on DioException catch (e) {
      throw NetworkException(
        e.message ?? 'Custom endpoint request failed',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  @override
  Future<ChatMessage> sendMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) async {
    final sb = StringBuffer();
    await for (final chunk in streamMessage(
      history: history,
      prompt: prompt,
      model: model,
      systemPrompt: systemPrompt,
    )) {
      sb.write(chunk);
    }
    return ChatMessage(
      id: const Uuid().v4(),
      sessionId: history.isNotEmpty ? history.first.sessionId : '',
      role: MessageRole.assistant,
      content: sb.toString(),
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<bool> testConnection(AIModel model, String apiKey) async {
    try {
      await _dio.get('/models');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<AIModel>> fetchAvailableModels(String apiKey) async {
    try {
      final response = await _dio.get('/models');
      final data = response.data as Map<String, dynamic>;
      final models = (data['data'] as List)
          .map(
            (m) => AIModel(
              id: m['id'] as String,
              provider: AIProvider.custom,
              name: m['id'] as String,
              modelId: m['id'] as String,
            ),
          )
          .toList();
      return models;
    } catch (_) {
      return [];
    }
  }

  List<Map<String, String>> _buildMessages(List<ChatMessage> history, String prompt, String? systemPrompt) {
    final messages = <Map<String, String>>[];
    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    for (final msg in history) {
      messages.add({'role': msg.role.value, 'content': msg.content});
    }
    messages.add({'role': 'user', 'content': prompt});
    return messages;
  }
}
