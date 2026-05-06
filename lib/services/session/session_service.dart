import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/ai/datasource/ai_provider_datasource.dart';
import '../ai_provider/ai_provider_service.dart';
import '../../data/ai/repository/ai_repository_impl.dart';
import '../../data/ai/repository/text_streaming_repository.dart';
import '../../data/session/models/permission_request.dart';
import '../../data/session/models/session_settings.dart';
import '../../data/session/models/tool_event.dart';
import '../../data/shared/ai_model.dart';
import '../../data/shared/chat_message.dart';
import '../../data/session/models/chat_session.dart';
import '../../data/session/repository/session_repository.dart';
import '../../data/session/repository/session_repository_impl.dart';
import '../agent/agent_service.dart';
import '../chat/chat_stream_service.dart';
import '../mcp/mcp_service.dart' show McpRemoveCallback, McpStatusCallback;

part 'session_service.g.dart';

@Riverpod(keepAlive: true)
Future<SessionService> sessionService(Ref ref) async {
  final session = ref.watch(sessionRepositoryProvider);
  final ai = await ref.watch(aiRepositoryProvider.future);
  final agent = await ref.watch(agentServiceProvider.future);
  final providerService = ref.watch(aIProviderServiceProvider.notifier);
  final chatStreamSvc = ref.read(chatStreamServiceProvider);
  return SessionService(
    session: session,
    ai: ai,
    agent: agent,
    providerService: providerService,
    chatStreamService: chatStreamSvc,
  );
}

class SessionService {
  SessionService({
    required SessionRepository session,
    required TextStreamingRepository ai,
    required AgentService agent,
    AIProviderService? providerService,
    ChatStreamService? chatStreamService,
  }) : _session = session,
       _ai = ai,
       _agent = agent,
       _providerService = providerService,
       _chatStreamService = chatStreamService;

  final SessionRepository _session;
  final TextStreamingRepository _ai;
  final AgentService _agent;
  final AIProviderService? _providerService;
  final ChatStreamService? _chatStreamService;
  static const _uuid = Uuid();

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
  Future<void> deleteAllSessionsAndMessages() async {
    await _chatStreamService?.cancelAll();
    return _session.deleteAllSessionsAndMessages();
  }

  Future<List<ChatMessage>> loadHistory(String sessionId, {int limit = 50, int offset = 0}) =>
      _session.loadHistory(sessionId, limit: limit, offset: offset);
  Future<void> persistMessage(String sessionId, ChatMessage message) => _session.persistMessage(sessionId, message);
  Future<List<ChatSession>> getSessionsByProject(String projectId) => _session.getSessionsByProject(projectId);

  ({String? providerId, String? modelId}) _attribution({AIModel? model, String? cliProviderId, String? cliModelId}) {
    if (cliProviderId != null) return (providerId: cliProviderId, modelId: cliModelId);
    if (model != null) return (providerId: model.provider.name, modelId: model.modelId);
    return (providerId: null, modelId: null);
  }

