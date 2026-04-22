import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/ai/models/stream_event.dart';
import '../../data/ai/repository/ai_repository.dart';
import '../../data/ai/repository/ai_repository_impl.dart';
import '../../data/coding_tools/models/coding_tool_result.dart';
import '../../data/coding_tools/models/tool_capability.dart';
import '../../data/session/models/permission_request.dart';
import '../../data/session/models/session_settings.dart';
import '../../data/session/models/tool_event.dart';
import '../../data/shared/ai_model.dart';
import '../../data/shared/chat_message.dart';
import '../../features/chat/notifiers/agent_cancel_notifier.dart';
import '../../features/chat/notifiers/agent_permission_request_notifier.dart';
import '../coding_tools/tool_registry.dart';
import 'agent_exceptions.dart';

export 'agent_exceptions.dart';

part 'agent_service.g.dart';

const String _kActSystemPrompt = '''
You are a coding assistant embedded in a local IDE. You have six tools: read_file, list_dir, write_file, str_replace, grep, glob.

Rules:
- Read before you edit. Always call read_file on a file before write_file or str_replace against it, unless you're creating a brand-new file.
- Prefer str_replace over write_file for targeted edits. Only use write_file for new files or full rewrites.
- After making changes, briefly describe what you changed and why in 1-3 sentences.
- If a task is ambiguous or destructive (removing large sections, deleting files, sweeping refactors), ask the user before acting.
- All paths you provide must be inside the active project. Absolute paths outside the project will be rejected.
- If asked to do something your tools cannot do (e.g. run git commands, install packages, run the app), decline in one sentence and suggest what you can help with using your available tools.
''';

const int _kMaxIterations = 10;

/// Provides an [AgentService] wired to the cancel flag and permission-request
/// notifier from the chat feature layer.
@Riverpod(keepAlive: true)
Future<AgentService> agentService(Ref ref) async {
  final ai = await ref.watch(aiRepositoryProvider.future);
  final registry = ref.watch(toolRegistryProvider);
  return AgentService(
    ai: ai,
    registry: registry,
    cancelFlag: () => ref.read(agentCancelProvider),
    requestPermission: (req) => ref.read(agentPermissionRequestProvider.notifier).request(req),
  );
}

/// Orchestrates one user turn: streams from the model, executes tool calls,
/// loops until the model returns `finish_reason: stop`, hits the iteration
/// cap, or the user cancels.
class AgentService {
  AgentService({
    required AIRepository ai,
    required ToolRegistry registry,
    required bool Function() cancelFlag,
    Future<bool> Function(PermissionRequest req)? requestPermission,
    String Function()? idGen,
  }) : _ai = ai,
       _registry = registry,
       _cancelFlag = cancelFlag,
       _requestPermission = requestPermission ?? ((_) async => true),
       _idGen = idGen ?? (() => const Uuid().v4());

  final AIRepository _ai;
  final ToolRegistry _registry;
  final bool Function() _cancelFlag;
  final Future<bool> Function(PermissionRequest req) _requestPermission;
  final String Function() _idGen;

