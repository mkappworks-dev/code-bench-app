import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/_core/http/dio_factory.dart';
import '../../../data/shared/ai_model.dart';
import '../../../data/shared/chat_message.dart';
import 'ai_remote_datasource.dart';

class OpenAIRemoteDatasourceDio implements AIRemoteDatasource {
  OpenAIRemoteDatasourceDio(String apiKey)
    : _dio = DioFactory.create(
        baseUrl: ApiConstants.openAiBaseUrl,
        headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
      );

  final Dio _dio;

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
            } on FormatException catch (_) {
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
  Future<bool> testConnection(AIModel model, String apiKey) async {
    try {
      final testDio = DioFactory.create(
        baseUrl: ApiConstants.openAiBaseUrl,
        headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
      );
      await testDio.get(ApiConstants.openAiModelsEndpoint);
      return true;
    } on DioException catch (e) {
      dLog('[OpenAIRemoteDatasource] testConnection failed: ${e.type} ${e.response?.statusCode}');
      return false;
    }
  }

  @override
  Future<List<AIModel>> fetchAvailableModels(String apiKey) async {
    try {
      final testDio = DioFactory.create(
        baseUrl: ApiConstants.openAiBaseUrl,
        headers: {'Authorization': 'Bearer $apiKey'},
      );
      final response = await testDio.get(ApiConstants.openAiModelsEndpoint);
      final data = response.data as Map<String, dynamic>;
      final models = (data['data'] as List)
          .map((m) => m['id'] as String)
          .where((id) => id.startsWith('gpt-'))
          .map((id) => AIModel(id: id, provider: AIProvider.openai, name: id, modelId: id))
          .toList();
      return models;
    } on DioException catch (e) {
      dLog('[OpenAIRemoteDatasource] fetchAvailableModels failed: ${e.type} ${e.response?.statusCode}');
      return AIModels.defaults.where((m) => m.provider == AIProvider.openai).toList();
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
