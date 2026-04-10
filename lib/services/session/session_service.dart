import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/local/app_database.dart';
import '../../data/models/ai_model.dart';
import '../../data/models/chat_message.dart' as msg_model;
import '../../data/models/chat_session.dart' as session_model;
import '../ai/ai_service_factory.dart';

part 'session_service.g.dart';

@Riverpod(keepAlive: true)
SessionService sessionService(Ref ref) {
  return SessionService(ref);
}

class SessionService {
  SessionService(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  // ── Sessions ───────────────────────────────────────────────────────────────

  Stream<List<session_model.ChatSession>> watchAllSessions() {
    return _db.sessionDao.watchAllSessions().map(
          (rows) => rows.map(_sessionFromRow).toList(),
        );
  }

  Future<String> createSession({
    required AIModel model,
    String? title,
    String? projectId,
  }) async {
    final sessionId = _uuid.v4();
    final now = DateTime.now();
    await _db.sessionDao.upsertSession(
      ChatSessionsCompanion(
        sessionId: Value(sessionId),
        title: Value(title ?? 'New Chat'),
        modelId: Value(model.modelId),
        providerId: Value(model.provider.name),
        projectId: Value(projectId),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return sessionId;
  }

  Future<void> updateSessionTitle(String sessionId, String title) async {
    await _db.sessionDao.upsertSession(
      ChatSessionsCompanion(
        sessionId: Value(sessionId),
        title: Value(title),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSession(String sessionId) async {
    await _db.sessionDao.deleteSessionMessages(sessionId);
    await _db.sessionDao.deleteSession(sessionId);
  }

  Future<session_model.ChatSession?> getSession(String sessionId) async {
    final row = await _db.sessionDao.getSession(sessionId);
    return row != null ? _sessionFromRow(row) : null;
  }

  Stream<List<session_model.ChatSession>> watchSessionsByProject(
    String projectId,
  ) {
    return _db.sessionDao.watchSessionsByProject(projectId).map(
          (rows) => rows.map(_sessionFromRow).toList(),
        );
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  Future<List<msg_model.ChatMessage>> loadHistory(
    String sessionId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await _db.sessionDao.getMessages(
      sessionId,
      limit: limit,
      offset: offset,
    );
    return rows.map(_messageFromRow).toList();
  }

  Future<void> persistMessage(
    String sessionId,
    msg_model.ChatMessage message,
  ) async {
    await _db.sessionDao.insertMessage(
      ChatMessagesCompanion(
        id: Value(message.id),
        sessionId: Value(sessionId),
        role: Value(message.role.value),
        content: Value(message.content),
        codeBlocksJson: Value(
          jsonEncode(
            message.codeBlocks
                .map(
                  (b) => {
                    'code': b.code,
                    'language': b.language,
                    'filename': b.filename,
                  },
                )
                .toList(),
          ),
        ),
        timestamp: Value(message.timestamp),
      ),
    );
    await _db.sessionDao.upsertSession(
      ChatSessionsCompanion(
        sessionId: Value(sessionId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ── Streaming ─────────────────────────────────────────────────────────────

  Stream<msg_model.ChatMessage> sendAndStream({
    required String sessionId,
    required String userInput,
    required AIModel model,
    String? systemPrompt,
  }) async* {
    final userMsg = msg_model.ChatMessage(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: msg_model.MessageRole.user,
      content: userInput,
      timestamp: DateTime.now(),
    );
    await persistMessage(sessionId, userMsg);
    yield userMsg;

    final service = await _ref.read(aiServiceProvider(model.provider).future);
    if (service == null) {
      throw Exception(
        'No API key configured for ${model.provider.displayName}',
      );
    }

    final history = await loadHistory(sessionId, limit: 20);
    final historyExcludingCurrent = history.where((m) => m.id != userMsg.id).toList();

    final assistantId = _uuid.v4();
    final buffer = StringBuffer();

    await for (final chunk in service.streamMessage(
      history: historyExcludingCurrent,
      prompt: userInput,
      model: model,
      systemPrompt: systemPrompt,
    )) {
      buffer.write(chunk);
      yield msg_model.ChatMessage(
        id: assistantId,
        sessionId: sessionId,
        role: msg_model.MessageRole.assistant,
        content: buffer.toString(),
        timestamp: DateTime.now(),
        isStreaming: true,
      );
    }

    final finalMsg = msg_model.ChatMessage(
      id: assistantId,
      sessionId: sessionId,
      role: msg_model.MessageRole.assistant,
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  session_model.ChatSession _sessionFromRow(ChatSessionRow row) {
    return session_model.ChatSession(
      sessionId: row.sessionId,
      title: row.title,
      modelId: row.modelId,
      providerId: row.providerId,
      projectId: row.projectId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isPinned: row.isPinned,
    );
  }

  msg_model.ChatMessage _messageFromRow(ChatMessageRow row) {
    List<msg_model.CodeBlock> codeBlocks = [];
    try {
      final raw = jsonDecode(row.codeBlocksJson) as List;
      codeBlocks = raw
          .map(
            (b) => msg_model.CodeBlock(
              code: b['code'] as String? ?? '',
              language: b['language'] as String?,
              filename: b['filename'] as String?,
            ),
          )
          .toList();
    } catch (_) {}

    return msg_model.ChatMessage(
      id: row.id,
      sessionId: row.sessionId,
      role: msg_model.MessageRole.values.firstWhere(
        (r) => r.value == row.role,
        orElse: () => msg_model.MessageRole.user,
      ),
      content: row.content,
      codeBlocks: codeBlocks,
      timestamp: row.timestamp,
    );
  }
}
