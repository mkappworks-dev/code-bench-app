import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../data/models/ai_model.dart';
import '../../data/models/chat_message.dart';
import 'ai_service.dart';

class GeminiService implements AIService {
  GeminiService(this._apiKey);

  final String _apiKey;
  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.geminiBaseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
    ),
  );

  @override
  AIProvider get provider => AIProvider.gemini;

  @override
  Stream<String> streamMessage({
    required List<ChatMessage> history,
    required String prompt,
    required AIModel model,
    String? systemPrompt,
  }) async* {
    final contents = _buildContents(history, prompt);
    final body = <String, dynamic>{
      'contents': contents,
      if (systemPrompt != null)
        'system_instruction': {
          'parts': [
            {'text': systemPrompt}
          ]
        },
    };

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
            } catch (_) {}
          }
        }
      }
    } on DioException catch (e) {
      throw NetworkException(
        e.message ?? 'Gemini request failed',
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
      await _dio.get('/models?key=$apiKey');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<AIModel>> fetchAvailableModels(String apiKey) async {
    try {
      final response = await _dio.get('/models?key=$apiKey');
      final data = response.data as Map<String, dynamic>;
      final models = (data['models'] as List)
          .where((m) => (m['name'] as String).contains('gemini'))
          .map((m) {
        final name = m['name'] as String;
        final id = name.split('/').last;
        return AIModel(
          id: id,
          provider: AIProvider.gemini,
          name: m['displayName'] as String? ?? id,
          modelId: id,
        );
      }).toList();
      return models;
    } catch (_) {
      return AIModels.defaults
          .where((m) => m.provider == AIProvider.gemini)
          .toList();
    }
  }

  List<Map<String, dynamic>> _buildContents(
    List<ChatMessage> history,
    String prompt,
  ) {
    final contents = <Map<String, dynamic>>[];
    for (final msg in history.where((m) => m.role != MessageRole.system)) {
      contents.add({
        'role': msg.role == MessageRole.user ? 'user' : 'model',
        'parts': [
          {'text': msg.content}
        ],
      });
    }
    contents.add({
      'role': 'user',
      'parts': [
        {'text': prompt}
      ],
    });
    return contents;
  }
}
