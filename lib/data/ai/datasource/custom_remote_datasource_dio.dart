import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../data/_core/http/dio_factory.dart';
import '../../../data/shared/ai_model.dart';
import '../../../data/shared/chat_message.dart';
import '../models/stream_event.dart';
import '../../coding_tools/models/tool.dart';
import 'ai_remote_datasource.dart';

/// OpenAI-compatible AI datasource for custom endpoints (e.g. LM Studio, LocalAI).
class CustomRemoteDatasourceDio implements AIRemoteDatasource, TextStreamingDatasource {
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
      // `utf8.decoder` handles multi-byte character boundaries across Dio
      // chunks; `LineSplitter` splits on \n / \r\n / \r and buffers the
      // incomplete trailing line internally. Replaces the old manual
      // `utf8.decode(chunk)` which could raise on a split UTF-8 sequence.
      final lineStream = stream.stream.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter());

      await for (final line in lineStream) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data: ')) continue;
        final data = trimmed.substring(6);
        if (data == '[DONE]') return;
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final delta = json['choices']?[0]?['delta']?['content'];
          if (delta is String && delta.isNotEmpty) {
            yield delta;
          }
        } on FormatException {
          dLog('[CustomRemoteDatasource] streamMessage dropped malformed SSE line (${data.length} bytes)');
        }
      }
    } on DioException catch (e) {
      dLog('[CustomRemoteDatasource] streamMessage failed: ${e.type} ${e.response?.statusCode ?? ''}');
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

  /// OpenAI function-calling stream. Emits [StreamEvent]s as SSE chunks arrive.
  ///
  /// [messages] must already be in OpenAI wire shape (list of maps with `role`,
  /// `content`, optionally `tool_calls` / `tool_call_id`). The [AgentService]
  /// history translator is responsible for that layout — this datasource does
  /// not re-translate.
  Stream<StreamEvent> streamMessageWithTools({
    required List<Map<String, dynamic>> messages,
    required List<Tool> tools,
    required AIModel model,
  }) async* {
    final body = {
      'model': model.modelId,
      'stream': true,
      'messages': messages,
      'tools': tools.map((t) => t.toOpenAiToolJson()).toList(),
      'tool_choice': 'auto',
    };

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: body,
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data as ResponseBody;
      final idByIndex = <int, String>{};
      final inFlightIds = <String>{};
      // See streamMessage for why we use utf8.decoder + LineSplitter instead
      // of buffering chunks and calling utf8.decode manually.
      final lineStream = stream.stream.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter());

      await for (final line in lineStream) {
        if (line.trim().isEmpty) continue;
        final event = parseOpenAiToolSseLine(line, idByIndex);
        if (event == null) continue;

        switch (event) {
          case StreamToolCallStart(:final id):
            inFlightIds.add(id);
            yield event;
          case StreamToolCallArgsDelta():
            yield event;
          case StreamFinish(reason: 'tool_calls'):
            for (final id in inFlightIds) {
              yield StreamEvent.toolCallEnd(id: id);
            }
            inFlightIds.clear();
            yield event;
            return;
          case StreamFinish(:final reason):
            // A non-tool_calls finish while tool-call deltas are still
            // in-flight means the model aborted mid-call (context limit,
            // content filter, etc.). Log so we can diagnose truncated
            // tool_call arguments that arrive at the agent loop.
            if (inFlightIds.isNotEmpty) {
              dLog(
                '[CustomRemoteDatasource] stream finished with reason="$reason" '
                'while ${inFlightIds.length} tool call(s) still in-flight',
              );
            }
            yield event;
            return;
          case StreamTextDelta():
            yield event;
          // StreamToolCallEnd is synthesised above (finish_reason=tool_calls),
          // never returned by parseOpenAiToolSseLine — kept for exhaustiveness.
          case StreamToolCallEnd():
            yield event;
          // Claude Code CLI variants are emitted by a different parser and
          // never reach this OpenAI SSE path — kept for exhaustiveness.
          case TextDelta():
          case ToolUseStart():
          case ToolUseInputDelta():
          case ToolUseComplete():
          case ToolResult():
          case ThinkingDelta():
          case StreamDone():
          case StreamParseFailure():
          case StreamError():
            break;
        }
      }
    } on DioException catch (e) {
      dLog('[CustomRemoteDatasource] streamMessageWithTools failed: ${e.type} ${e.response?.statusCode ?? ''}');
      throw NetworkException(
        'Custom endpoint tool stream failed',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }
}

/// Parses a single SSE line from OpenAI chat-completions (tools enabled).
///
/// [idByIndex] carries tool-call `index → id` mapping across deltas. The
/// first delta for each tool call carries `id`; subsequent args deltas carry
/// only `index`. Callers own this map for the lifetime of one stream.
///
/// Returns `null` for lines that don't produce events (keep-alives, `[DONE]`,
/// malformed JSON, tool-call deltas with no meaningful content).
StreamEvent? parseOpenAiToolSseLine(String line, Map<int, String> idByIndex) {
  final trimmed = line.trim();
  if (!trimmed.startsWith('data: ')) return null;
  final data = trimmed.substring(6);
  if (data == '[DONE]') return null;

  Map<String, dynamic> json;
  try {
    json = jsonDecode(data) as Map<String, dynamic>;
  } on FormatException {
    dLog('[CustomRemoteDatasource] dropped malformed SSE line (${data.length} bytes)');
    return null;
  }

  final choices = json['choices'];
  if (choices is! List || choices.isEmpty) return null;
  final choice = choices[0];
  if (choice is! Map) return null;

  final finishReason = choice['finish_reason'];
  if (finishReason is String) {
    return StreamEvent.finish(reason: finishReason);
  }

  final delta = choice['delta'];
  if (delta is! Map) return null;

  final content = delta['content'];
  if (content is String && content.isNotEmpty) {
    return StreamEvent.textDelta(content);
  }

  final toolCalls = delta['tool_calls'];
  if (toolCalls is List && toolCalls.isNotEmpty) {
    final tc = toolCalls[0];
    if (tc is! Map) return null;
    final index = tc['index'];
    if (index is! int) return null;

    final id = tc['id'];
    final fnBlock = tc['function'];
    if (id is String && id.isNotEmpty) {
      idByIndex[index] = id;
      final name = (fnBlock is Map) ? fnBlock['name'] : null;
      if (name is String && name.isNotEmpty) {
        return StreamEvent.toolCallStart(id: id, name: name);
      }
    }

    if (fnBlock is Map) {
      final args = fnBlock['arguments'];
      if (args is String && args.isNotEmpty) {
        final resolvedId = idByIndex[index];
        if (resolvedId != null) {
          return StreamEvent.toolCallArgsDelta(id: resolvedId, argsJsonFragment: args);
        }
      }
    }
  }

  return null;
}
