import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/_core/http/dio_factory.dart';
import '../../../data/shared/ai_model.dart';
import '../../../data/shared/chat_message.dart';
import '../../../data/shared/session_settings.dart';
import '../models/provider_capabilities.dart';
import '../models/provider_setting_drop.dart';
import '../models/provider_turn_settings.dart';
import '../util/setting_mappers.dart';
import 'ai_remote_datasource.dart';
import 'text_streaming_datasource.dart';

@visibleForTesting
Map<String, dynamic> buildOpenAiRequestBody({
  required AIModel model,
  required List<Map<String, String>> messages,
  ProviderTurnSettings? settings,
  ProviderSettingDropSink? onSettingDropped,
}) {
  final body = <String, dynamic>{'model': model.modelId, 'messages': messages, 'stream': true};
  if (settings?.effort != null && AIModels.isOpenAiReasoningModel(model.modelId)) {
    body['reasoning_effort'] = mapOpenAIReasoningEffort(settings!.effort!, onSettingDropped: onSettingDropped);
  }
  return body;
}

class OpenAIRemoteDatasourceDio implements AIRemoteDatasource, TextStreamingDatasource {
  OpenAIRemoteDatasourceDio(String apiKey)
    : _dio = DioFactory.create(
        baseUrl: ApiConstants.openAiBaseUrl,
        headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
      );

  final Dio _dio;

  @override
  AIProvider get provider => AIProvider.openai;

  @override
  ProviderCapabilities capabilitiesFor(AIModel model) => ProviderCapabilities(
    supportsModelOverride: true,
    supportsSystemPrompt: true,
    supportedModes: const {ChatMode.chat},
    supportedEfforts: AIModels.isOpenAiReasoningModel(model.modelId)
        ? const {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max}
        : const <ChatEffort>{},
    supportedPermissions: const <ChatPermission>{},
  );

  @override
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
    ProviderTurnSettings? settings,
    ProviderSettingDropSink? onSettingDropped,
  }) async* {
    final messages = _buildMessages(history, prompt, systemPrompt);
    final body = buildOpenAiRequestBody(
      model: model,
      messages: messages,
      settings: settings,
      onSettingDropped: onSettingDropped,
    );

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
      String? errorBody;
      if (e.response?.data is ResponseBody) {
        try {
          final bytes = await (e.response!.data as ResponseBody).stream.fold<List<int>>(
            [],
            (acc, chunk) => [...acc, ...chunk],
          );
          errorBody = utf8.decode(bytes);
        } catch (_) {}
      }
      dLog(
        '[OpenAIDatasource] request failed: status=${e.response?.statusCode} '
        'type=${e.type} body=${redactSecrets(errorBody ?? 'null')}',
      );
      throw NetworkException('OpenAI request failed', statusCode: e.response?.statusCode, originalError: e);
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
      final entries = data['data'];
      if (entries is! List) {
        dLog('[OpenAIRemoteDatasource] /models payload missing "data" list — using hardcoded fallback');
        return AIModels.defaults.where((m) => m.provider == AIProvider.openai).toList();
      }
      final models = <AIModel>[];
      for (final entry in entries) {
        if (entry is! Map) continue;
        final id = entry['id'];
        if (id is! String || id.isEmpty) continue;
        if (!AIModels.isOpenAiChatModelId(id)) continue;
        models.add(AIModel(id: id, provider: AIProvider.openai, name: id, modelId: id));
      }
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
    for (final msg in history.where((m) => m.role != MessageRole.interrupted)) {
      messages.add({'role': msg.role.value, 'content': msg.content});
    }
    messages.add({'role': 'user', 'content': prompt});
    return messages;
  }
}
