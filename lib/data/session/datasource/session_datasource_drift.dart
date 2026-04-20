import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/debug_logger.dart';
import '../../_core/app_database.dart';
import '../../shared/chat_message.dart' as msg;
import '../models/chat_session.dart';
import 'session_datasource.dart';

part 'session_datasource_drift.g.dart';

@Riverpod(keepAlive: true)
SessionDatasource sessionDatasource(Ref ref) => SessionDatasourceDrift(ref.watch(appDatabaseProvider));

class SessionDatasourceDrift implements SessionDatasource {
  SessionDatasourceDrift(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  // ── Sessions ───────────────────────────────────────────────────────────────

  @override
  Stream<List<ChatSession>> watchAllSessions() {
    return _db.sessionDao.watchAllSessions().map((rows) => rows.map(_sessionFromRow).toList());
  }

  @override
  Stream<List<ChatSession>> watchSessionsByProject(String projectId) {
    return _db.sessionDao.watchSessionsByProject(projectId).map((rows) => rows.map(_sessionFromRow).toList());
  }

  @override
  Stream<List<ChatSession>> watchArchivedSessions() {
    return _db.sessionDao.watchArchivedSessions().map((rows) => rows.map(_sessionFromRow).toList());
  }

  @override
  Future<ChatSession?> getSession(String sessionId) async {
    final row = await _db.sessionDao.getSession(sessionId);
    return row != null ? _sessionFromRow(row) : null;
  }

  @override
  Future<String> createSession({
    required String modelId,
    required String providerId,
    String? title,
    String? projectId,
  }) async {
    final sessionId = _uuid.v4();
    final now = DateTime.now();
    await _db.sessionDao.upsertSession(
      ChatSessionsCompanion(
        sessionId: Value(sessionId),
        title: Value(title ?? 'New Chat'),
        modelId: Value(modelId),
        providerId: Value(providerId),
        projectId: Value(projectId),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return sessionId;
  }

  @override
  Future<void> updateSessionTitle(String sessionId, String title) async {
    await _db.sessionDao.updateSession(
      sessionId,
      ChatSessionsCompanion(title: Value(title), updatedAt: Value(DateTime.now())),
    );
  }

  @override
  Future<void> patchSessionSettings(
    String sessionId, {
    String? modelId,
    String? systemPrompt,
    String? mode,
    String? effort,
    String? permission,
  }) async {
    await _db.sessionDao.updateSession(
      sessionId,
      ChatSessionsCompanion(
        modelId: modelId != null ? Value(modelId) : const Value.absent(),
        systemPrompt: systemPrompt != null ? Value(systemPrompt) : const Value.absent(),
        mode: mode != null ? Value(mode) : const Value.absent(),
        effort: effort != null ? Value(effort) : const Value.absent(),
        permission: permission != null ? Value(permission) : const Value.absent(),
      ),
    );
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await _db.sessionDao.deleteSessionMessages(sessionId);
    await _db.sessionDao.deleteSession(sessionId);
  }

  @override
  Future<void> archiveSession(String sessionId) async {
    await _db.sessionDao.archiveSession(sessionId);
  }

  @override
  Future<void> unarchiveSession(String sessionId) async {
    await _db.sessionDao.unarchiveSession(sessionId);
  }

  @override
  Future<void> deleteAllSessionsAndMessages() => _db.sessionDao.deleteAllSessionsAndMessages();

  // ── Messages ───────────────────────────────────────────────────────────────

  @override
  Future<List<msg.ChatMessage>> loadHistory(String sessionId, {int limit = 50, int offset = 0}) async {
    final rows = await _db.sessionDao.getMessages(sessionId, limit: limit, offset: offset);
    return rows.map(_messageFromRow).toList();
  }

  @override
  Future<void> persistMessage(String sessionId, msg.ChatMessage message) async {
    await _db.sessionDao.insertMessage(
      ChatMessagesCompanion(
        id: Value(message.id),
        sessionId: Value(sessionId),
        role: Value(message.role.value),
        content: Value(message.content),
        codeBlocksJson: Value(
          jsonEncode(
            message.codeBlocks.map((b) => {'code': b.code, 'language': b.language, 'filename': b.filename}).toList(),
          ),
        ),
        timestamp: Value(message.timestamp),
      ),
    );
    await _db.sessionDao.updateSession(sessionId, ChatSessionsCompanion(updatedAt: Value(DateTime.now())));
  }

  @override
  Future<void> deleteMessage(String sessionId, String messageId) => _db.sessionDao.deleteMessage(sessionId, messageId);

  @override
  Future<void> deleteMessages(String sessionId, List<String> messageIds) =>
      _db.sessionDao.deleteMessages(sessionId, messageIds);

  // ── Helpers ────────────────────────────────────────────────────────────────

  ChatSession _sessionFromRow(ChatSessionRow row) {
    return ChatSession(
      sessionId: row.sessionId,
      title: row.title,
      modelId: row.modelId,
      providerId: row.providerId,
      projectId: row.projectId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isPinned: row.isPinned,
      isArchived: row.isArchived,
      systemPrompt: row.systemPrompt,
      mode: row.mode,
      effort: row.effort,
      permission: row.permission,
    );
  }

  msg.ChatMessage _messageFromRow(ChatMessageRow row) {
    List<msg.CodeBlock> codeBlocks = [];
    try {
      final raw = jsonDecode(row.codeBlocksJson) as List;
      codeBlocks = raw
          .map(
            (b) => msg.CodeBlock(
              code: b['code'] as String? ?? '',
              language: b['language'] as String?,
              filename: b['filename'] as String?,
            ),
          )
          .toList();
    } catch (e) {
      dLog('[SessionDatasourceDrift] failed to parse codeBlocksJson for message ${row.id}: $e');
    }

    return msg.ChatMessage(
      id: row.id,
      sessionId: row.sessionId,
      role: msg.MessageRole.values.firstWhere((r) => r.value == row.role, orElse: () => msg.MessageRole.user),
      content: row.content,
      codeBlocks: codeBlocks,
      timestamp: row.timestamp,
    );
  }
}