  Stream<ChatMessage> runAgenticTurn({
    required String sessionId,
    required List<ChatMessage> history,
    required String userInput,
    required AIModel model,
    required ChatPermission permission,
    required String projectPath,
  }) async* {
    final assistantId = _idGen();
    final textBuffer = StringBuffer();
    final events = <ToolEvent>[];
    final pending = <String, _PendingCall>{};
    var iteration = 0;

    final workingHistory = <ChatMessage>[
      ...history,
      if (userInput.isNotEmpty)
        ChatMessage(
          id: _idGen(),
          sessionId: sessionId,
          role: MessageRole.user,
          content: userInput,
          timestamp: DateTime.now(),
        ),
    ];

    ChatMessage snapshot({required bool streaming, bool capReached = false}) => ChatMessage(
      id: assistantId,
      sessionId: sessionId,
      role: MessageRole.assistant,
      content: textBuffer.toString(),
      timestamp: DateTime.now(),
      isStreaming: streaming,
      toolEvents: List.unmodifiable(events),
      iterationCapReached: capReached,
    );

    while (true) {
      iteration++;
      final tools = _registry.visibleTools(permission);
      final wire = _buildWireMessages(workingHistory, _kActSystemPrompt, events);
      final roundCalls = <_PendingCall>[];
      String? finishReason;

      try {
        await for (final event in _ai.streamMessageWithTools(wireMessages: wire, tools: tools, model: model)) {
          switch (event) {
            case StreamTextDelta(:final text):
              textBuffer.write(text);
              yield snapshot(streaming: true);
            case StreamToolCallStart(:final id, :final name):
              final call = _PendingCall(id: id, name: name);
              pending[id] = call;
              roundCalls.add(call);
              events.add(ToolEvent(id: id, type: 'tool_use', toolName: name));
              yield snapshot(streaming: true);
            case StreamToolCallArgsDelta(:final id, :final argsJsonFragment):
              pending[id]?.argsBuffer.write(argsJsonFragment);
            case StreamToolCallEnd(:final id):
              final call = pending[id];
              if (call != null) {
                final decoded = _decodeArgs(call.argsBuffer.toString());
                if (decoded == null) {
                  // Malformed JSON args — model bug or partial stream. Mark
                  // the event as error so the wire builder surfaces a tool
                  // result describing the decode failure. Don't execute.
                  call.args = const {};
                  call.decodeFailed = true;
                  final idx = events.indexWhere((e) => e.id == id);
                  if (idx >= 0) {
                    events[idx] = events[idx].copyWith(
                      status: ToolStatus.error,
                      error: 'Tool arguments were malformed JSON and could not be decoded.',
                    );
                  }
                } else {
                  call.args = decoded;
                  final idx = events.indexWhere((e) => e.id == id);
                  if (idx >= 0) {
                    events[idx] = events[idx].copyWith(input: decoded);
                  }
                }
                yield snapshot(streaming: true);
              }
            case StreamFinish(:final reason):
              finishReason = reason;
          }
        }
      } catch (e, st) {
        // The SSE stream threw mid-iteration (Dio error, NetworkException,
        // transport reset). Flip in-flight tool events to cancelled so the
        // UI doesn't leave a spinner forever, yield one final snapshot so
        // the partial text is persisted, and let the exception propagate —
        // ChatMessagesNotifier.onError maps it to an AgentFailure.
        dLog('[AgentService] stream threw during iteration $iteration: ${e.runtimeType} $e\n$st');
        _flipRunningToCancelled(events);
        yield snapshot(streaming: false);
        rethrow;
      }

      if (finishReason == 'stop') {
        yield snapshot(streaming: false);
        return;
      }

      if (finishReason != 'tool_calls') {
        dLog('[AgentService] unexpected finishReason=$finishReason');
        _flipRunningToCancelled(events);
        yield snapshot(streaming: false);
        throw StreamAbortedUnexpectedlyException(finishReason ?? 'null');
      }

      if (_cancelFlag()) {
        _flipRunningToCancelled(events);
        textBuffer.write('\n\n_Cancelled by user._');
        yield snapshot(streaming: false);
        return;
      }

      if (iteration >= _kMaxIterations) {
        _flipRunningToCancelled(events);
        yield snapshot(streaming: false, capReached: true);
        return;
      }

      // Phase 1: run read-only non-prompted calls in parallel (max 4 at a time).
      final parallelizable = roundCalls.where((c) => _isParallelizable(c, permission)).toList();
      final serial = roundCalls.where((c) => !parallelizable.contains(c)).toList();

      for (var i = 0; i < parallelizable.length; i += 4) {
        if (_cancelFlag()) break;
        final chunk = parallelizable.skip(i).take(4).toList();
        await Future.wait(
          chunk.map(
            (c) => _executeCall(
              c,
              projectPath: projectPath,
              sessionId: sessionId,
              assistantId: assistantId,
              events: events,
            ),
          ),
        );
        yield snapshot(streaming: true);
      }

      for (final call in serial) {
        if (_cancelFlag()) break;
        if (call.decodeFailed) continue;

        final tool = _registry.byName(call.name);
        if (tool != null && _registry.requiresPrompt(tool, permission)) {
          final summary = _summaryFor(call);
          final req = PermissionRequest(toolEventId: call.id, toolName: call.name, summary: summary, input: call.args);
          yield snapshot(streaming: true).copyWith(pendingPermissionRequest: req);
          final approved = await _requestPermission(req);
          yield snapshot(streaming: true);
          if (!approved) {
            final idx = events.indexWhere((e) => e.id == call.id);
            if (idx >= 0) {
              events[idx] = events[idx].copyWith(status: ToolStatus.cancelled, error: 'Denied by user');
            }
            yield snapshot(streaming: true);
            continue;
          }
        }

        await _executeCall(
          call,
          projectPath: projectPath,
          sessionId: sessionId,
          assistantId: assistantId,
          events: events,
        );
        yield snapshot(streaming: true);
      }
    }
  }

