import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/ai/models/stream_event.dart';
import '../../data/ai/repository/ai_repository.dart';
import '../../data/ai/repository/ai_repository_impl.dart';
import '../../data/coding_tools/models/coding_tool_definition.dart';
import '../../data/shared/ai_model.dart';
import '../../data/shared/chat_message.dart';
import '../../data/session/models/session_settings.dart';
import '../../data/session/models/tool_event.dart';
import '../coding_tools/coding_tools_service.dart';

part 'agent_service.g.dart';

const String _kActSystemPrompt = '''
You are a coding assistant embedded in a local IDE. You have four tools: read_file, list_dir, write_file, str_replace.

Rules:
- Read before you edit. Always call read_file on a file before write_file or str_replace against it, unless you're creating a brand-new file.
- Prefer str_replace over write_file for targeted edits. Only use write_file for new files or full rewrites.
- After making changes, briefly describe what you changed and why in 1-3 sentences.
- If a task is ambiguous or destructive (removing large sections, deleting files, sweeping refactors), ask the user before acting.
- All paths you provide must be inside the active project. Absolute paths outside the project will be rejected.
''';

const int _kMaxIterations = 10;

/// Provides an [AgentService] with a no-op cancel flag.
///
/// The cancel flag is intentionally left as `() => false` here because the
/// service layer must not import from `lib/features/`. Callers that need
/// cooperative cancellation (e.g. [ChatMessagesActions]) should supply their
/// own cancel closure by constructing an [AgentService] directly — or by
/// reading [agentCancelProvider] themselves and passing it as a closure to
/// [AgentService.runAgenticTurn] via a wrapper.
@Riverpod(keepAlive: true)
Future<AgentService> agentService(Ref ref) async {
  final ai = await ref.watch(aiRepositoryProvider.future);
  final codingTools = ref.read(codingToolsServiceProvider);
  return AgentService(ai: ai, codingTools: codingTools, cancelFlag: () => false);
}

/// Orchestrates one user turn: streams from the model, executes tool calls,
/// loops until the model returns `finish_reason: stop`, hits the iteration
/// cap, or the user cancels.
class AgentService {
  AgentService({
    required AIRepository ai,
    required CodingToolsService codingTools,
    required bool Function() cancelFlag,
    String Function()? idGen,
  }) : _ai = ai,
       _tools = codingTools,
       _cancelFlag = cancelFlag,
       _idGen = idGen ?? (() => const Uuid().v4());

  final AIRepository _ai;
  final CodingToolsService _tools;
  final bool Function() _cancelFlag;
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
      final tools = permission == ChatPermission.readOnly ? CodingTools.readOnly : CodingTools.all;
      final wire = _buildWireMessages(workingHistory, _kActSystemPrompt, assistantId, textBuffer.toString(), events);
      final roundCalls = <_PendingCall>[];
      String? finishReason;

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
              call.args = _decodeArgs(call.argsBuffer.toString());
              final idx = events.indexWhere((e) => e.id == id);
              if (idx >= 0) {
                events[idx] = events[idx].copyWith(input: call.args);
              }
              yield snapshot(streaming: true);
            }
          case StreamFinish(:final reason):
            finishReason = reason;
        }
      }

      if (finishReason == 'stop') {
        yield snapshot(streaming: false);
        return;
      }

      if (finishReason != 'tool_calls') {
        dLog('[AgentService] unexpected finishReason=$finishReason');
        textBuffer.write('\n\n_Stream ended unexpectedly._');
        yield snapshot(streaming: false);
        return;
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

      for (final call in roundCalls) {
        if (_cancelFlag()) break;
        final result = await _tools.execute(
          toolName: call.name,
          args: call.args,
          projectPath: projectPath,
          sessionId: sessionId,
          messageId: assistantId,
        );
        _recordResult(events, call.id, result);
        workingHistory.add(_toolResultMessage(sessionId, call.id, result));
        yield snapshot(streaming: true);
      }
    }
  }

  Map<String, dynamic> _decodeArgs(String raw) {
    if (raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
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

  ChatMessage _toolResultMessage(String sessionId, String toolCallId, CodingToolResult result) {
    final (content, isSuccess, output, errMsg) = switch (result) {
      CodingToolResultSuccess(:final output) => (output, true, output, null as String?),
      CodingToolResultError(:final message) => (message, false, null as String?, message),
    };
    return ChatMessage(
      id: _idGen(),
      sessionId: sessionId,
      role: MessageRole.system,
      content: content,
      timestamp: DateTime.now(),
      toolEvents: [
        ToolEvent(
          id: toolCallId,
          type: 'tool_result',
          toolName: '__tool_result__',
          status: isSuccess ? ToolStatus.success : ToolStatus.error,
          output: output,
          error: errMsg,
        ),
      ],
    );
  }

  /// Translates in-memory history → OpenAI chat-completions wire format.
  List<Map<String, dynamic>> _buildWireMessages(
    List<ChatMessage> history,
    String systemPrompt,
    String currentAssistantId,
    String currentTextBuffer,
    List<ToolEvent> currentEvents,
  ) {
    final wire = <Map<String, dynamic>>[];
    wire.add({'role': 'system', 'content': systemPrompt});
    for (final msg in history) {
      if (msg.role == MessageRole.system && msg.toolEvents.isNotEmpty && msg.toolEvents.first.type == 'tool_result') {
        final te = msg.toolEvents.first;
        wire.add({'role': 'tool', 'tool_call_id': te.id, 'content': te.output ?? te.error ?? ''});
      } else if (msg.role == MessageRole.assistant && msg.toolEvents.isNotEmpty) {
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
      } else {
        wire.add({'role': msg.role.value, 'content': msg.content});
      }
    }
    if (currentEvents.isNotEmpty) {
      wire.add({
        'role': 'assistant',
        'content': currentTextBuffer.isEmpty ? null : currentTextBuffer,
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
        if (te.status == ToolStatus.success || te.status == ToolStatus.error) {
          wire.add({'role': 'tool', 'tool_call_id': te.id, 'content': te.output ?? te.error ?? ''});
        }
      }
    }
    return wire;
  }
}

class _PendingCall {
  _PendingCall({required this.id, required this.name});
  final String id;
  final String name;
  final StringBuffer argsBuffer = StringBuffer();
  Map<String, dynamic> args = const {};
}
