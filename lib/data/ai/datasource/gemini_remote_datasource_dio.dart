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
import '../models/provider_turn_settings.dart';
import '../util/setting_mappers.dart';
import 'ai_remote_datasource.dart';
import 'text_streaming_datasource.dart';

@visibleForTesting
Map<String, dynamic> buildGeminiRequestBody({
  required AIModel model,
  required List<Map<String, dynamic>> contents,
  String? systemPrompt,
  ProviderTurnSettings? settings,
}) {
  final body = <String, dynamic>{
    'contents': contents,
    if (systemPrompt != null)
      'system_instruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
  };
  if (settings?.effort != null && supportsGeminiThinking(model.modelId)) {
    final thinkingConfig = isGemini3(model.modelId)
        ? {'thinkingLevel': mapGeminiThinkingLevel(settings!.effort!)}
        : {'thinkingBudget': mapGeminiThinkingBudget(settings!.effort!)};
    body['generationConfig'] = {'thinkingConfig': thinkingConfig};
  }
  return body;
}

class GeminiRemoteDatasourceDio implements AIRemoteDatasource, TextStreamingDatasource {
  GeminiRemoteDatasourceDio(String apiKey)
    : _apiKey = apiKey,
      _dio = DioFactory.create(baseUrl: ApiConstants.geminiBaseUrl);

  final String _apiKey;
  final Dio _dio;

  @override
  AIProvider get provider => AIProvider.gemini;

  @override
  ProviderCapabilities capabilitiesFor(AIModel model) => ProviderCapabilities(
    supportsModelOverride: true,
    supportsSystemPrompt: true,
    supportedModes: const {ChatMode.chat},
    supportedEfforts: supportsGeminiThinking(model.modelId)
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
  }) async* {
    final contents = _buildContents(history, prompt);
    final body = buildGeminiRequestBody(
      model: model,
      contents: contents,
      systemPrompt: systemPrompt,
      settings: settings,
    );

    try {
      final response = await _dio.post(
        '/models/${model.modelId}:streamGenerateContent?key=$_apiKey&alt=sse',
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
              final text = json['candidates']?[0]?['content']?['parts']?[0]?['text'];
              if (text is String && text.isNotEmpty) {
                yield text;
              }
            } on FormatException catch (_) {}
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
      dLog('[GeminiDatasource] request failed: status=${e.response?.statusCode} type=${e.type} body=$errorBody');
      throw NetworkException('Gemini request failed', statusCode: e.response?.statusCode, originalError: e);
    }
  }

  @override
  Future<bool> testConnection(AIModel model, String apiKey) async {
    try {
      await _dio.get('/models?key=$apiKey');
      return true;
    } on DioException catch (e) {
      dLog('[GeminiRemoteDatasource] testConnection failed: ${e.type} ${e.response?.statusCode}');
      return false;
    }
  }

  @override
  Future<List<AIModel>> fetchAvailableModels(String apiKey) async {
    try {
      final response = await _dio.get('/models?key=$apiKey');
      final data = response.data as Map<String, dynamic>;
      final models = (data['models'] as List).where((m) => (m['name'] as String).contains('gemini')).map((m) {
        final name = m['name'] as String;
        final id = name.split('/').last;
        return AIModel(id: id, provider: AIProvider.gemini, name: m['displayName'] as String? ?? id, modelId: id);
      }).toList();
      return models;
    } on DioException catch (e) {
      dLog('[GeminiRemoteDatasource] fetchAvailableModels failed: ${e.type} ${e.response?.statusCode}');
      return AIModels.defaults.where((m) => m.provider == AIProvider.gemini).toList();
    }
  }

  List<Map<String, dynamic>> _buildContents(List<ChatMessage> history, String prompt) {
    final contents = <Map<String, dynamic>>[];
    for (final msg in history.where((m) => m.role != MessageRole.system && m.role != MessageRole.interrupted)) {
      contents.add({
        'role': msg.role == MessageRole.user ? 'user' : 'model',
        'parts': [
          {'text': msg.content},
        ],
      });
    }
    contents.add({
      'role': 'user',
      'parts': [
        {'text': prompt},
      ],
    });
    return contents;
  }
}
