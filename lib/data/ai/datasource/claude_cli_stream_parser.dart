import 'dart:convert';

import '../models/stream_event.dart';

/// Parses Claude Code CLI `--output-format stream-json` lines into Code Bench's
/// [StreamEvent] shape. Stateful across tool_use input_json_delta frames.
class ClaudeCliStreamParser {
  final Map<int, _PendingToolUse> _pendingToolUses = {};

  StreamEvent? parseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, dynamic>) {
        return StreamEvent.cliStreamParseFailure(line: trimmed, error: 'expected object, got ${decoded.runtimeType}');
      }
      json = decoded;
    } catch (e) {
      return StreamEvent.cliStreamParseFailure(line: trimmed, error: e);
    }

    final type = json['type'] as String?;
    switch (type) {
      case 'system':
      case 'rate_limit_event':
      case 'assistant':
      case 'message':
      case 'result':
        return null;
      case 'stream_event':
        return _parseStreamEvent(json['event'] as Map<String, dynamic>?, line: trimmed);
      case 'user':
        return _parseUserMessage(json['message'] as Map<String, dynamic>?, line: trimmed);
      default:
        return null;
    }
  }

  StreamEvent? _parseStreamEvent(Map<String, dynamic>? event, {required String line}) {
    if (event == null) return null;
    final eventType = event['type'] as String?;
    switch (eventType) {
      case 'content_block_start':
        final index = event['index'] as int?;
        final block = event['content_block'] as Map<String, dynamic>?;
        if (index == null || block == null) return null;
        if (block['type'] == 'tool_use') {
          final id = block['id'] as String?;
          final name = block['name'] as String?;
          if (id == null || name == null) return null;
          _pendingToolUses[index] = _PendingToolUse(id: id, name: name, inputBuffer: StringBuffer());
          return StreamEvent.cliToolUseStart(id: id, name: name);
        }
        return null;
      case 'content_block_delta':
        final index = event['index'] as int?;
        final delta = event['delta'] as Map<String, dynamic>?;
        if (index == null || delta == null) return null;
        switch (delta['type'] as String?) {
          case 'text_delta':
            return StreamEvent.cliTextDelta(delta['text'] as String? ?? '');
          case 'thinking_delta':
            return StreamEvent.cliThinkingDelta(delta['thinking'] as String? ?? '');
          case 'input_json_delta':
            final partial = delta['partial_json'] as String? ?? '';
            final pending = _pendingToolUses[index];
            if (pending == null) return null;
            pending.inputBuffer.write(partial);
            return StreamEvent.cliToolUseInputDelta(id: pending.id, partialJson: partial);
          default:
            return null;
        }
      case 'content_block_stop':
        final index = event['index'] as int?;
        if (index == null) return null;
        final pending = _pendingToolUses.remove(index);
        if (pending == null) return null;
        Map<String, dynamic> input;
        try {
          final decoded = jsonDecode(pending.inputBuffer.toString());
          input = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
        } catch (e) {
          return StreamEvent.cliStreamParseFailure(line: line, error: e);
        }
        return StreamEvent.cliToolUseComplete(id: pending.id, input: input);
      case 'message_stop':
        return const StreamEvent.cliStreamDone();
      default:
        return null;
    }
  }

  StreamEvent? _parseUserMessage(Map<String, dynamic>? message, {required String line}) {
    if (message == null) return null;
    final content = message['content'];
    if (content is! List) return null;
    for (final item in content) {
      if (item is! Map<String, dynamic>) continue;
      if (item['type'] == 'tool_result') {
        final id = item['tool_use_id'] as String?;
        final raw = item['content'];
        final contentStr = raw is String ? raw : jsonEncode(raw);
        final isError = item['is_error'] as bool? ?? false;
        if (id == null) return null;
        return StreamEvent.cliToolResult(toolUseId: id, content: contentStr, isError: isError);
      }
    }
    return null;
  }
}

class _PendingToolUse {
  _PendingToolUse({required this.id, required this.name, required this.inputBuffer});
  final String id;
  final String name;
  final StringBuffer inputBuffer;
}
