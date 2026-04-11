import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../data/models/ai_model.dart';
import '../../data/models/chat_message.dart';
import 'ai_service.dart';

class OllamaService implements AIService {
  OllamaService(this._baseUrl);

  final String _baseUrl;
  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
    ),
  );

  @override
  AIProvider get provider => AIProvider.ollama;

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
        ApiConstants.ollamaChatEndpoint,
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
          if (trimmed.isEmpty) continue;
          try {
            final json = jsonDecode(trimmed) as Map<String, dynamic>;
            final content = json['message']?['content'];
            if (content is String && content.isNotEmpty) {
              yield content;
            }
          } catch (_) {}
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('Ollama is not running. Start it with: ollama serve', originalError: e);
      }
      throw NetworkException(
        e.message ?? 'Ollama request failed',
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
    final buffer = StringBuffer();
    await for (final chunk in streamMessage(
      history: history,
      prompt: prompt,
      model: model,
      systemPrompt: systemPrompt,
    )) {
      buffer.write(chunk);
    }
    return ChatMessage(
      id: const Uuid().v4(),
      sessionId: history.isNotEmpty ? history.first.sessionId : '',
      role: MessageRole.assistant,
      content: buffer.toString(),
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<bool> testConnection(AIModel model, String apiKey) async {
    try {
      await _dio.get(ApiConstants.ollamaTagsEndpoint);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<AIModel>> fetchAvailableModels(String apiKey) async {
    try {
      final response = await _dio.get(ApiConstants.ollamaTagsEndpoint);
      final data = response.data as Map<String, dynamic>;
      final models = (data['models'] as List? ?? []).map((m) {
        final name = m['name'] as String;
        return AIModel(
          id: 'ollama_$name',
          provider: AIProvider.ollama,
          name: name,
          modelId: name,
          supportsStreaming: true,
        );
      }).toList();
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
