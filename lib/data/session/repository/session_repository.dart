import '../../models/ai_model.dart';
import '../../models/chat_message.dart';
import '../../models/chat_session.dart';

abstract interface class SessionRepository {
  Stream<List<ChatSession>> watchAllSessions();
  Stream<List<ChatSession>> watchSessionsByProject(String projectId);
  Stream<List<ChatSession>> watchArchivedSessions();
  Future<ChatSession?> getSession(String sessionId);
  Future<String> createSession({required AIModel model, String? title, String? projectId});
  Future<void> updateSessionTitle(String sessionId, String title);
  Future<void> deleteSession(String sessionId);
  Future<void> archiveSession(String sessionId);
  Future<void> unarchiveSession(String sessionId);
  Future<void> deleteAllSessionsAndMessages();
  Future<List<ChatMessage>> loadHistory(String sessionId, {int limit, int offset});
  Future<void> persistMessage(String sessionId, ChatMessage message);

  /// One-shot fetch of all non-archived sessions for [projectId].
  Future<List<ChatSession>> getSessionsByProject(String projectId);

  /// Streams a user message followed by streamed assistant chunks, then the
  /// final persisted assistant message.
  Stream<ChatMessage> sendAndStream({
    required String sessionId,
    required String userInput,
    required AIModel model,
    String? systemPrompt,
  });
}
