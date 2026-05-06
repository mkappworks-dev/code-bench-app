import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../shared/ai_model.dart';
import '../../shared/chat_message.dart';
import '../models/chat_session.dart';
import '../datasource/session_datasource.dart';
import '../datasource/session_datasource_drift.dart';
import 'session_repository.dart';

part 'session_repository_impl.g.dart';

@Riverpod(keepAlive: true)
SessionRepository sessionRepository(Ref ref) {
  return SessionRepositoryImpl(datasource: ref.watch(sessionDatasourceProvider));
}

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl({required SessionDatasource datasource}) : _ds = datasource;

  final SessionDatasource _ds;

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
  Future<void> patchSessionSettings(
    String sessionId, {
    String? modelId,
    String? systemPrompt,
    String? mode,
    String? effort,
    String? permission,
  }) => _ds.patchSessionSettings(
    sessionId,
    modelId: modelId,
    systemPrompt: systemPrompt,
    mode: mode,
    effort: effort,
    permission: permission,
  );

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
  Future<void> deleteMessage(String sessionId, String messageId) => _ds.deleteMessage(sessionId, messageId);

  @override
  Future<void> deleteMessages(String sessionId, List<String> messageIds) => _ds.deleteMessages(sessionId, messageIds);

  @override
  Future<List<ChatSession>> getSessionsByProject(String projectId) => watchSessionsByProject(projectId).first;
}
