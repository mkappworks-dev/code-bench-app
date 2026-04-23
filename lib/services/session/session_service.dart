import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/ai/datasource/claude_cli_remote_datasource_process.dart';
import '../../data/ai/models/stream_event.dart';
import '../../data/ai/repository/ai_repository.dart';
import '../../data/ai/repository/ai_repository_impl.dart';
import '../../data/session/models/permission_request.dart';
import '../../data/session/models/session_settings.dart';
import '../../data/session/models/tool_event.dart';
import '../../data/shared/ai_model.dart';
import '../../data/shared/chat_message.dart';
import '../../data/session/models/chat_session.dart';
import '../../data/session/repository/session_repository.dart';
import '../../data/session/repository/session_repository_impl.dart';
import '../agent/agent_service.dart';
import '../mcp/mcp_service.dart' show McpRemoveCallback, McpStatusCallback;

part 'session_service.g.dart';

@Riverpod(keepAlive: true)
Future<SessionService> sessionService(Ref ref) async {
  final session = ref.watch(sessionRepositoryProvider);
  final ai = await ref.watch(aiRepositoryProvider.future);
  final agent = await ref.watch(agentServiceProvider.future);
  return SessionService(session: session, ai: ai, agent: agent);
}

class SessionService {
  SessionService({required SessionRepository session, required AIRepository ai, required AgentService agent})
    : _session = session,
      _ai = ai,
      _agent = agent;

  final SessionRepository _session;
  final AIRepository _ai;
  final AgentService _agent;
  static const _uuid = Uuid();

  // ── CRUD delegation ────────────────────────────────────────────────────────

  Stream<List<ChatSession>> watchAllSessions() => _session.watchAllSessions();
  Stream<List<ChatSession>> watchSessionsByProject(String projectId) => _session.watchSessionsByProject(projectId);
  Stream<List<ChatSession>> watchArchivedSessions() => _session.watchArchivedSessions();
  Future<ChatSession?> getSession(String sessionId) => _session.getSession(sessionId);
  Future<String> createSession({required AIModel model, String? title, String? projectId}) =>
      _session.createSession(model: model, title: title, projectId: projectId);
  Future<void> updateSessionTitle(String sessionId, String title) => _session.updateSessionTitle(sessionId, title);
  Future<void> patchSessionSettings(
    String sessionId, {
    String? modelId,
    String? systemPrompt,
    String? mode,
    String? effort,
    String? permission,
  }) => _session.patchSessionSettings(
    sessionId,
    modelId: modelId,
    systemPrompt: systemPrompt,
    mode: mode,
    effort: effort,
    permission: permission,
  );
  Future<void> deleteSession(String sessionId) => _session.deleteSession(sessionId);
  Future<void> deleteMessage(String sessionId, String messageId) => _session.deleteMessage(sessionId, messageId);
  Future<void> deleteMessages(String sessionId, List<String> messageIds) =>
      _session.deleteMessages(sessionId, messageIds);
  Future<void> archiveSession(String sessionId) => _session.archiveSession(sessionId);
  Future<void> unarchiveSession(String sessionId) => _session.unarchiveSession(sessionId);
  Future<void> deleteAllSessionsAndMessages() => _session.deleteAllSessionsAndMessages();
  Future<List<ChatMessage>> loadHistory(String sessionId, {int limit = 50, int offset = 0}) =>
      _session.loadHistory(sessionId, limit: limit, offset: offset);
  Future<void> persistMessage(String sessionId, ChatMessage message) => _session.persistMessage(sessionId, message);
  Future<List<ChatSession>> getSessionsByProject(String projectId) => _session.getSessionsByProject(projectId);

  static bool _neverCancel() => false;

