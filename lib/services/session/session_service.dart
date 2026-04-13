import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/ai/repository/ai_repository.dart';
import '../../data/ai/repository/ai_repository_impl.dart';
import '../../data/models/ai_model.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/chat_session.dart';
import '../../data/session/repository/session_repository.dart';
import '../../data/session/repository/session_repository_impl.dart';

part 'session_service.g.dart';

@Riverpod(keepAlive: true)
Future<SessionService> sessionService(Ref ref) async {
  final session = ref.watch(sessionRepositoryProvider);
  final ai = await ref.watch(aiRepositoryProvider.future);
  return SessionService(session: session, ai: ai);
}

class SessionService {
  SessionService({required SessionRepository session, required AIRepository ai}) : _session = session, _ai = ai;

  final SessionRepository _session;
  final AIRepository _ai;
  static const _uuid = Uuid();

  // ── CRUD delegation ────────────────────────────────────────────────────────

  Stream<List<ChatSession>> watchAllSessions() => _session.watchAllSessions();
  Stream<List<ChatSession>> watchSessionsByProject(String projectId) => _session.watchSessionsByProject(projectId);
  Stream<List<ChatSession>> watchArchivedSessions() => _session.watchArchivedSessions();
  Future<ChatSession?> getSession(String sessionId) => _session.getSession(sessionId);
  Future<String> createSession({required AIModel model, String? title, String? projectId}) =>
      _session.createSession(model: model, title: title, projectId: projectId);
  Future<void> updateSessionTitle(String sessionId, String title) => _session.updateSessionTitle(sessionId, title);
  Future<void> deleteSession(String sessionId) => _session.deleteSession(sessionId);
  Future<void> archiveSession(String sessionId) => _session.archiveSession(sessionId);
  Future<void> unarchiveSession(String sessionId) => _session.unarchiveSession(sessionId);
  Future<void> deleteAllSessionsAndMessages() => _session.deleteAllSessionsAndMessages();
  Future<List<ChatMessage>> loadHistory(String sessionId, {int limit = 50, int offset = 0}) =>
      _session.loadHistory(sessionId, limit: limit, offset: offset);
  Future<void> persistMessage(String sessionId, ChatMessage message) => _session.persistMessage(sessionId, message);
  Future<List<ChatSession>> getSessionsByProject(String projectId) => _session.getSessionsByProject(projectId);

  // ── Orchestration (moved from SessionRepositoryImpl) ──────────────────────

  Stream<ChatMessage> sendAndStream({
    required String sessionId,
    required String userInput,
    required AIModel model,
    String? systemPrompt,
  }) async* {
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: MessageRole.user,
      content: userInput,
      timestamp: DateTime.now(),
    );
    await _session.persistMessage(sessionId, userMsg);
    yield userMsg;

    final history = await _session.loadHistory(sessionId, limit: 20);
    final historyExcludingCurrent = history.where((m) => m.id != userMsg.id).toList();

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

    if (history.isEmpty) {
      final shortTitle = userInput.length > 50 ? '${userInput.substring(0, 47)}...' : userInput;
      await _session.updateSessionTitle(sessionId, shortTitle);
    }
  }
}
