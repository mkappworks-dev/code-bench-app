import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/_core/http/dio_factory.dart';
import '../../../data/shared/ai_model.dart';
import '../../../data/shared/chat_message.dart';
import 'ai_remote_datasource.dart';

class AnthropicRemoteDatasourceDio implements AIRemoteDatasource {
  AnthropicRemoteDatasourceDio(String apiKey)
    : _dio = DioFactory.create(
        baseUrl: ApiConstants.anthropicBaseUrl,
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': ApiConstants.anthropicVersion,
          'content-type': 'application/json',
        },
      );

  final Dio _dio;

  @override
  AIProvider get provider => AIProvider.anthropic;

  @override
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) async* {
    final messages = _buildMessages(history, prompt);
    final body = <String, dynamic>{'model': model.modelId, 'max_tokens': 4096, 'messages': messages, 'stream': true};
    if (systemPrompt != null) {
      body['system'] = systemPrompt;
    }

    try {
      final response = await _dio.post(
        ApiConstants.anthropicChatEndpoint,
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
            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              if (json['type'] == 'content_block_delta') {
                final delta = json['delta']?['text'];
                if (delta is String && delta.isNotEmpty) {
                  yield delta;
                }
              }
            } on FormatException catch (_) {}
          }
        }
      }
    } on DioException catch (e) {
      throw NetworkException(
        e.message ?? 'Anthropic request failed',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  @override
  Future<bool> testConnection(AIModel model, String apiKey) async {
    try {
      final testDio = DioFactory.create(
        baseUrl: ApiConstants.anthropicBaseUrl,
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': ApiConstants.anthropicVersion,
          'content-type': 'application/json',
        },
      );
      await testDio.post(
        ApiConstants.anthropicChatEndpoint,
        data: {
          'model': model.modelId,
          'max_tokens': 1,
          'messages': [
            {'role': 'user', 'content': 'hi'},
          ],
        },
      );
      return true;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) return true;
      return false;
    }
  }

  @override
  Future<List<AIModel>> fetchAvailableModels(String apiKey) {
    return Future.value(AIModels.defaults.where((m) => m.provider == AIProvider.anthropic).toList());
  }

  List<Map<String, String>> _buildMessages(List<ChatMessage> history, String prompt) {
    final messages = <Map<String, String>>[];
    for (final msg in history.where((m) => m.role != MessageRole.system)) {
      messages.add({'role': msg.role.value, 'content': msg.content});
    }
    messages.add({'role': 'user', 'content': prompt});
    return messages;
  }
}
