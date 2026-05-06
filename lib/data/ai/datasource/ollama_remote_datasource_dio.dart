import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/_core/http/dio_factory.dart';
import '../../../data/shared/ai_model.dart';
import '../../../data/shared/chat_message.dart';
import '../../../data/shared/session_settings.dart';
import '../models/provider_capabilities.dart';
import '../models/provider_turn_settings.dart';
import '../util/setting_mappers.dart';
import 'ai_remote_datasource.dart';
import 'text_streaming_datasource.dart';

class OllamaRemoteDatasourceDio implements AIRemoteDatasource, TextStreamingDatasource {
  OllamaRemoteDatasourceDio(String baseUrl)
    : _dio = DioFactory.create(
        baseUrl: baseUrl,
        // See CustomRemoteDatasourceDio for the redirect-replay rationale.
        followRedirects: false,
      );

  final Dio _dio;

  @override
  AIProvider get provider => AIProvider.ollama;

  @override
  ProviderCapabilities capabilitiesFor(AIModel model) => const ProviderCapabilities(
    supportsModelOverride: true,
    supportsSystemPrompt: true,
    supportedModes: {ChatMode.chat},
    supportedEfforts: {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max},
    supportedPermissions: <ChatPermission>{},
  );

  @override
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
    ProviderTurnSettings? settings,
  }) async* {
    final messages = _buildMessages(history, prompt, systemPrompt);
    final body = <String, dynamic>{
      'model': model.modelId,
      'messages': messages,
      'stream': true,
      if (settings?.effort != null) 'think': mapOllamaThink(settings!.effort),
    };

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
          } on FormatException catch (_) {}
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('Ollama is not running. Start it with: ollama serve', originalError: e);
      }
      // Static message — `e.message` can embed the request URL which may
      // include RFC-3986 userinfo (e.g. http://user:token@host/...) that would
      // then leak into the snackbar. The status code is safe to surface.
      throw NetworkException('Ollama request failed', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  @override
  Future<bool> testConnection(AIModel model, String apiKey) async {
    try {
      await _dio.get(ApiConstants.ollamaTagsEndpoint);
      return true;
    } on DioException catch (e) {
      dLog('[OllamaRemoteDatasource] testConnection failed: ${e.type} ${e.response?.statusCode}');
      return false;
    }
  }

  @override
  Future<List<AIModel>> fetchAvailableModels(String apiKey) async {
    // See CustomRemoteDatasourceDio.fetchAvailableModels — Ollama and Custom
    // are the only two AI datasources that propagate typed errors. Cloud
    // datasources continue to swallow because their model lists are static.
    try {
      final response = await _dio.get(ApiConstants.ollamaTagsEndpoint);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ParseException('Ollama returned an unexpected payload (expected JSON object)');
      }
      final list = data['models'];
      if (list is! List) {
        // Missing or null `models` field — treat as empty, not an error.
        return const [];
      }
      final models = <AIModel>[];
      for (final entry in list) {
        if (entry is! Map) continue;
        final name = entry['name'];
        if (name is! String || name.isEmpty) continue;
        models.add(
          AIModel(id: 'ollama_$name', provider: AIProvider.ollama, name: name, modelId: name, supportsStreaming: true),
        );
      }
      return models;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      dLog('[OllamaRemoteDatasource] fetchAvailableModels failed: ${e.type} ${status ?? ''}');
      throw NetworkException('Ollama request failed', statusCode: status, originalError: e);
    } on ParseException {
      rethrow;
    } catch (e) {
      dLog('[OllamaRemoteDatasource] fetchAvailableModels unexpected ${e.runtimeType}');
      throw ParseException('Malformed Ollama /api/tags response', originalError: e);
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