  /// Decodes JSON tool arguments. Returns `null` on malformed input (callers
  /// surface that as an error event) and `const {}` for empty/non-map input
  /// (valid: a tool that takes no arguments).
  Map<String, dynamic>? _decodeArgs(String raw) {
    if (raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        dLog('[AgentService] tool args JSON is not an object: ${decoded.runtimeType}');
        return null;
      }
      return decoded;
    } on FormatException {
      dLog('[AgentService] malformed tool args JSON (${raw.length} bytes)');
      return null;
    }
  }

  void _flipRunningToCancelled(List<ToolEvent> events) {
    for (var i = 0; i < events.length; i++) {
      if (events[i].status == ToolStatus.running) {
        events[i] = events[i].copyWith(status: ToolStatus.cancelled);
      }
    }
  }

  void _recordResult(List<ToolEvent> events, String id, CodingToolResult result) {
    final idx = events.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final (isSuccess, output, errMsg) = switch (result) {
      CodingToolResultSuccess(:final output) => (true, output, null as String?),
      CodingToolResultError(:final message) => (false, null as String?, message),
    };
    events[idx] = events[idx].copyWith(
      status: isSuccess ? ToolStatus.success : ToolStatus.error,
      output: output,
      error: errMsg,
    );
  }

  String _summaryFor(_PendingCall call) {
    if (call.name == 'write_file') {
      final path = call.args['path'] ?? '';
      final content = call.args['content'];
      final bytes = content is String ? utf8.encode(content).length : 0;
      return '$path · New file · $bytes bytes';
    }
    if (call.name == 'str_replace') {
      final path = call.args['path'] ?? '';
      return '$path · 1 match';
    }
    return call.args['path']?.toString() ?? '';
  }

  /// Translates in-memory history → OpenAI chat-completions wire format.
  ///
  /// Tool results are *not* persisted as separate messages — they live on
  /// each assistant message's `toolEvents`. Every assistant message carrying
  /// tool calls emits one `role:'assistant'` block followed by one
  /// `role:'tool'` block per terminal-status event. This keeps wire-replay
  /// consistent across session reload without a dedicated system-message
  /// persistence path.
  List<Map<String, dynamic>> _buildWireMessages(
    List<ChatMessage> history,
    String systemPrompt,
    List<ToolEvent> currentEvents,
  ) {
    final wire = <Map<String, dynamic>>[];
    wire.add({'role': 'system', 'content': systemPrompt});
    for (final msg in history) {
      if (msg.role == MessageRole.assistant && msg.toolEvents.isNotEmpty) {
        wire.add({
          'role': 'assistant',
          'content': msg.content.isEmpty ? null : msg.content,
          'tool_calls': [
            for (final te in msg.toolEvents)
              {
                'id': te.id,
                'type': 'function',
                'function': {'name': te.toolName, 'arguments': jsonEncode(te.input)},
              },
          ],
        });
        for (final te in msg.toolEvents) {
          if (_isTerminal(te.status)) {
            wire.add({'role': 'tool', 'tool_call_id': te.id, 'content': _toolContentFor(te)});
          }
        }
      } else {
        wire.add({'role': msg.role.value, 'content': msg.content});
      }
    }
    if (currentEvents.isNotEmpty) {
      wire.add({
        'role': 'assistant',
        'content': null,
        'tool_calls': [
          for (final te in currentEvents)
            {
              'id': te.id,
              'type': 'function',
              'function': {'name': te.toolName, 'arguments': jsonEncode(te.input)},
            },
        ],
      });
      for (final te in currentEvents) {
        if (_isTerminal(te.status)) {
          wire.add({'role': 'tool', 'tool_call_id': te.id, 'content': _toolContentFor(te)});
        }
      }
    }
    return wire;
  }

  static bool _isTerminal(ToolStatus s) =>
      s == ToolStatus.success || s == ToolStatus.error || s == ToolStatus.cancelled;

  static String _toolContentFor(ToolEvent te) {
    final raw = te.output ?? te.error ?? '';
    if (te.output == null && te.error == null) {
      dLog('[AgentService] terminal ToolEvent ${te.id} (${te.toolName}) has neither output nor error');
    }
    final capped = capContent(raw);
    if (te.output == null && te.error != null && !identical(capped, raw)) {
      dLog('[AgentService] tool error for ${te.toolName}/${te.id} exceeds cap — truncating');
    }
    return capped;
  }

  static const int _kToolOutputCap = 50 * 1024;

  @visibleForTesting
  static const int kToolOutputCapBytes = _kToolOutputCap;

  @visibleForTesting
  static String capContent(String s) {
    final bytes = utf8.encode(s);
    if (bytes.length <= _kToolOutputCap) return s;
    final head = utf8.decode(bytes.sublist(0, _kToolOutputCap), allowMalformed: true);
    return '$head\n[Output truncated at 50 KB. '
        'Use grep to search for specific content or read a narrower file range.]';
  }

  bool _isParallelizable(_PendingCall call, ChatPermission permission) {
    if (call.decodeFailed) return false;
    final tool = _registry.byName(call.name);
    if (tool == null) return false;
    if (tool.capability != ToolCapability.readOnly) return false;
    if (_registry.requiresPrompt(tool, permission)) return false;
    return true;
  }

  Future<void> _executeCall(
    _PendingCall call, {
    required String projectPath,
    required String sessionId,
    required String assistantId,
    required List<ToolEvent> events,
  }) async {
    final result = await _registry.execute(
      name: call.name,
      args: call.args,
      projectPath: projectPath,
      sessionId: sessionId,
      messageId: assistantId,
    );
    _recordResult(events, call.id, result);
  }
}

class _PendingCall {
  _PendingCall({required this.id, required this.name});
  final String id;
  final String name;
  final StringBuffer argsBuffer = StringBuffer();
  Map<String, dynamic> args = const {};
  bool decodeFailed = false;
}
