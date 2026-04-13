import '../../shared/chat_message.dart' as msg;
import '../models/chat_session.dart';

abstract interface class SessionDatasource {
  Stream<List<ChatSession>> watchAllSessions();
  Stream<List<ChatSession>> watchSessionsByProject(String projectId);
  Stream<List<ChatSession>> watchArchivedSessions();
  Future<ChatSession?> getSession(String sessionId);
  Future<String> createSession({required String modelId, required String providerId, String? title, String? projectId});
  Future<void> updateSessionTitle(String sessionId, String title);
  Future<void> deleteSession(String sessionId);
  Future<void> archiveSession(String sessionId);
  Future<void> unarchiveSession(String sessionId);
  Future<void> deleteAllSessionsAndMessages();
  Future<List<msg.ChatMessage>> loadHistory(String sessionId, {int limit, int offset});
  Future<void> persistMessage(String sessionId, msg.ChatMessage message);
}
