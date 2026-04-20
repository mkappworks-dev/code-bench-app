import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/ai/repository/ai_repository.dart';
import '../../data/ai/repository/ai_repository_impl.dart';
import '../../data/session/models/session_settings.dart';
import '../../data/shared/ai_model.dart';
import '../../data/shared/chat_message.dart';
import '../../data/session/models/chat_session.dart';
import '../../data/session/repository/session_repository.dart';
import '../../data/session/repository/session_repository_impl.dart';
import '../agent/agent_service.dart';
import '../../features/chat/notifiers/agent_failure.dart';

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

  Stream<ChatMessage> sendAndStream({
    required String sessionId,
    required String userInput,
    required AIModel model,
    String? systemPrompt,
    ChatMode mode = ChatMode.chat,
    ChatPermission permission = ChatPermission.fullAccess,
    String? projectPath,
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

    if (mode == ChatMode.act && model.provider != AIProvider.custom) {
      throw const AgentProviderDoesNotSupportTools();
    }

    if (mode == ChatMode.act && model.provider == AIProvider.custom && projectPath != null) {
      await for (final msg in _agent.runAgenticTurn(
        sessionId: sessionId,
        history: historyExcludingCurrent,
        userInput: userInput,
        model: model,
        permission: permission,
        projectPath: projectPath,
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
}
