import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../data/models/ai_model.dart';
import '../../data/models/chat_message.dart';
import 'ai_service.dart';

class OpenAIService implements AIService {
  OpenAIService(this._apiKey);

  final String _apiKey;
  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.openAiBaseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
    ),
  );

  @override
  AIProvider get provider => AIProvider.openai;

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
        ApiConstants.openAiChatEndpoint,
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
        e.message ?? 'OpenAI request failed',
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
      final testDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.openAiBaseUrl,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );
      await testDio.get(ApiConstants.openAiModelsEndpoint);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<AIModel>> fetchAvailableModels(String apiKey) async {
    try {
      final testDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.openAiBaseUrl,
          headers: {'Authorization': 'Bearer $apiKey'},
        ),
      );
      final response = await testDio.get(ApiConstants.openAiModelsEndpoint);
      final data = response.data as Map<String, dynamic>;
      final models = (data['data'] as List)
          .map((m) => m['id'] as String)
          .where((id) => id.startsWith('gpt-'))
          .map(
            (id) => AIModel(
              id: id,
              provider: AIProvider.openai,
              name: id,
              modelId: id,
            ),
          )
          .toList();
      return models;
    } catch (_) {
      return AIModels.defaults.where((m) => m.provider == AIProvider.openai).toList();
    }
  }

  List<Map<String, String>> _buildMessages(
    List<ChatMessage> history,
    String prompt,
    String? systemPrompt,
  ) {
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