  Stream<ChatMessage> sendAndStream({
    required String sessionId,
    required String userInput,
    required AIModel model,
    String? systemPrompt,
    ChatMode mode = ChatMode.chat,
    ChatPermission permission = ChatPermission.fullAccess,
    String? projectPath,
    bool Function() cancelFlag = _neverCancel,
    Future<bool> Function(PermissionRequest req)? requestPermission,
    McpStatusCallback? onMcpStatusChanged,
    McpRemoveCallback? onMcpServerRemoved,
  }) async* {
    String? persistedUserMsgId;
    if (userInput.isNotEmpty) {
      final userMsg = ChatMessage(
        id: _uuid.v4(),
        sessionId: sessionId,
        role: MessageRole.user,
        content: userInput,
        timestamp: DateTime.now(),
      );
      persistedUserMsgId = userMsg.id;
      await _session.persistMessage(sessionId, userMsg);
      yield userMsg;
    }

    final history = await _session.loadHistory(sessionId, limit: 20);
    // Preserve the existing interrupted-marker filter so MessageRole.interrupted
    // rows never leak into the model's context window.
    // When persistedUserMsgId is null (no user message was added), no message
    // is filtered by id — which is correct.
    final historyExcludingCurrent = history
        .where((m) => m.id != persistedUserMsgId && m.role != MessageRole.interrupted)
        .toList();

    // CLI transport: if the Anthropic datasource is the CLI-backed one AND the
    // target model is Anthropic, bypass the agent loop / plain text path and
    // stream Claude Code's own tool-use events as receipts. Guarded by an
    // `is` check so test fakes that don't extend AIRepositoryImpl remain
    // compatible.
    final ai = _ai;
    if (ai is AIRepositoryImpl && model.provider == AIProvider.anthropic) {
      final anthropicDs = ai.rawDatasource(AIProvider.anthropic);
      if (anthropicDs is ClaudeCliRemoteDatasourceProcess) {
        yield* _streamClaudeCli(
          ds: anthropicDs,
          sessionId: sessionId,
          prompt: userInput,
          history: historyExcludingCurrent,
          projectPath: projectPath,
          requestPermission: requestPermission,
          cancelFlag: cancelFlag,
        );
        // Title-from-first-message on cold session.
        if (historyExcludingCurrent.isEmpty && userInput.isNotEmpty) {
          final shortTitle = userInput.length > 50 ? '${userInput.substring(0, 47)}...' : userInput;
          await _session.updateSessionTitle(sessionId, shortTitle);
        }
        return;
      }
    }

    if (mode == ChatMode.act && model.provider != AIProvider.custom) {
      throw ProviderDoesNotSupportToolsException();
    }

    if (mode == ChatMode.act && model.provider == AIProvider.custom && projectPath != null) {
      await for (final msg in _agent.runAgenticTurn(
        sessionId: sessionId,
        history: historyExcludingCurrent,
        userInput: userInput,
        model: model,
        permission: permission,
        projectPath: projectPath,
        cancelFlag: cancelFlag,
        requestPermission: requestPermission,
        onMcpStatusChanged: onMcpStatusChanged,
        onMcpServerRemoved: onMcpServerRemoved,
      )) {
        if (!msg.isStreaming) {
          await _session.persistMessage(sessionId, msg);
        }
        yield msg;
      }
      if (historyExcludingCurrent.isEmpty && userInput.isNotEmpty) {
        final shortTitle = userInput.length > 50 ? '${userInput.substring(0, 47)}...' : userInput;
        await _session.updateSessionTitle(sessionId, shortTitle);
      }
      return;
    }

    // Plain text path (unchanged).
    final assistantId = _uuid.v4();
    final buffer = StringBuffer();

    await for (final chunk in _ai.streamMessage(
      history: historyExcludingCurrent,
      prompt: userInput,
      model: model,
      systemPrompt: systemPrompt,
    )) {
      buffer.write(chunk);
      yield ChatMessage(
        id: assistantId,
        sessionId: sessionId,
        role: MessageRole.assistant,
        content: buffer.toString(),
        timestamp: DateTime.now(),
        isStreaming: true,
      );
    }

    final finalMsg = ChatMessage(
      id: assistantId,
      sessionId: sessionId,
      role: MessageRole.assistant,
      content: buffer.toString(),
      timestamp: DateTime.now(),
    );
    await _session.persistMessage(sessionId, finalMsg);
    yield finalMsg;

    if (historyExcludingCurrent.isEmpty && userInput.isNotEmpty) {
      final shortTitle = userInput.length > 50 ? '${userInput.substring(0, 47)}...' : userInput;
      await _session.updateSessionTitle(sessionId, shortTitle);
    }
  }