  Stream<ChatMessage> sendAndStream({
    required String sessionId,
    required String userInput,
    required AIModel model,
    required bool Function() cancelFlag,
    String? systemPrompt,
    ChatMode mode = ChatMode.chat,
    ChatPermission permission = ChatPermission.fullAccess,
    String? projectPath,
    String? providerId,
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

    // Provider transport: route through AIProviderDatasource when the user has
    // selected a named provider (claude-cli, codex, etc.).
    if (providerId != null) {
      final ds = _providerService?.getProvider(providerId);
      if (ds != null) {
        // CLI providers run with their own permission model
        // (`bypassPermissions` for Claude, codex's own approval flow). The
        // user's act/permission picks in the chat UI don't apply on this
        // path — log so the override is visible in dev builds. The chat
        // permission card warns the user before a CLI turn begins.
        if (mode == ChatMode.act || permission != ChatPermission.fullAccess) {
          dLog(
            '[SessionService] CLI provider $providerId — '
            'mode=$mode and permission=$permission ignored; CLI manages its own permissions',
          );
        }
        yield* _streamProvider(
          ds: ds,
          sessionId: sessionId,
          prompt: userInput,
          projectPath: projectPath,
          requestPermission: requestPermission,
          cancelFlag: cancelFlag,
        );
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
      final attribution = _attribution(model: model);
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
        final stamped = msg.role == MessageRole.assistant
            ? msg.copyWith(providerId: attribution.providerId, modelId: attribution.modelId)
            : msg;
        if (!stamped.isStreaming) {
          await _session.persistMessage(sessionId, stamped);
        }
        yield stamped;
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
    final plainAttribution = _attribution(model: model);

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
        providerId: plainAttribution.providerId,
        modelId: plainAttribution.modelId,
      );
    }

    final finalMsg = ChatMessage(
      id: assistantId,
      sessionId: sessionId,
      role: MessageRole.assistant,
      content: buffer.toString(),
      timestamp: DateTime.now(),
      providerId: plainAttribution.providerId,
      modelId: plainAttribution.modelId,
    );
    await _session.persistMessage(sessionId, finalMsg);
    yield finalMsg;

    if (historyExcludingCurrent.isEmpty && userInput.isNotEmpty) {
      final shortTitle = userInput.length > 50 ? '${userInput.substring(0, 47)}...' : userInput;
      await _session.updateSessionTitle(sessionId, shortTitle);
    }
  }

  Stream<ChatMessage> _streamProvider({
    required AIProviderDatasource ds,
    required String sessionId,
    required String prompt,
    required String? projectPath,
    required Future<bool> Function(PermissionRequest req)? requestPermission,
    required bool Function() cancelFlag,
  }) async* {
    final assistantId = _uuid.v4();
    final contentBuffer = StringBuffer();
    final toolEvents = <ToolEvent>[];
    String? streamProviderId = ds.id;
    String? streamModelId;

    ChatMessage snapshot({bool streaming = true}) => ChatMessage(
      id: assistantId,
      sessionId: sessionId,
      role: MessageRole.assistant,
      content: contentBuffer.toString(),
      timestamp: DateTime.now(),
      isStreaming: streaming,
      toolEvents: List.unmodifiable(toolEvents),
      providerId: streamProviderId,
      modelId: streamModelId,
    );

    var interrupted = false;
    await for (final event in ds.sendAndStream(
      prompt: prompt,
      sessionId: sessionId,
      workingDirectory: projectPath ?? Directory.current.path,
    )) {
      if (cancelFlag()) {
        ds.cancel();
        interrupted = true;
        break;
      }

      switch (event) {
        case ProviderInit(:final provider, :final modelId):
          streamProviderId = provider;
          streamModelId = modelId;
          dLog('[SessionService] provider $provider started (model=$modelId)');

        case ProviderTextDelta(:final text):
          contentBuffer.write(text);
          yield snapshot();

        case ProviderThinkingDelta():
          break; // Not surfaced in the chat bubble for MVP.

        case ProviderToolUseStart(:final toolId, :final toolName):
          toolEvents.add(
            ToolEvent(id: toolId, type: 'provider_tool', toolName: toolName, source: ToolEventSource.cliTransport),
          );
          yield snapshot();

        case ProviderToolInputDelta():
          break; // Accumulated by the datasource; no incremental UI update.

        case ProviderToolUseComplete(:final toolId, :final input):
          final idx = toolEvents.indexWhere((t) => t.id == toolId);
          if (idx >= 0) {
            toolEvents[idx] = toolEvents[idx].copyWith(
              input: input.isEmpty ? toolEvents[idx].input : input,
              status: ToolStatus.success,
            );
            yield snapshot();
          }

        case ProviderPermissionRequest(:final requestId, :final toolName, :final toolInput):
          final approved = requestPermission != null
              ? await requestPermission(
                  PermissionRequest(toolEventId: requestId, toolName: toolName, summary: toolName, input: toolInput),
                )
              : true;
          ds.respondToPermissionRequest(requestId, approved: approved);

        case ProviderStreamDone():
          break; // Loop ends naturally.

        case ProviderStreamFailure(:final error):
          if (contentBuffer.isNotEmpty || toolEvents.isNotEmpty) {
            await _session.persistMessage(sessionId, snapshot(streaming: false));
          }
          Error.throwWithStackTrace(StreamAbortedUnexpectedlyException(error.toString()), StackTrace.current);
      }
    }

    if (interrupted) {
      final interruptedMsg = ChatMessage(
        id: assistantId,
        sessionId: sessionId,
        role: MessageRole.interrupted,
        content: contentBuffer.isEmpty ? '[interrupted]' : '${contentBuffer.toString()}\n[interrupted]',
        timestamp: DateTime.now(),
        toolEvents: List.unmodifiable(toolEvents),
        providerId: streamProviderId,
        modelId: streamModelId,
      );
      await _session.persistMessage(sessionId, interruptedMsg);
      yield interruptedMsg;
      return;
    }

    final finalMsg = snapshot(streaming: false);
    await _session.persistMessage(sessionId, finalMsg);
    yield finalMsg;
  }
}
