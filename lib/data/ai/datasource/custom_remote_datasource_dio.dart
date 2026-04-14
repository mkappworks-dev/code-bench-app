import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/_core/http/dio_factory.dart';
import '../../../data/shared/ai_model.dart';
import '../../../data/shared/chat_message.dart';
import 'ai_remote_datasource.dart';

/// OpenAI-compatible AI datasource for custom endpoints (e.g. LM Studio, LocalAI).
class CustomRemoteDatasourceDio implements AIRemoteDatasource {
  CustomRemoteDatasourceDio({required String endpoint, required String apiKey})
    : _dio = DioFactory.create(
        baseUrl: endpoint,
        headers: {if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
      );

  final Dio _dio;

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
            } on FormatException catch (_) {
              // skip malformed lines
            }
          }
        }
      }
    } on DioException catch (e) {
      throw NetworkException('Custom endpoint request failed', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  @override
  Future<bool> testConnection(AIModel model, String apiKey) async {
    try {
      await _dio.get('/models');
      return true;
    } on DioException catch (e) {
      dLog('[CustomRemoteDatasource] testConnection failed: ${e.type} ${e.response?.statusCode}');
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
    } on DioException catch (e) {
      dLog('[CustomRemoteDatasource] fetchAvailableModels failed: ${e.type} ${e.response?.statusCode}');
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
