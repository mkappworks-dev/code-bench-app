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
        // Redirects are disabled because a hostile endpoint could 302 us to an
        // internal host and we'd replay the Authorization header. The caller
        // typed this URL; we trust only that host.
        followRedirects: false,
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
    // NOTE: Unlike the cloud datasources (openai/anthropic/gemini) which still
    // swallow fetchAvailableModels errors, Ollama and Custom propagate typed
    // AppException subclasses so AvailableModelsNotifier can classify them
    // (auth vs unreachable vs malformed) in the picker. See
    // available_models_failure.dart.
    try {
      final response = await _dio.get('/models');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ParseException('Custom endpoint returned an unexpected payload (expected JSON object)');
      }
      final list = data['data'];
      if (list is! List) {
        throw const ParseException('Custom endpoint response is missing the "data" list');
      }
      final models = <AIModel>[];
      for (final entry in list) {
        if (entry is! Map) continue; // skip malformed entries; don't fail the whole list
        final id = entry['id'];
        if (id is! String || id.isEmpty) continue;
        models.add(AIModel(id: id, provider: AIProvider.custom, name: id, modelId: id));
      }
      return models;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      dLog('[CustomRemoteDatasource] fetchAvailableModels failed: ${e.type} ${status ?? ''}');
      if (status == 401 || status == 403) {
        throw AuthException('Custom endpoint rejected the API key', originalError: e);
      }
      throw NetworkException('Custom endpoint request failed', statusCode: status, originalError: e);
    } on ParseException {
      rethrow;
    } catch (e) {
      // Defensive: unexpected non-Dio, non-Parse error (e.g. a CastError from
      // some nested field). Log only the runtime type so we don't spill
      // response content.
      dLog('[CustomRemoteDatasource] fetchAvailableModels unexpected ${e.runtimeType}');
      throw ParseException('Malformed model list response', originalError: e);
    }
  }

  List<Map<String, String>> _buildMessages(List<ChatMessage> history, String prompt, String? systemPrompt) {
    final messages = <Map<String, String>>[];
    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    for (final msg in history.where((m) => m.role != MessageRole.interrupted)) {
      messages.add({'role': msg.role.value, 'content': msg.content});
    }
    messages.add({'role': 'user', 'content': prompt});
    return messages;
  }
}
