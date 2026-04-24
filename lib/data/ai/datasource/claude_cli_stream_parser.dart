import 'dart:convert';

import '../../../core/utils/debug_logger.dart';
import '../models/stream_event.dart';

/// Upper bound for a single tool_use's accumulated `partial_json` stream.
/// A pathological CLI could otherwise balloon memory by streaming deltas
/// indefinitely. 1 MiB is roughly 10× the largest tool input we've seen
/// in practice.
const int _toolInputBufferCap = 1024 * 1024;

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
        dLog('[ClaudeCliStreamParser] unknown top-level type: $type');
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
        final deltaType = delta['type'] as String?;
        switch (deltaType) {
          case 'text_delta':
            return StreamEvent.cliTextDelta(delta['text'] as String? ?? '');
          case 'thinking_delta':
            return StreamEvent.cliThinkingDelta(delta['thinking'] as String? ?? '');
          case 'input_json_delta':
            final partial = delta['partial_json'] as String? ?? '';
            final pending = _pendingToolUses[index];
            if (pending == null) return null;
            if (pending.inputBuffer.length >= _toolInputBufferCap) {
              // Already capped; silently drop further deltas but keep
              // the tool_use entry so the terminal content_block_stop
              // still lands (with whatever we buffered).
              if (!pending.bufferCapExceeded) {
                pending.bufferCapExceeded = true;
                dLog('[ClaudeCliStreamParser] tool_use input exceeded $_toolInputBufferCap bytes; truncating');
              }
              return null;
            }
            pending.inputBuffer.write(partial);
            return StreamEvent.cliToolUseInputDelta(id: pending.id, partialJson: partial);
          default:
            dLog('[ClaudeCliStreamParser] unknown content_block_delta type: $deltaType');
            return null;
        }
      case 'content_block_stop':
        final index = event['index'] as int?;
        if (index == null) return null;
        final pending = _pendingToolUses.remove(index);
        if (pending == null) return null;
        final rawInput = pending.inputBuffer.toString();
        Map<String, dynamic> input;
        try {
          final decoded = jsonDecode(rawInput);
          input = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
        } catch (e) {
          // Carry enough of the accumulated tool-input buffer to
          // diagnose. `line` (the content_block_stop line) isn't the
          // culprit — the preceding input_json_deltas are.
          final preview = rawInput.length > 256 ? '${rawInput.substring(0, 256)}…' : rawInput;
          return StreamEvent.cliStreamParseFailure(
            line: line,
            error: 'malformed tool_use input: $e (buffer="$preview")',
          );
        }
        return StreamEvent.cliToolUseComplete(id: pending.id, input: input);
      case 'message_stop':
        return const StreamEvent.cliStreamDone();
      default:
        dLog('[ClaudeCliStreamParser] unknown stream_event type: $eventType');
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
  bool bufferCapExceeded = false;
}
