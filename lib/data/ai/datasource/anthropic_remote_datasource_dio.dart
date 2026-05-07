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
Map<String, dynamic> buildAnthropicRequestBody({
  required AIModel model,
  required List<Map<String, String>> messages,
  required int maxTokens,
  String? systemPrompt,
  ProviderTurnSettings? settings,
  ProviderSettingDropSink? onSettingDropped,
}) {
  final body = <String, dynamic>{
    'model': model.modelId,
    'max_tokens': maxTokens,
    'messages': messages,
    'stream': true,
    'system': ?systemPrompt,
  };
  final effort = settings?.effort;
  if (effort != null) {
    final budget = mapAnthropicThinkingBudget(
      effort,
      maxTokens: maxTokens,
      modelId: model.modelId,
      onSettingDropped: onSettingDropped,
    );
    if (budget != null) {
      body['thinking'] = {'type': 'enabled', 'budget_tokens': budget};
    }
  }
  return body;
}

class AnthropicRemoteDatasourceDio implements AIRemoteDatasource, TextStreamingDatasource {
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
  ProviderCapabilities capabilitiesFor(AIModel model) => ProviderCapabilities(
    supportsModelOverride: true,
    supportsSystemPrompt: true,
    supportedModes: const {ChatMode.chat},
    supportedEfforts: AIModels.isAnthropicAdaptiveOnly(model.modelId)
        ? const <ChatEffort>{}
        : const {ChatEffort.low, ChatEffort.medium, ChatEffort.high, ChatEffort.max},
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
    final messages = _buildMessages(history, prompt);
    final body = buildAnthropicRequestBody(
      model: model,
      messages: messages,
      // 64K leaves room for ChatEffort.max's 32 768-token thinking budget alongside a meaningful response window.
      maxTokens: 64000,
      systemPrompt: systemPrompt,
      settings: settings,
      onSettingDropped: onSettingDropped,
    );

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
            } on FormatException catch (e) {
              // SSE keepalives (`: ping`) and partial frames are expected
              // — but a real malformed JSON frame is worth a breadcrumb.
              dLog('[AnthropicDatasource] dropped malformed SSE frame: $e');
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
        } catch (decodeError) {
          dLog('[AnthropicDatasource] failed to decode error body: $decodeError');
        }
      }
      dLog(
        '[AnthropicDatasource] request failed: status=${e.response?.statusCode} '
        'type=${e.type} body=${redactSecrets(errorBody ?? 'null')}',
      );
      throw NetworkException('Anthropic request failed', statusCode: e.response?.statusCode, originalError: e);
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
  Future<List<AIModel>> fetchAvailableModels(String apiKey) async {
    try {
      final response = await _dio.get('/models');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ParseException('Anthropic /v1/models payload is not a JSON object');
      }
      final list = data['data'];
      if (list is! List) {
        throw const ParseException('Anthropic /v1/models response is missing the "data" list');
      }
      final models = <AIModel>[];
      for (final entry in list) {
        if (entry is! Map) continue;
        final id = entry['id'];
        if (id is! String || id.isEmpty) continue;
        final displayName = entry['display_name'];
        models.add(
          AIModel(
            id: id,
            provider: AIProvider.anthropic,
            name: (displayName is String && displayName.isNotEmpty) ? displayName : id,
            modelId: id,
            contextWindow: 200000,
          ),
        );
      }
      if (list.isNotEmpty && models.isEmpty) {
        throw const ParseException('Anthropic /v1/models returned entries but none were parseable');
      }
      return dropSupersededAnthropicSnapshots(models);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      dLog('[AnthropicRemoteDatasource] fetchAvailableModels failed: ${e.type} ${status ?? ''}');
      if (status == 401 || status == 403) {
        throw AuthException('Anthropic rejected the API key', originalError: e);
      }
      throw NetworkException('Anthropic request failed', statusCode: status, originalError: e);
    }
  }

  List<Map<String, String>> _buildMessages(List<ChatMessage> history, String prompt) {
    final messages = <Map<String, String>>[];
    for (final msg in history.where((m) => m.role != MessageRole.system && m.role != MessageRole.interrupted)) {
      messages.add({'role': msg.role.value, 'content': msg.content});
    }
    messages.add({'role': 'user', 'content': prompt});
    return messages;
  }
}

/// Collapses `claude-{family}-{YYYYMMDD}` snapshots to the newest dated revision per family, preserving input order and undated entries.
@visibleForTesting
List<AIModel> dropSupersededAnthropicSnapshots(List<AIModel> models) {
  final dateSuffix = RegExp(r'-(\d{8})$');
  final result = <AIModel>[];
  final indexByBase = <String, int>{};
  final dateByBase = <String, int>{};
  for (final m in models) {
    final match = dateSuffix.firstMatch(m.modelId);
    if (match == null) {
      result.add(m);
      continue;
    }
    final base = m.modelId.substring(0, match.start);
    final date = int.parse(match.group(1)!);
    final priorIdx = indexByBase[base];
    if (priorIdx == null) {
      indexByBase[base] = result.length;
      dateByBase[base] = date;
      result.add(m);
    } else if (date > dateByBase[base]!) {
      result[priorIdx] = m;
      dateByBase[base] = date;
    }
  }
  return result;
}