  Stream<ChatMessage> _streamClaudeCli({
    required ClaudeCliRemoteDatasourceProcess ds,
    required String sessionId,
    required String prompt,
    required List<ChatMessage> history,
    required String? projectPath,
    required Future<bool> Function(PermissionRequest)? requestPermission,
    required bool Function() cancelFlag,
  }) async* {
    final assistantId = _uuid.v4();

    // Permission gate: a single Code Bench card per CLI delegation. Claude
    // Code itself runs with bypassPermissions, so we warn the user here.
    if (requestPermission != null) {
      final req = PermissionRequest(
        toolEventId: assistantId,
        toolName: 'claude-cli',
        summary: 'Delegate to Claude Code CLI',
        input: {
          'prompt': prompt.length > 200 ? '${prompt.substring(0, 200)}…' : prompt,
          'workingDirectory': projectPath ?? Directory.current.path,
          'sessionId': sessionId,
          'warning':
              'Claude Code will autonomously read, edit, and run shell '
              'commands in this directory using its built-in tools. Code '
              "Bench's permission rules do not apply to its actions.",
        },
      );
      final approved = await requestPermission(req);
      if (!approved) {
        // User denied — emit an interrupted marker and stop.
        final cancelled = ChatMessage(
          id: assistantId,
          sessionId: sessionId,
          role: MessageRole.assistant,
          content: '[Delegation cancelled by user]',
          timestamp: DateTime.now(),
        );
        await _session.persistMessage(sessionId, cancelled);
        yield cancelled;
        return;
      }
    }

    // Determine isFirstTurn from persisted history.
    final isFirstTurn = history.isEmpty;

    // Accumulators for the streaming assistant message.
    final contentBuffer = StringBuffer();
    final thinkingBuffer = StringBuffer();
    final toolEvents = <ToolEvent>[];

    ChatMessage snapshot({bool streaming = true}) => ChatMessage(
      id: assistantId,
      sessionId: sessionId,
      role: MessageRole.assistant,
      content: contentBuffer.toString(),
      timestamp: DateTime.now(),
      isStreaming: streaming,
      toolEvents: List.unmodifiable(toolEvents),
    );

    await for (final event in ds.streamEvents(
      history: history,
      prompt: prompt,
      workingDirectory: projectPath ?? Directory.current.path,
      sessionId: sessionId,
      isFirstTurn: isFirstTurn,
    )) {
      if (cancelFlag()) {
        await ds.cancel();
        break;
      }

      if (event is TextDelta) {
        contentBuffer.write(event.text);
        yield snapshot();
      } else if (event is ThinkingDelta) {
        // Accumulate internally — we don't surface thinking in the chat
        // bubble for MVP, but it stays available for future diagnostics.
        thinkingBuffer.write(event.text);
      } else if (event is ToolUseStart) {
        toolEvents.add(
          ToolEvent(
            id: event.id,
            type: 'claude_cli_tool',
            toolName: event.name,
            status: ToolStatus.running,
            source: ToolEventSource.cliTransport,
          ),
        );
        yield snapshot();
      } else if (event is ToolUseComplete) {
        final idx = toolEvents.indexWhere((t) => t.id == event.id);
        if (idx >= 0) {
          toolEvents[idx] = toolEvents[idx].copyWith(input: event.input);
          yield snapshot();
        }
      } else if (event is ToolResult) {
        final idx = toolEvents.indexWhere((t) => t.id == event.toolUseId);
        if (idx >= 0) {
          toolEvents[idx] = toolEvents[idx].copyWith(
            output: event.content,
            status: event.isError ? ToolStatus.error : ToolStatus.success,
            error: event.isError ? event.content : null,
          );
          yield snapshot();
        }
      } else if (event is StreamError) {
        final errMsg = '[Claude Code error] ${event.failure}';
        contentBuffer.write(contentBuffer.isEmpty ? errMsg : '\n$errMsg');
        yield snapshot();
      }
      // ToolUseInputDelta: no-op; parser accumulates the buffer and emits
      // ToolUseComplete.
      // StreamDone: handled by the loop ending naturally.
      // StreamParseFailure: logged inside the datasource; ignore here.
    }

    // Final non-streaming message.
    final finalMsg = snapshot(streaming: false);
    await _session.persistMessage(sessionId, finalMsg);
    yield finalMsg;
  }
}
