import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../ai/repository/ai_repository.dart';
import '../../ai/repository/ai_repository_impl.dart';
import '../../models/ai_model.dart';
import '../../models/chat_message.dart';
import '../../models/chat_session.dart';
import '../datasource/session_datasource.dart';
import '../datasource/session_datasource_drift.dart';
import 'session_repository.dart';

part 'session_repository_impl.g.dart';

@Riverpod(keepAlive: true)
Future<SessionRepository> sessionRepository(Ref ref) async {
  final ai = await ref.watch(aiRepositoryProvider.future);
  return SessionRepositoryImpl(datasource: ref.watch(sessionDatasourceProvider), ai: ai);
}

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl({required SessionDatasource datasource, required AIRepository ai}) : _ds = datasource, _ai = ai;

  final SessionDatasource _ds;
  final AIRepository _ai;
  static const _uuid = Uuid();

  // ── CRUD — delegate to datasource ─────────────────────────────────────────

  @override
  Stream<List<ChatSession>> watchAllSessions() => _ds.watchAllSessions();

  @override
  Stream<List<ChatSession>> watchSessionsByProject(String projectId) => _ds.watchSessionsByProject(projectId);

  @override
  Stream<List<ChatSession>> watchArchivedSessions() => _ds.watchArchivedSessions();

  @override
  Future<ChatSession?> getSession(String sessionId) => _ds.getSession(sessionId);

  @override
  Future<String> createSession({required AIModel model, String? title, String? projectId}) =>
      _ds.createSession(modelId: model.modelId, providerId: model.provider.name, title: title, projectId: projectId);

  @override
  Future<void> updateSessionTitle(String sessionId, String title) => _ds.updateSessionTitle(sessionId, title);

  @override
  Future<void> deleteSession(String sessionId) => _ds.deleteSession(sessionId);

  @override
  Future<void> archiveSession(String sessionId) => _ds.archiveSession(sessionId);

  @override
  Future<void> unarchiveSession(String sessionId) => _ds.unarchiveSession(sessionId);

  @override
  Future<void> deleteAllSessionsAndMessages() => _ds.deleteAllSessionsAndMessages();

  @override
  Future<List<ChatMessage>> loadHistory(String sessionId, {int limit = 50, int offset = 0}) =>
      _ds.loadHistory(sessionId, limit: limit, offset: offset);

  @override
  Future<void> persistMessage(String sessionId, ChatMessage message) => _ds.persistMessage(sessionId, message);

  @override
  Future<List<ChatSession>> getSessionsByProject(String projectId) => watchSessionsByProject(projectId).first;

  // ── Streaming ──────────────────────────────────────────────────────────────

  @override
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
    await persistMessage(sessionId, userMsg);
    yield userMsg;

    final history = await loadHistory(sessionId, limit: 20);
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
    await persistMessage(sessionId, finalMsg);
    yield finalMsg;

    if (history.isEmpty) {
      final shortTitle = userInput.length > 50 ? '${userInput.substring(0, 47)}...' : userInput;
      await updateSessionTitle(sessionId, shortTitle);
    }
  }
}
